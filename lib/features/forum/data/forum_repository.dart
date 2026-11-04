import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/forum_models.dart';

/// Urutan daftar topik.
enum ForumSort {
  terbaru('Topik terbaru', 'created_at'),
  teraktif('Paling aktif', 'last_activity_at');

  const ForumSort(this.label, this.field);

  final String label;
  final String field;
}

/// Akses tabel forum di Supabase.
///
/// Semua penulisan mengandalkan RLS: `user_id` harus sama dengan
/// `auth.uid()`, dan balasan hanya bisa masuk ke topik yang terbuka.
class ForumRepository {
  ForumRepository(this._client);

  final SupabaseClient _client;

  static const int pageSize = 25;

  Future<List<ForumThread>> threads({
    ForumCategory? category,
    ForumSort sort = ForumSort.terbaru,
    int offset = 0,
    int limit = pageSize,
  }) async {
    var query = _client.from('forum_threads').select();

    if (category != null) {
      query = query.eq('category', category.id);
    }

    final rows = await query
        .order('is_pinned', ascending: false)
        .order(sort.field, ascending: false)
        .range(offset, offset + limit - 1);

    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>().toList(
      growable: false,
    );
    final names = await _authorNames(
      list.map((row) => row['user_id']).whereType<String>(),
    );

    return list
        .map((row) => ForumThread.tryFromRow(row, authorNames: names))
        .whereType<ForumThread>()
        .toList(growable: false);
  }

  /// Topik yang ditulis satu pengguna (untuk tab Akun).
  Future<List<ForumThread>> threadsByAuthor(
    String userId, {
    int limit = 30,
  }) async {
    final rows = await _client
        .from('forum_threads')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>().toList(
      growable: false,
    );
    final names = await _authorNames(<String>[userId]);

    return list
        .map((row) => ForumThread.tryFromRow(row, authorNames: names))
        .whereType<ForumThread>()
        .toList(growable: false);
  }

  Future<ForumThreadDetail?> thread(String id) async {
    final threadRow = await _client
        .from('forum_threads')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (threadRow == null) return null;

    final postRows = await _client
        .from('forum_posts')
        .select()
        .eq('thread_id', id)
        .order('created_at', ascending: true);

    final rows = (postRows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

    final names = await _authorNames(<String>[
      threadRow['user_id'] as String? ?? '',
      ...rows.map((row) => row['user_id']).whereType<String>(),
    ]);

    final thread = ForumThread.tryFromRow(threadRow, authorNames: names);
    if (thread == null) return null;

    final posts = rows
        .map((row) => ForumPost.tryFromRow(row, authorNames: names))
        .whereType<ForumPost>()
        .toList(growable: false);

    return ForumThreadDetail(thread: thread, posts: posts);
  }

  /// Membuat topik baru, mengembalikan id-nya.
  ///
  /// [mangaId]/[mangaTitle]/[mangaCoverUrl] diisi untuk kategori
  /// "rekomendasi" agar pembaca bisa langsung membuka manganya.
  Future<String> createThread({
    required String userId,
    required ForumCategory category,
    required String title,
    required String body,
    String? mangaId,
    String? mangaTitle,
    String? mangaCoverUrl,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': userId,
      'category': category.id,
      'title': title.trim(),
      'body': body.trim(),
    };

    if (mangaId != null && mangaId.isNotEmpty) {
      payload['manga_id'] = mangaId;
      payload['manga_title'] = mangaTitle;
      payload['manga_cover_url'] = mangaCoverUrl;
    }

    final row = await _client
        .from('forum_threads')
        .insert(payload)
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> createPost({
    required String userId,
    required String threadId,
    required String body,
  }) async {
    await _client.from('forum_posts').insert(<String, dynamic>{
      'thread_id': threadId,
      'user_id': userId,
      'body': body.trim(),
    });
  }

  Future<void> deleteThread(String id) async {
    await _client.from('forum_threads').delete().eq('id', id);
  }

  Future<void> deletePost(String id) async {
    await _client.from('forum_posts').delete().eq('id', id);
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Masuk dulu untuk melapor.');
    }

    await _client.from('forum_reports').insert(<String, dynamic>{
      'target_type': targetType,
      'target_id': targetId,
      'reporter_id': userId,
      'reason': reason.trim(),
    });
  }

  /// Username penulis. Kalau tabel profil belum bisa dibaca (mis. migrasi
  /// forum belum dijalankan), forum tetap tampil dengan nama umum.
  Future<Map<String, String>> _authorNames(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return const <String, String>{};

    try {
      final rows = await _client
          .from('profiles')
          .select('id, username')
          .inFilter('id', unique);

      final names = <String, String>{};
      for (final row in (rows as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final id = map['id'];
        final username = map['username'];
        if (id is String && username is String && username.trim().isNotEmpty) {
          names[id] = username.trim();
        }
      }
      return names;
    } catch (_) {
      return const <String, String>{};
    }
  }
}
