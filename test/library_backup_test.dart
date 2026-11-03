import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/library/data/library_backup.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

FollowedManga _followed(String id, DateTime at, {String title = ''}) {
  return FollowedManga(
    id: id,
    title: title.isEmpty ? 'Judul $id' : title,
    followedAt: at,
  );
}

ReadingHistoryEntry _history(
  String mangaId,
  String chapterId,
  DateTime at, {
  int page = 0,
}) {
  return ReadingHistoryEntry(
    mangaId: mangaId,
    mangaTitle: 'Judul $mangaId',
    chapterId: chapterId,
    chapterNumber: '1',
    readAt: at,
    page: page,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('encode/decode', () {
    test('round-trip mempertahankan data', () {
      final backup = LibraryBackup(
        followed: <FollowedManga>[
          _followed('a', DateTime(2026, 1, 1)),
          _followed('b', DateTime(2026, 1, 2)),
        ],
        history: <ReadingHistoryEntry>[
          _history('a', 'c1', DateTime(2026, 2, 1), page: 7),
        ],
        readChapters: <String, Set<String>>{
          'a': <String>{'c1', 'c2'},
        },
      );

      final decoded = LibraryBackup.decode(backup.encode());

      expect(decoded, isNotNull);
      expect(decoded!.followed, hasLength(2));
      expect(decoded.history, hasLength(1));
      expect(decoded.history.single.page, 7);
      expect(decoded.readChapters['a'], <String>{'c1', 'c2'});
    });

    test('menolak teks yang bukan backup', () {
      expect(LibraryBackup.decode('bukan json'), isNull);
      expect(LibraryBackup.decode('{"app":"lain"}'), isNull);
      expect(LibraryBackup.decode('[]'), isNull);
    });

    test('entri rusak di dalam backup dilewati', () {
      const raw = '''
{"app":"isekaiku","version":1,
 "followed":[{"id":"ok","title":"Ok","followedAt":"2026-01-01T00:00:00.000"},
             {"tanpa":"id"}],
 "history":[{"mangaId":"m","chapterId":"c","readAt":"2026-01-01T00:00:00.000"}],
 "readChapters":{"m":["c1"]}}
''';
      final decoded = LibraryBackup.decode(raw);

      expect(decoded, isNotNull);
      expect(decoded!.followed, hasLength(1));
      expect(decoded.history, hasLength(1));
      expect(decoded.readChapters['m'], <String>{'c1'});
    });
  });

  group('merge', () {
    test('followed: id sama memakai tanggal terbaru', () {
      final merged = LibraryBackup.mergeFollowed(
        <FollowedManga>[_followed('a', DateTime(2026, 1, 1), title: 'Lama')],
        <FollowedManga>[_followed('a', DateTime(2026, 3, 1), title: 'Baru')],
      );

      expect(merged, hasLength(1));
      expect(merged.single.title, 'Baru');
    });

    test('followed: id berbeda digabung, terbaru di atas', () {
      final merged = LibraryBackup.mergeFollowed(
        <FollowedManga>[_followed('a', DateTime(2026, 1, 1))],
        <FollowedManga>[_followed('b', DateTime(2026, 2, 1))],
      );

      expect(merged.map((e) => e.id).toList(), <String>['b', 'a']);
    });

    test('history: satu entri per manga, readAt terbaru menang', () {
      final merged = LibraryBackup.mergeHistory(
        <ReadingHistoryEntry>[_history('m', 'c1', DateTime(2026, 1, 1))],
        <ReadingHistoryEntry>[_history('m', 'c2', DateTime(2026, 2, 1), page: 9)],
      );

      expect(merged, hasLength(1));
      expect(merged.single.chapterId, 'c2');
      expect(merged.single.page, 9);
    });

    test('history: dibatasi historyLimit', () {
      final incoming = <ReadingHistoryEntry>[
        for (var i = 0; i < LibraryStore.historyLimit + 10; i++)
          _history('m$i', 'c$i', DateTime(2026, 1, 1).add(Duration(minutes: i))),
      ];

      final merged = LibraryBackup.mergeHistory(const [], incoming);

      expect(merged, hasLength(LibraryStore.historyLimit));
    });

    test('readChapters: gabungan tanpa duplikat', () {
      final merged = LibraryBackup.mergeReadChapters(
        <String, Set<String>>{
          'm': <String>{'c1'},
        },
        <String, Set<String>>{
          'm': <String>{'c1', 'c2'},
          'n': <String>{'c9'},
        },
      );

      expect(merged['m'], <String>{'c1', 'c2'});
      expect(merged['n'], <String>{'c9'});
    });
  });

  group('LibraryBackupService.import', () {
    test('menggabungkan dengan data yang sudah ada', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = await StorageService.create();
      final store = LibraryStore(storage);

      await store.saveFollowed(<FollowedManga>[_followed('lama', DateTime(2026, 1, 1))]);
      await store.saveHistory(<ReadingHistoryEntry>[
        _history('lama', 'c1', DateTime(2026, 1, 1)),
      ]);
      await store.saveReadChapters(<String, Set<String>>{
        'lama': <String>{'c1'},
      });

      final incoming = LibraryBackup(
        followed: <FollowedManga>[_followed('baru', DateTime(2026, 5, 1))],
        history: <ReadingHistoryEntry>[
          _history('baru', 'c2', DateTime(2026, 5, 1)),
        ],
        readChapters: <String, Set<String>>{
          'baru': <String>{'c2'},
        },
      );

      final summary =
          await LibraryBackupService(store).import(incoming.encode());

      expect(summary.followed, 2);
      expect(summary.history, 2);
      expect(summary.readChapters, 2);
      expect(store.loadFollowed().map((e) => e.id), containsAll(<String>['lama', 'baru']));
      expect(store.loadReadChapters()['lama'], <String>{'c1'});
      expect(store.loadReadChapters()['baru'], <String>{'c2'});
    });

    test('teks tidak valid melempar FormatException', () async {
      final storage = await StorageService.create();
      final store = LibraryStore(storage);

      expect(
        () => LibraryBackupService(store).import('ngawur'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
