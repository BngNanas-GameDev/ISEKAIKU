import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/library/data/library_backup.dart';
import '../../features/library/data/library_store.dart';
import '../../features/library/data/models/library_models.dart';

/// Pemetaan model lokal <-> baris Postgres.
///
/// Dipisahkan sebagai fungsi murni supaya bisa diuji tanpa jaringan.
class RemoteMapping {
  const RemoteMapping._();

  static Map<String, dynamic> followedRow(String userId, FollowedManga item) {
    return <String, dynamic>{
      'user_id': userId,
      'manga_id': item.id,
      'title': item.title,
      'cover_url': item.coverUrl,
      'author': item.author,
      'followed_at': item.followedAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> progressRow(
    String userId,
    ReadingHistoryEntry entry,
  ) {
    return <String, dynamic>{
      'user_id': userId,
      'manga_id': entry.mangaId,
      'manga_title': entry.mangaTitle,
      'cover_url': entry.coverUrl,
      'chapter_id': entry.chapterId,
      'chapter_number': entry.chapterNumber,
      'chapter_title': entry.chapterTitle,
      'page': entry.page,
      'total_pages': entry.totalPages,
      'read_at': entry.readAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Map<String, dynamic> readRow(
    String userId,
    String mangaId,
    String chapterId, {
    DateTime? readAt,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'manga_id': mangaId,
      'chapter_id': chapterId,
      'read_at': (readAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  static FollowedManga? followedFromRow(Map<String, dynamic> row) {
    final mangaId = row['manga_id'];
    final title = row['title'];
    if (mangaId is! String || mangaId.isEmpty || title is! String) return null;
    return FollowedManga(
      id: mangaId,
      title: title,
      coverUrl: row['cover_url'] as String?,
      author: row['author'] as String? ?? '',
      followedAt: _parseTime(row['followed_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static ReadingHistoryEntry? progressFromRow(Map<String, dynamic> row) {
    final mangaId = row['manga_id'];
    final chapterId = row['chapter_id'];
    if (mangaId is! String || mangaId.isEmpty) return null;
    if (chapterId is! String || chapterId.isEmpty) return null;
    return ReadingHistoryEntry(
      mangaId: mangaId,
      mangaTitle: row['manga_title'] as String? ?? '',
      coverUrl: row['cover_url'] as String?,
      chapterId: chapterId,
      chapterNumber: row['chapter_number'] as String? ?? '',
      chapterTitle: row['chapter_title'] as String? ?? '',
      page: (row['page'] as num?)?.toInt() ?? 0,
      totalPages: (row['total_pages'] as num?)?.toInt() ?? 0,
      readAt: _parseTime(row['read_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _parseTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

/// Sinkronisasi Pustaka lokal dengan tabel Supabase.
///
/// Strategi: **pull → merge → push**, dengan `updated_at`/`read_at` terbaru
/// menang. Impor dari cloud memakai aturan gabung yang sama seperti backup
/// lokal, jadi tidak ada data yang hilang.
class RemoteLibrary {
  RemoteLibrary(this._client, this._store);

  final SupabaseClient _client;
  final LibraryStore _store;

  static const int _chunk = 500;

  Future<void> sync(String userId) async {
    await pull(userId);
    await push(userId);
  }

  Future<void> pull(String userId) async {
    final deletedFollowed = _store.loadDeletedFollowed();
    final deletedHistory = _store.loadDeletedHistory();

    // --- manga diikuti ---
    final followedRows = await _client
        .from('library_entries')
        .select()
        .eq('user_id', userId);
    final remoteFollowed = <FollowedManga>[];
    for (final row in (followedRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final mangaId = map['manga_id'];
      if (mangaId is String && _deletedAfter(deletedFollowed, mangaId, map)) {
        continue; // penghapusan lokal lebih baru dari data server
      }
      final mapped = RemoteMapping.followedFromRow(map);
      if (mapped != null) remoteFollowed.add(mapped);
    }
    if (remoteFollowed.isNotEmpty) {
      await _store.saveFollowed(
        LibraryBackup.mergeFollowed(_store.loadFollowed(), remoteFollowed),
      );
    }

    // --- progres baca ---
    final progressRows = await _client
        .from('reading_progress')
        .select()
        .eq('user_id', userId);
    final remoteProgress = <ReadingHistoryEntry>[];
    for (final row in (progressRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final mangaId = map['manga_id'];
      if (mangaId is String && _deletedAfter(deletedHistory, mangaId, map)) {
        continue;
      }
      final mapped = RemoteMapping.progressFromRow(map);
      if (mapped != null) remoteProgress.add(mapped);
    }
    if (remoteProgress.isNotEmpty) {
      await _store.saveHistory(
        LibraryBackup.mergeHistory(_store.loadHistory(), remoteProgress),
      );
    }

    // --- chapter terbaca ---
    final readRows = await _client
        .from('read_chapters')
        .select()
        .eq('user_id', userId);
    final remoteRead = <String, Set<String>>{};
    for (final row in (readRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final mangaId = map['manga_id'];
      final chapterId = map['chapter_id'];
      if (mangaId is String && chapterId is String) {
        remoteRead.putIfAbsent(mangaId, () => <String>{}).add(chapterId);
      }
    }
    if (remoteRead.isNotEmpty) {
      await _store.saveReadChapters(
        LibraryBackup.mergeReadChapters(_store.loadReadChapters(), remoteRead),
      );
    }
  }

  /// True bila [mangaId] pernah dihapus lokal dan tidak ada data server yang
  /// lebih baru (mis. di-follow ulang dari perangkat lain).
  bool _deletedAfter(
    Map<String, DateTime> deleted,
    String mangaId,
    Map<String, dynamic> row,
  ) {
    final deletion = deleted[mangaId];
    if (deletion == null) return false;
    final updated = _parseTime(row['updated_at']);
    if (updated == null) return true;
    return !updated.isAfter(deletion);
  }

  DateTime? _parseTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> push(String userId) async {
    // Kirim penghapusan lebih dulu, supaya server tidak lagi menyimpan data
    // yang sudah tidak diikuti pengguna.
    final deletedFollowed = _store.loadDeletedFollowed();
    if (deletedFollowed.isNotEmpty) {
      await _client
          .from('library_entries')
          .delete()
          .eq('user_id', userId)
          .inFilter('manga_id', deletedFollowed.keys.toList());
      await _store.clearDeletedFollowed();
    }

    final deletedHistory = _store.loadDeletedHistory();
    if (deletedHistory.isNotEmpty) {
      await _client
          .from('reading_progress')
          .delete()
          .eq('user_id', userId)
          .inFilter('manga_id', deletedHistory.keys.toList());
      await _store.clearDeletedHistory();
    }

    final followed = _store.loadFollowed();
    if (followed.isNotEmpty) {
      await _client.from('library_entries').upsert(
            followed
                .map((e) => RemoteMapping.followedRow(userId, e))
                .toList(growable: false),
          );
    }

    final history = _store.loadHistory();
    if (history.isNotEmpty) {
      await _client.from('reading_progress').upsert(
            history
                .map((e) => RemoteMapping.progressRow(userId, e))
                .toList(growable: false),
          );
    }

    final readChapters = _store.loadReadChapters();
    final rows = <Map<String, dynamic>>[];
    readChapters.forEach((String mangaId, Set<String> chapterIds) {
      for (final chapterId in chapterIds) {
        rows.add(RemoteMapping.readRow(userId, mangaId, chapterId));
      }
    });
    for (var i = 0; i < rows.length; i += _chunk) {
      final end = (i + _chunk < rows.length) ? i + _chunk : rows.length;
      await _client
          .from('read_chapters')
          .upsert(rows.sublist(i, end));
    }
  }
}
