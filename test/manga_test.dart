import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/features/manga/data/mangadex_api.dart';
import 'package:isekaiku/features/manga/data/models/manga.dart';
import 'package:isekaiku/features/manga/manga_providers.dart';

void main() {
  group('ChapterPages.urls', () {
    const pages = ChapterPages(
      chapterId: 'abc',
      baseUrl: 'https://cdn.example',
      hash: 'hash1',
      data: <String>['1.png', '2.png'],
      dataSaver: <String>['1.jpg'],
    );

    test('kualitas data penuh', () {
      expect(pages.urls(), <String>[
        'https://cdn.example/data/hash1/1.png',
        'https://cdn.example/data/hash1/2.png',
      ]);
    });

    test('kualitas data-saver memakai folder data-saver', () {
      expect(pages.urls(saver: true), <String>[
        'https://cdn.example/data-saver/hash1/1.jpg',
      ]);
    });

    test('fallback ke data penuh jika data-saver kosong', () {
      const onlyFull = ChapterPages(
        chapterId: 'abc',
        baseUrl: 'https://cdn.example',
        hash: 'hash1',
        data: <String>['1.png'],
      );
      expect(onlyFull.urls(saver: true), <String>[
        'https://cdn.example/data/hash1/1.png',
      ]);
    });
  });

  test('pencarian kosong tidak memanggil jaringan', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(searchResultsProvider('').future);
    expect(result, isEmpty);
  });

  group('rating konten', () {
    test('bawaan hanya safe dan suggestive', () {
      expect(MangaDexApi.contentRatings(adult: false), <String>[
        'safe',
        'suggestive',
      ]);
    });

    test('mode 18+ menyertakan erotika dan dewasa', () {
      final ratings = MangaDexApi.contentRatings(adult: true);
      expect(
        ratings,
        containsAll(<String>['safe', 'suggestive', 'erotica', 'pornographic']),
      );
    });
  });
}
