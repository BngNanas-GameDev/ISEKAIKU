import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'mangadex_mapper.dart';
import 'models/manga.dart';
import 'models/manga_tag.dart';

/// Pembungkus endpoint MangaDex API v5.
///
/// Semua request melewati [mangaDexClient] yang sudah memasang User-Agent,
/// throttle 1 req/detik, dan retry otomatis saat 429.
class MangaDexApi {
  final ApiClient _client;
  final ApiClient _probe;

  MangaDexApi([ApiClient? client, ApiClient? probe])
      : _client = client ?? mangaDexClient,
        _probe = probe ?? mangaDexProbeClient;

  static const List<String> _includeRelations = <String>[
    'cover_art',
    'author',
    'artist',
  ];

  /// Manga populer berdasarkan jumlah follower.
  Future<List<Manga>> popular({
    int limit = 20,
    int offset = 0,
    String language = 'id',
  }) async {
    final json = await _getJson('/manga', <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'includes': _includeRelations,
      'order[followedCount]': 'desc',
      'contentRating': <String>['safe', 'suggestive'],
      'availableTranslatedLanguage': <String>[language],
    });
    return MangaDexMapper.mangaList(json);
  }

  /// Manga terbaru (baru di-update).
  Future<List<Manga>> latest({
    int limit = 20,
    int offset = 0,
    String language = 'id',
  }) async {
    final json = await _getJson('/manga', <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'includes': _includeRelations,
      'order[latestUploadedChapter]': 'desc',
      'contentRating': <String>['safe', 'suggestive'],
      'availableTranslatedLanguage': <String>[language],
    });
    return MangaDexMapper.mangaList(json);
  }

  /// Pencarian judul.
  Future<List<Manga>> search(
    String query, {
    int limit = 24,
    int offset = 0,
  }) async {
    final json = await _getJson('/manga', <String, dynamic>{
      'title': query,
      'limit': limit,
      'offset': offset,
      'includes': _includeRelations,
      'order[relevance]': 'desc',
      'contentRating': <String>['safe', 'suggestive'],
    });
    return MangaDexMapper.mangaList(json);
  }

  /// Detail satu manga.
  Future<Manga> byId(String id) async {
    final json = await _getJson(
      '/manga/$id',
      <String, dynamic>{'includes': _includeRelations},
    );
    return MangaDexMapper.manga(json['data'] as Map<String, dynamic>);
  }

  /// Daftar chapter untuk **satu bahasa saja**.
  ///
  /// Chapter dengan bahasa lain tidak diikutkan, supaya daftar tidak berubah
  /// isi saat pengguna memilih ID lalu menggulir sampai bawah.
  ///
  /// `includeExternalUrl: 0` membuang chapter yang hanya menautkan situs lain
  /// (judul berlisensi), karena chapter seperti itu tidak bisa dibaca in-app.
  Future<List<Chapter>> chapters(
    String mangaId, {
    String language = 'id',
    int limit = 500,
  }) async {
    final json = await _getJson('/manga/$mangaId/feed', <String, dynamic>{
      'limit': limit,
      'translatedLanguage': <String>[language],
      'order[volume]': 'asc',
      'order[chapter]': 'asc',
      'includeEmptyPages': 0,
      'includeExternalUrl': 0,
      'contentRating': <String>['safe', 'suggestive'],
    });

    final data = (json['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(MangaDexMapper.chapter)
        .toList();

    return MangaDexMapper.sortChapters(data, preferredLanguage: language);
  }

  /// Jumlah chapter yang bisa dibaca pada [language].
  ///
  /// Memakai `limit=1` supaya payload kecil; total diambil dari metadata
  /// respons. Dipakai untuk menyaring judul yang tidak punya chapter.
  Future<int> chapterCount(String mangaId, {required String language}) async {
    final json = await _getProbeJson('/manga/$mangaId/feed', <String, dynamic>{
      'limit': 1,
      'translatedLanguage': <String>[language],
      'includeEmptyPages': 0,
      'includeExternalUrl': 0,
      'contentRating': <String>['safe', 'suggestive'],
    });
    return (json['total'] as num?)?.toInt() ?? 0;
  }

  /// URL gambar untuk chapter tertentu.
  Future<ChapterPages> pages(String chapterId) async {
    final json = await _getJson('/at-home/server/$chapterId', null);
    return MangaDexMapper.pages(chapterId, json);
  }

  /// Daftar tag untuk filter jelajah (hanya grup `genre`).
  Future<List<MangaTag>> tags() async {
    final json = await _getProbeJson('/manga/tag', null);
    final data = (json['data'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    final result = <MangaTag>[];
    for (final item in data) {
      final attributes =
          item['attributes'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final group = attributes['group'] as String? ?? 'genre';
      if (group != 'genre') continue;
      final names = attributes['name'] as Map<String, dynamic>? ?? {};
      final name = (names['en'] ?? names['id'] ?? '').toString();
      final id = item['id'] as String? ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      result.add(MangaTag(id: id, name: name, group: group));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Jelajah dengan filter genre, status, tahun, dan urutan.
  Future<List<Manga>> browse({
    required String language,
    List<String> tagIds = const <String>[],
    String? status,
    int? year,
    String order = 'followedCount',
    int limit = 24,
    int offset = 0,
  }) async {
    final json = await _getJson('/manga', <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'includes': _includeRelations,
      'order[$order]': 'desc',
      'contentRating': <String>['safe', 'suggestive'],
      'availableTranslatedLanguage': <String>[language],
      if (tagIds.isNotEmpty) 'includedTags': tagIds,
      if (status != null) 'status': <String>[status],
      if (year != null) 'year': year,
    });
    return MangaDexMapper.mangaList(json);
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, dynamic>? query,
  ) async {
    try {
      final data = await _client.get<dynamic>(path, query: query);
      if (data is Map<String, dynamic>) return data;
      throw ApiException(message: 'Respons tidak dikenal dari MangaDex');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  /// Sama seperti [_getJson], tetapi memakai client probe (throttle ringan).
  Future<Map<String, dynamic>> _getProbeJson(
    String path,
    Map<String, dynamic>? query,
  ) async {
    try {
      final data = await _probe.get<dynamic>(path, query: query);
      if (data is Map<String, dynamic>) return data;
      throw ApiException(message: 'Respons tidak dikenal dari MangaDex');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
