import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'mangadex_mapper.dart';
import 'models/manga.dart';

/// Pembungkus endpoint MangaDex API v5.
///
/// Semua request melewati [mangaDexClient] yang sudah memasang User-Agent,
/// throttle 1 req/detik, dan retry otomatis saat 429.
class MangaDexApi {
  final ApiClient _client;

  MangaDexApi([ApiClient? client]) : _client = client ?? mangaDexClient;

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

  /// Daftar chapter. Preferensi bahasa [language], fallback [fallbackLanguage].
  Future<List<Chapter>> chapters(
    String mangaId, {
    String language = 'id',
    String fallbackLanguage = 'en',
    int limit = 500,
  }) async {
    final languages = <String>{language, fallbackLanguage}.toList();

    final json = await _getJson('/manga/$mangaId/feed', <String, dynamic>{
      'limit': limit,
      'translatedLanguage': languages,
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

    return MangaDexMapper.sortChapters(
      data,
      preferredLanguage: language,
    );
  }

  /// URL gambar untuk chapter tertentu.
  Future<ChapterPages> pages(String chapterId) async {
    final json = await _getJson('/at-home/server/$chapterId', null);
    return MangaDexMapper.pages(chapterId, json);
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
}
