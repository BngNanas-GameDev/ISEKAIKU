import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_providers.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LibraryStore> _newStore() async =>
    LibraryStore(await StorageService.create());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('FollowedManga', () {
    test('round-trip JSON mempertahankan field', () {
      final original = FollowedManga(
        id: 'abc',
        title: 'Judul',
        coverUrl: 'https://contoh/cover.jpg',
        author: 'Penulis',
        followedAt: DateTime(2026, 3, 4, 5, 6, 7),
      );

      final restored = FollowedManga.tryFromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.title, original.title);
      expect(restored.coverUrl, original.coverUrl);
      expect(restored.author, original.author);
      expect(restored.followedAt, original.followedAt);
    });

    test('json tanpa id ditolak', () {
      expect(
        FollowedManga.tryFromJson(<String, dynamic>{'title': 'x'}),
        isNull,
      );
    });
  });

  group('LibraryStore.followed', () {
    test('simpan lalu muat, urut terbaru dulu', () async {
      final store = await _newStore();
      await store.saveFollowed(<FollowedManga>[
        FollowedManga(
          id: 'lama',
          title: 'Lama',
          followedAt: DateTime(2026, 1, 1),
        ),
        FollowedManga(
          id: 'baru',
          title: 'Baru',
          followedAt: DateTime(2026, 2, 1),
        ),
      ]);

      final loaded = store.loadFollowed();

      expect(loaded.map((e) => e.id).toList(), <String>['baru', 'lama']);
    });

    test('entri rusak dilewati, entri valid tetap terbaca', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LibraryStore.followedKeyFor(LibraryStore.guestScope): <String>[
          'bukan json',
          '{"id":"ok","title":"Valid","followedAt":"2026-01-01T00:00:00.000"}',
          '{"tanpa":"id"}',
        ],
      });

      final store = await _newStore();
      final loaded = store.loadFollowed();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'ok');
    });

    test('daftar kosong menghasilkan list kosong', () async {
      final store = await _newStore();
      expect(store.loadFollowed(), isEmpty);
    });
  });

  group('LibraryStore.history', () {
    test('simpan lalu muat, satu entri per manga', () async {
      final store = await _newStore();
      await store.saveHistory(<ReadingHistoryEntry>[
        ReadingHistoryEntry(
          mangaId: 'a',
          mangaTitle: 'Alpha',
          chapterId: 'c1',
          chapterNumber: '1',
          readAt: DateTime(2026, 5, 1),
        ),
        ReadingHistoryEntry(
          mangaId: 'b',
          mangaTitle: 'Beta',
          chapterId: 'c9',
          chapterNumber: '9',
          readAt: DateTime(2026, 5, 2),
        ),
      ]);

      final loaded = store.loadHistory();

      expect(loaded.map((e) => e.mangaId).toList(), <String>['b', 'a']);
      expect(loaded.first.chapterLabel, 'Chapter 9');
    });

    test('riwayat tanpa chapterId ditolak', () {
      expect(
        ReadingHistoryEntry.tryFromJson(<String, dynamic>{'mangaId': 'a'}),
        isNull,
      );
    });

    test('chapterLabel jatuh ke judul lalu default', () {
      ReadingHistoryEntry build({String number = '', String title = ''}) =>
          ReadingHistoryEntry(
            mangaId: 'a',
            mangaTitle: 'A',
            chapterId: 'c',
            chapterNumber: number,
            chapterTitle: title,
            readAt: DateTime(2026),
          );

      expect(build(number: '3').chapterLabel, 'Chapter 3');
      expect(build(title: 'Prolog').chapterLabel, 'Prolog');
      expect(build().chapterLabel, 'Chapter');
    });
  });

  group('PersistentBoolNotifier', () {
    test('set menyimpan nilai ke storage', () async {
      final storage = await StorageService.create();
      final notifier = PersistentBoolNotifier(storage, 'uji.bool', false);

      notifier.set(true);

      expect(notifier.state, isTrue);
      expect(storage.getBool('uji.bool'), isTrue);
    });

    test(
      'nilai awal mengikuti storage bila dibaca lewat pola provider',
      () async {
        final storage = await StorageService.create();
        await storage.setBool('uji.awal', true);

        // Provider membaca storage lalu meneruskan nilainya sebagai state awal.
        final notifier = PersistentBoolNotifier(
          storage,
          'uji.awal',
          storage.getBool('uji.awal', fallback: false),
        );

        expect(notifier.state, isTrue);
      },
    );
  });
}
