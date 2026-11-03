import '../../../manga/data/models/manga.dart';

/// Manga yang diikuti (disimpan lokal, tanpa akun MangaDex).
class FollowedManga {
  const FollowedManga({
    required this.id,
    required this.title,
    required this.followedAt,
    this.coverUrl,
    this.author = '',
  });

  final String id;
  final String title;
  final String? coverUrl;
  final String author;
  final DateTime followedAt;

  /// Bentuk yang bisa dipakai ulang oleh widget grid manga.
  Manga toManga() => Manga(
        id: id,
        title: title,
        coverUrl: coverUrl,
        author: author,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'coverUrl': coverUrl,
        'author': author,
        'followedAt': followedAt.toIso8601String(),
      };

  static FollowedManga? tryFromJson(Map<String, dynamic> json) {
    final dynamic id = json['id'];
    final dynamic title = json['title'];
    if (id is! String || id.isEmpty || title is! String) return null;
    return FollowedManga(
      id: id,
      title: title,
      coverUrl: json['coverUrl'] is String ? json['coverUrl'] as String : null,
      author: json['author'] is String ? json['author'] as String : '',
      followedAt: DateTime.tryParse(json['followedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Satu baris riwayat baca: chapter terakhir yang dibuka untuk sebuah manga.
class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterId,
    required this.readAt,
    this.coverUrl,
    this.chapterNumber = '',
    this.chapterTitle = '',
  });

  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final String chapterId;
  final String chapterNumber;
  final String chapterTitle;
  final DateTime readAt;

  /// Label chapter untuk ditampilkan di daftar riwayat.
  String get chapterLabel {
    if (chapterNumber.isNotEmpty) return 'Chapter $chapterNumber';
    if (chapterTitle.isNotEmpty) return chapterTitle;
    return 'Chapter';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mangaId': mangaId,
        'mangaTitle': mangaTitle,
        'coverUrl': coverUrl,
        'chapterId': chapterId,
        'chapterNumber': chapterNumber,
        'chapterTitle': chapterTitle,
        'readAt': readAt.toIso8601String(),
      };

  static ReadingHistoryEntry? tryFromJson(Map<String, dynamic> json) {
    final dynamic mangaId = json['mangaId'];
    final dynamic chapterId = json['chapterId'];
    if (mangaId is! String || mangaId.isEmpty) return null;
    if (chapterId is! String || chapterId.isEmpty) return null;
    return ReadingHistoryEntry(
      mangaId: mangaId,
      mangaTitle:
          json['mangaTitle'] is String ? json['mangaTitle'] as String : '',
      coverUrl: json['coverUrl'] is String ? json['coverUrl'] as String : null,
      chapterId: chapterId,
      chapterNumber:
          json['chapterNumber'] is String ? json['chapterNumber'] as String : '',
      chapterTitle:
          json['chapterTitle'] is String ? json['chapterTitle'] as String : '',
      readAt: DateTime.tryParse(json['readAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
