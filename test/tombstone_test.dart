import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_providers.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:isekaiku/features/library/library_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('tombstone penyimpanan', () {
    test('recordDeletedFollowed tersimpan dan bisa dibersihkan', () async {
      final storage = await StorageService.create();
      final store = LibraryStore(storage);

      await store.recordDeletedFollowed('m1');
      expect(store.loadDeletedFollowed().keys, contains('m1'));

      await store.clearDeletedFollowed();
      expect(store.loadDeletedFollowed(), isEmpty);
    });

    test('recordDeletedHistory terpisah dari followed', () async {
      final storage = await StorageService.create();
      final store = LibraryStore(storage);

      await store.recordDeletedHistory('m2');

      expect(store.loadDeletedHistory().keys, contains('m2'));
      expect(store.loadDeletedFollowed(), isEmpty);
    });
  });

  group('notifier mencatat tombstone saat menghapus', () {
    Future<ProviderContainer> build(StorageService storage) async {
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('berhenti mengikuti menulis tombstone', () async {
      final storage = await StorageService.create();
      final store = LibraryStore(storage);
      await store.saveFollowed(<FollowedManga>[
        FollowedManga(id: 'm1', title: 'Satu', followedAt: DateTime(2026)),
      ]);

      final container = await build(storage);
      container.read(followedMangaProvider.notifier).remove('m1');

      expect(store.loadFollowed(), isEmpty);
      expect(store.loadDeletedFollowed().containsKey('m1'), isTrue);
    });

    test('hapus riwayat dan hapus semua menulis tombstone', () async {
      final storage = await StorageService.create();
      final store = LibraryStore(storage);
      await store.saveHistory(<ReadingHistoryEntry>[
        ReadingHistoryEntry(
          mangaId: 'a',
          mangaTitle: 'A',
          chapterId: 'c1',
          readAt: DateTime(2026),
        ),
        ReadingHistoryEntry(
          mangaId: 'b',
          mangaTitle: 'B',
          chapterId: 'c2',
          readAt: DateTime(2026),
        ),
      ]);

      final container = await build(storage);
      final notifier = container.read(readingHistoryProvider.notifier);

      notifier.remove('a');
      expect(store.loadDeletedHistory().containsKey('a'), isTrue);

      notifier.clear();
      final deleted = store.loadDeletedHistory();
      expect(deleted.containsKey('a'), isTrue);
      expect(deleted.containsKey('b'), isTrue);
    });
  });
}
