/// Model forum komunitas.
///
/// Semua field berasal dari tabel Supabase (`forum_threads`, `forum_posts`).
/// Nama penulis diambil dari `profiles.username`, jadi baris mentah tidak
/// memuatnya sendirian.
library;

enum ForumCategory {
  umum('umum', 'Umum'),
  rekomendasi('rekomendasi', 'Rekomendasi'),
  bantuan('bantuan', 'Bantuan'),
  offtopic('offtopic', 'Off-topic');

  const ForumCategory(this.id, this.label);

  /// Nilai yang disimpan di kolom `category`.
  final String id;

  /// Label yang tampil di aplikasi.
  final String label;

  static ForumCategory fromId(Object? value) {
    return values.firstWhere(
      (category) => category.id == value,
      orElse: () => ForumCategory.umum,
    );
  }
}

/// Topik diskusi.
class ForumThread {
  const ForumThread({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.title,
    required this.body,
    required this.replyCount,
    required this.createdAt,
    required this.lastActivityAt,
    this.mangaId,
    this.isPinned = false,
    this.isLocked = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final ForumCategory category;
  final String title;
  final String body;
  final int replyCount;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final String? mangaId;
  final bool isPinned;
  final bool isLocked;

  ForumThread copyWith({int? replyCount, DateTime? lastActivityAt}) {
    return ForumThread(
      id: id,
      authorId: authorId,
      authorName: authorName,
      category: category,
      title: title,
      body: body,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      mangaId: mangaId,
      isPinned: isPinned,
      isLocked: isLocked,
    );
  }

  /// `null` bila baris tidak lengkap (mis. respons rusak).
  static ForumThread? tryFromRow(
    Map<String, dynamic> row, {
    Map<String, String> authorNames = const <String, String>{},
  }) {
    final dynamic id = row['id'];
    final dynamic userId = row['user_id'];
    final dynamic title = row['title'];
    if (id is! String || userId is! String || title is! String) return null;

    return ForumThread(
      id: id,
      authorId: userId,
      authorName: authorNames[userId] ?? 'Pengguna Isekaiku',
      category: ForumCategory.fromId(row['category']),
      title: title,
      body: row['body'] is String ? row['body'] as String : '',
      replyCount: _asInt(row['reply_count']),
      createdAt: _asDate(row['created_at']),
      lastActivityAt: _asDate(row['last_activity_at']),
      mangaId: row['manga_id'] is String ? row['manga_id'] as String : null,
      isPinned: row['is_pinned'] == true,
      isLocked: row['is_locked'] == true,
    );
  }
}

/// Balasan pada sebuah topik.
class ForumPost {
  const ForumPost({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  static ForumPost? tryFromRow(
    Map<String, dynamic> row, {
    Map<String, String> authorNames = const <String, String>{},
  }) {
    final dynamic id = row['id'];
    final dynamic threadId = row['thread_id'];
    final dynamic userId = row['user_id'];
    final dynamic body = row['body'];
    if (id is! String ||
        threadId is! String ||
        userId is! String ||
        body is! String) {
      return null;
    }

    return ForumPost(
      id: id,
      threadId: threadId,
      authorId: userId,
      authorName: authorNames[userId] ?? 'Pengguna Isekaiku',
      body: body,
      createdAt: _asDate(row['created_at']),
    );
  }
}

/// Topik beserta seluruh balasannya.
class ForumThreadDetail {
  const ForumThreadDetail({required this.thread, required this.posts});

  final ForumThread thread;
  final List<ForumPost> posts;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _asDate(Object? value) {
  final parsed = value is String ? DateTime.tryParse(value) : null;
  return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal();
}
