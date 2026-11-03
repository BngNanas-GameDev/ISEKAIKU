import 'models/manga.dart';

/// Pemetaan JSON MangaDex API v5 ke model aplikasi.
///
/// Dipisahkan dari [MangaDexApi] agar bisa diuji tanpa jaringan.
class MangaDexMapper {
  const MangaDexMapper._();

  static const String coverBase = 'https://uploads.mangadex.org/covers';

  static List<Manga> mangaList(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(manga)
        .toList(growable: false);
  }

  static Manga manga(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? '';
    final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
    final relationships = (data['relationships'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    String? coverUrl;
    String author = '';

    for (final rel in relationships) {
      final type = rel['type'];
      final relAttributes =
          rel['attributes'] as Map<String, dynamic>? ?? <String, dynamic>{};

      if (type == 'cover_art') {
        final fileName = relAttributes['fileName'] as String?;
        if (fileName != null) {
          coverUrl = '$coverBase/$id/$fileName.512.jpg';
        }
      } else if (type == 'author') {
        author = relAttributes['name'] as String? ?? author;
      }
    }

    final titles = attributes['title'] as Map<String, dynamic>? ?? {};
    final descriptions =
        attributes['description'] as Map<String, dynamic>? ?? {};
    final tags = (attributes['tags'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Manga(
      id: id,
      title: _localized(titles) ?? id,
      altTitle: titles['ja'] as String? ?? titles['en'] as String? ?? '',
      description: _localized(descriptions) ?? '',
      status: attributes['status'] as String? ?? 'ongoing',
      year: (attributes['year'] ?? '').toString(),
      contentRating: attributes['contentRating'] as String? ?? 'safe',
      genres: tags.map(_tagName).whereType<String>().toList(),
      coverUrl: coverUrl,
      author: author,
      originalLanguage: attributes['originalLanguage'] as String? ?? 'ja',
      follows: (attributes['follows'] as num?)?.toInt() ?? 0,
    );
  }

  static Chapter chapter(Map<String, dynamic> data) {
    final attributes = data['attributes'] as Map<String, dynamic>? ?? {};
    return Chapter(
      id: data['id'] as String? ?? '',
      title: attributes['title'] as String? ?? '',
      chapterNumber: (attributes['chapter'] ?? '').toString(),
      volume: (attributes['volume'] ?? '').toString(),
      language: attributes['translatedLanguage'] as String? ?? 'id',
      pages: (attributes['pages'] as num?)?.toInt() ?? 0,
      publishedAt: DateTime.tryParse(attributes['publishAt'] as String? ?? ''),
      externalUrl: attributes['externalUrl'] as String?,
    );
  }

  /// Urutkan chapter: bahasa pilihan dulu, lalu nomor volume/chapter.
  static List<Chapter> sortChapters(
    List<Chapter> chapters, {
    required String preferredLanguage,
  }) {
    final sorted = List<Chapter>.of(chapters);
    sorted.sort((a, b) {
      final aPreferred = a.language == preferredLanguage ? 0 : 1;
      final bPreferred = b.language == preferredLanguage ? 0 : 1;
      if (aPreferred != bPreferred) return aPreferred - bPreferred;

      final av = double.tryParse(a.volume);
      final bv = double.tryParse(b.volume);
      if (av != null && bv != null && av != bv) return av.compareTo(bv);

      final an = double.tryParse(a.chapterNumber);
      final bn = double.tryParse(b.chapterNumber);
      if (an != null && bn != null) return an.compareTo(bn);

      return a.chapterNumber.compareTo(b.chapterNumber);
    });
    return sorted;
  }

  static ChapterPages pages(String chapterId, Map<String, dynamic> json) {
    final chapter = json['chapter'] as Map<String, dynamic>? ?? {};
    return ChapterPages(
      chapterId: chapterId,
      baseUrl: json['baseUrl'] as String? ?? '',
      hash: chapter['hash'] as String? ?? '',
      data: (chapter['data'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      dataSaver: (chapter['dataSaver'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// id → en → ja → nilai pertama yang tidak kosong.
  static String? _localized(Map<String, dynamic> map) {
    for (final key in <String>['id', 'en', 'ja']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    for (final value in map.values) {
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static String? _tagName(Map<String, dynamic> tag) {
    final attributes = tag['attributes'] as Map<String, dynamic>? ?? {};
    return _localized(
      attributes['name'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }
}
