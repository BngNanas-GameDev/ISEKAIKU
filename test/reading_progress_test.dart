import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_providers.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:isekaiku/features/library/library_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingHistoryEntry _entry({int page = 0, int totalPages = 0}) {
  return ReadingHistoryEntry(
    mangaId: 'm1',
    mangaTitle: 'Judul',
    chapterId: 'c1',
    chapterNumber: '5',
    readAt: DateTime(2026, 5, 1),
    page: page,
    totalPages: totalPages,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('posisi halaman pada riwayat', () {
    test('page dan totalPages bertahan lewat JSON', () {
      final restored = ReadingHistoryEntry.tryFromJson(
        _entry(page: 7, totalPages: 40).toJson(),
      );

      expect(restored, isNotNull);
      expect(restored!.page, 7);
      expect(restored.totalPages, 40);
      expect(restored.progress, closeTo(7 / 40, 1e-9));
    });

    test('entri lama tanpa field posisi tetap terbaca', () {
      final restored = ReadingHistoryEntry.tryFromJson(<String, dynamic>{
        'mangaId': 'm1',
        'chapterId': 'c1',
        'readAt': '2026-05-01T00:00:00.000',
      });

      expect(restored, isNotNull);
      expect(restored!.page, 0);
      expect(restored.totalPages, 0);
      expect(restored.progress, isNull);
      expect(restored.positionLabel, 'Chapter');
    });

    test('positionLabel menyesuaikan data yang tersedia', () {
      expect(_entry(page: 5).positionLabel, 'Halaman 5');
      expect(
        _entry(page: 5, totalPages: 20).positionLabel,
        'Halaman 5 / 20',
      );
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      final updated = _entry(page: 3, totalPages: 10).copyWith(page: 9);

      expect(updated.page, 9);
      expect(updated.totalPages, 10);
      expect(updated.chapterId, 'c1');
    });
  });

  group('ReadChaptersNotifier', () {
    Future<ProviderContainer> build() async {
      final storage = await StorageService.create();
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('markRead menyimpan chapter dan idempoten', () async {
      final container = await build();
      final notifier = container.read(readChaptersProvider.notifier);

      notifier.markRead('m1', 'c1');
      notifier.markRead('m1', 'c1');

      expect(container.read(readChapterIdsProvider('m1')), <String>{'c1'});
      expect(
        container.read(isChapterReadProvider(('m1', 'c1'))),
        isTrue,
      );
      expect(
        container.read(isChapterReadProvider(('m1', 'c2'))),
        isFalse,
      );
    });

    test('markAllRead menambahkan banyak chapter sekaligus', () async {
      final container = await build();
      container
          .read(readChaptersProvider.notifier)
          .markAllRead('m1', <String>['c1', 'c2', 'c3']);

      expect(
        container.read(readChapterIdsProvider('m1')),
        <String>{'c1', 'c2', 'c3'},
      );
    });

    test('unmarkRead dan clearManga bekerja', () async {
      final container = await build();
      final notifier = container.read(readChaptersProvider.notifier);
      notifier.markAllRead('m1', <String>['c1', 'c2']);

      notifier.unmarkRead('m1', 'c1');
      expect(container.read(readChapterIdsProvider('m1')), <String>{'c2'});

      notifier.clearManga('m1');
      expect(container.read(readChapterIdsProvider('m1')), isEmpty);
    });

    test('tersimpan ke storage dan terbaca lagi oleh store baru', () async {
      final storage = await StorageService.create();
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      container.read(readChaptersProvider.notifier).markRead('m1', 'c9');

      final store = LibraryStore(storage);
      expect(store.loadReadChapters()['m1'], <String>{'c9'});
    });
  });
}
