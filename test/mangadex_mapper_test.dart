import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/features/manga/data/mangadex_mapper.dart';
import 'package:isekaiku/features/manga/data/models/manga.dart';

/// Contoh respons asli MangaDex API v5 (dipangkas).
const String _mangaListJson = '''
{
  "result": "ok",
  "data": [
    {
      "id": "a1c7c817-4e59-43b7-9365-09675a149a6f",
      "type": "manga",
      "attributes": {
        "title": {"en": "One Piece"},
        "description": {"en": "Gol D. Roger was known as the Pirate King.", "id": "Gol D. Roger dikenal sebagai Raja Bajak Laut."},
        "year": 1997,
        "contentRating": "safe",
        "status": "ongoing",
        "originalLanguage": "ja",
        "follows": 123456,
        "tags": [
          {"attributes": {"name": {"en": "Action", "id": "Aksi"}}},
          {"attributes": {"name": {"en": "Adventure"}}}
        ]
      },
      "relationships": [
        {"type": "author", "attributes": {"name": "Oda Eiichiro"}},
        {"type": "cover_art", "attributes": {"fileName": "cover-abc.jpg"}}
      ]
    }
  ]
}
''';

const String _chapterFeedJson = '''
{
  "result": "ok",
  "data": [
    {"id": "ch-2", "attributes": {"title": "Chapter 2", "chapter": "2", "volume": "1", "translatedLanguage": "en", "pages": 18, "publishAt": "2024-02-02T00:00:00+00:00"}},
    {"id": "ch-1", "attributes": {"title": "", "chapter": "1", "volume": "1", "translatedLanguage": "id", "pages": 20}},
    {"id": "ch-10", "attributes": {"title": "", "chapter": "10", "volume": "2", "translatedLanguage": "id", "pages": 19}}
  ]
}
''';

const String _atHomeJson = '''
{
  "result": "ok",
  "baseUrl": "https://uploads.mangadex.org",
  "chapter": {
    "hash": "abc123",
    "data": ["1.png", "2.png"],
    "dataSaver": ["1.jpg"]
  }
}
''';

void main() {
  group('MangaDexMapper.mangaList', () {
    final json = jsonDecode(_mangaListJson) as Map<String, dynamic>;
    final list = MangaDexMapper.mangaList(json);

    test('memetakan id, judul, dan cover', () {
      expect(list, hasLength(1));
      final manga = list.first;
      expect(manga.id, 'a1c7c817-4e59-43b7-9365-09675a149a6f');
      expect(manga.title, 'One Piece');
      expect(
        manga.coverUrl,
        'https://uploads.mangadex.org/covers/a1c7c817-4e59-43b7-9365-09675a149a6f/cover-abc.jpg.512.jpg',
      );
    });

    test('memetakan author, status, tahun, dan follower', () {
      final manga = list.first;
      expect(manga.author, 'Oda Eiichiro');
      expect(manga.status, 'ongoing');
      expect(manga.year, '1997');
      expect(manga.follows, 123456);
    });

    test('deskripsi memakai bahasa Indonesia bila tersedia', () {
      expect(
        list.first.description,
        'Gol D. Roger dikenal sebagai Raja Bajak Laut.',
      );
    });

    test('genre diambil dari nama tag', () {
      expect(list.first.genres, <String>['Aksi', 'Adventure']);
    });
  });

  group('MangaDexMapper.chapter', () {
    final json = jsonDecode(_chapterFeedJson) as Map<String, dynamic>;
    final chapters = (json['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MangaDexMapper.chapter)
        .toList();

    test('memetakan field chapter', () {
      final first = chapters.first;
      expect(first.id, 'ch-2');
      expect(first.chapterNumber, '2');
      expect(first.volume, '1');
      expect(first.language, 'en');
      expect(first.pages, 18);
      expect(first.publishedAt, isNotNull);
    });

    test('mengurutkan nomor chapter secara numerik', () {
      final sorted = MangaDexMapper.sortChapters(
        chapters,
        preferredLanguage: 'id',
      );
      expect(
        sorted.map((c) => c.id).toList(),
        <String>['ch-1', 'ch-10', 'ch-2'],
      );
    });

    test('bahasa pilihan didahulukan', () {
      final sorted = MangaDexMapper.sortChapters(
        chapters,
        preferredLanguage: 'en',
      );
      expect(sorted.first.language, 'en');
    });
  });

  group('MangaDexMapper.pages', () {
    final json = jsonDecode(_atHomeJson) as Map<String, dynamic>;
    final pages = MangaDexMapper.pages('ch-1', json);

    test('menyusun URL halaman kualitas penuh', () {
      expect(pages.urls(), <String>[
        'https://uploads.mangadex.org/data/abc123/1.png',
        'https://uploads.mangadex.org/data/abc123/2.png',
      ]);
    });

    test('menyusun URL halaman data-saver', () {
      expect(pages.urls(saver: true), <String>[
        'https://uploads.mangadex.org/data-saver/abc123/1.jpg',
      ]);
    });
  });
}
