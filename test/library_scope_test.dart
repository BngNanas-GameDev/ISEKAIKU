import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ReadingHistoryEntry entry(String mangaId) => ReadingHistoryEntry(
    mangaId: mangaId,
    mangaTitle: mangaId,
    chapterId: 'c1',
    readAt: DateTime(2026, 1, 1),
  );

  test('riwayat akun A tidak muncul di akun B', () async {
    final storage = await StorageService.create();
    final storeA = LibraryStore(storage, scope: 'user-a');
    final storeB = LibraryStore(storage, scope: 'user-b');
    final guest = LibraryStore(storage);

    await storeA.saveHistory(<ReadingHistoryEntry>[entry('manga-a')]);

    expect(storeA.loadHistory().map((e) => e.mangaId), <String>['manga-a']);
    expect(storeB.loadHistory(), isEmpty);
    expect(guest.loadHistory(), isEmpty);
  });

  test('manga diikuti dan chapter terbaca juga terpisah', () async {
    final storage = await StorageService.create();
    final storeA = LibraryStore(storage, scope: 'user-a');
    final storeB = LibraryStore(storage, scope: 'user-b');

    await storeA.saveFollowed(<FollowedManga>[
      FollowedManga(id: 'm1', title: 'Satu', followedAt: DateTime(2026)),
    ]);
    await storeA.saveReadChapters(<String, Set<String>>{
      'm1': <String>{'c1', 'c2'},
    });

    expect(storeA.loadFollowed(), hasLength(1));
    expect(storeA.loadReadChapters()['m1'], hasLength(2));
    expect(storeB.loadFollowed(), isEmpty);
    expect(storeB.loadReadChapters(), isEmpty);
  });

  test('tombstone terpisah per akun', () async {
    final storage = await StorageService.create();
    final storeA = LibraryStore(storage, scope: 'user-a');
    final storeB = LibraryStore(storage, scope: 'user-b');

    await storeA.recordDeletedHistory('m1');

    expect(storeA.loadDeletedHistory().containsKey('m1'), isTrue);
    expect(storeB.loadDeletedHistory(), isEmpty);
  });

  test('data versi lama dipindah ke akun pertama yang membuka', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LibraryStore.legacyHistoryKey: <String>[
        '{"mangaId":"lama","mangaTitle":"Lama","chapterId":"c1",'
            '"readAt":"2026-01-01T00:00:00.000"}',
      ],
    });

    final storage = await StorageService.create();
    expect(
      storage.getStringList(LibraryStore.legacyHistoryKey),
      isNotEmpty,
      reason: 'data lama harus ada sebelum migrasi',
    );
    LibraryStore.claimLegacy(storage, 'user-a');
    expect(
      storage.getStringList(LibraryStore.historyKeyFor('user-a')),
      isNotEmpty,
      reason: 'data harus tersalin ke akun',
    );

    final storeA = LibraryStore(storage, scope: 'user-a');
    final storeB = LibraryStore(storage, scope: 'user-b');

    expect(storeA.loadHistory().map((e) => e.mangaId), <String>['lama']);
    expect(storeB.loadHistory(), isEmpty);
    expect(storage.getStringList(LibraryStore.legacyHistoryKey), isEmpty);
  });

  test('data lama tidak dipindah ke guest', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LibraryStore.legacyHistoryKey: <String>[
        '{"mangaId":"lama","mangaTitle":"Lama","chapterId":"c1",'
            '"readAt":"2026-01-01T00:00:00.000"}',
      ],
    });

    final storage = await StorageService.create();
    LibraryStore.claimLegacy(storage, LibraryStore.guestScope);

    final guest = LibraryStore(storage);
    expect(guest.loadHistory(), isEmpty);
    expect(storage.getStringList(LibraryStore.legacyHistoryKey), isNotEmpty);
  });

  test('clearAll menghapus data scope ini saja', () async {
    final storage = await StorageService.create();
    final storeA = LibraryStore(storage, scope: 'user-a');
    final storeB = LibraryStore(storage, scope: 'user-b');

    await storeA.saveHistory(<ReadingHistoryEntry>[entry('a')]);
    await storeA.recordDeletedHistory('a');
    await storeB.saveHistory(<ReadingHistoryEntry>[entry('b')]);

    await storeA.clearAll();

    expect(storeA.loadHistory(), isEmpty);
    expect(storeA.loadDeletedHistory(), isEmpty);
    expect(storeB.loadHistory().map((e) => e.mangaId), <String>['b']);
  });
}
