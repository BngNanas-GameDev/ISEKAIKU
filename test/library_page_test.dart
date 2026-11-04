import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_providers.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/features/library/data/library_store.dart';
import 'package:isekaiku/features/library/data/models/library_models.dart';
import 'package:isekaiku/features/library/library_providers.dart';
import 'package:isekaiku/features/library/presentation/library_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bungkus halaman dengan ProviderScope + storage palsu.
Future<Widget> _app(Widget child) async {
  final StorageService storage = await StorageService.create();
  return ProviderScope(
    overrides: <Override>[storageServiceProvider.overrideWithValue(storage)],
    child: MaterialApp(theme: appDarkTheme(), home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Pustaka kosong menampilkan panduan', (tester) async {
    await tester.pumpWidget(await _app(const LibraryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Diikuti (0)'), findsOneWidget);
    expect(find.text('Riwayat (0)'), findsOneWidget);
    expect(find.text('Belum ada manga diikuti'), findsOneWidget);
    // Tombol hapus riwayat tidak muncul saat kosong.
    expect(find.byIcon(Icons.delete_sweep_outlined), findsNothing);
  });

  testWidgets('Pustaka menampilkan manga diikuti dan riwayat', (tester) async {
    final followed = FollowedManga(
      id: 'manga-1',
      title: 'Manga Diikuti',
      author: 'Penulis',
      followedAt: DateTime(2026, 5, 2),
    );
    final history = ReadingHistoryEntry(
      mangaId: 'manga-2',
      mangaTitle: 'Manga Riwayat',
      chapterId: 'ch-1',
      chapterNumber: '7',
      readAt: DateTime(2026, 5, 3),
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      LibraryStore.followedKeyFor(LibraryStore.guestScope): <String>[
        jsonEncode(followed.toJson()),
      ],
      LibraryStore.historyKeyFor(LibraryStore.guestScope): <String>[
        jsonEncode(history.toJson()),
      ],
    });

    await tester.pumpWidget(await _app(const LibraryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Diikuti (1)'), findsOneWidget);
    expect(find.text('Manga Diikuti'), findsOneWidget);
    expect(find.text('Riwayat (1)'), findsOneWidget);

    // Pindah ke tab riwayat.
    await tester.tap(find.text('Riwayat (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Manga Riwayat'), findsOneWidget);
    expect(find.textContaining('Chapter 7'), findsOneWidget);
  });

  testWidgets('hapus riwayat lewat ikon menghilangkan entri', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LibraryStore.historyKeyFor(LibraryStore.guestScope): <String>[
        jsonEncode(
          ReadingHistoryEntry(
            mangaId: 'manga-2',
            mangaTitle: 'Manga Riwayat',
            chapterId: 'ch-1',
            chapterNumber: '7',
            readAt: DateTime(2026, 5, 3),
          ).toJson(),
        ),
      ],
    });

    await tester.pumpWidget(await _app(const LibraryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat (0)'), findsOneWidget);
    expect(find.text('Belum ada riwayat baca'), findsOneWidget);
  });

  group('FollowedNotifier', () {
    Future<(ProviderContainer, LibraryStore)> build() async {
      final storage = await StorageService.create();
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      return (container, LibraryStore(storage));
    }

    test('toggle menambah lalu menghapus dan tersimpan', () async {
      final (container, store) = await build();
      addTearDown(container.dispose);

      final manga = FollowedManga(
        id: 'x',
        title: 'X',
        followedAt: DateTime(2026, 6, 1),
      );

      container.read(followedMangaProvider.notifier).toggle(manga);
      expect(container.read(isFollowingProvider('x')), isTrue);
      expect(store.loadFollowed().single.id, 'x');

      container.read(followedMangaProvider.notifier).toggle(manga);
      expect(container.read(isFollowingProvider('x')), isFalse);
      expect(store.loadFollowed(), isEmpty);
    });

    test('toggle kedua manga menyimpan keduanya, terbaru dulu', () async {
      final (container, _) = await build();
      addTearDown(container.dispose);

      final notifier = container.read(followedMangaProvider.notifier);
      notifier.toggle(
        FollowedManga(id: 'a', title: 'A', followedAt: DateTime(2026, 1, 1)),
      );
      notifier.toggle(
        FollowedManga(id: 'b', title: 'B', followedAt: DateTime(2026, 2, 1)),
      );

      expect(
        container.read(followedMangaProvider).map((e) => e.id).toList(),
        <String>['b', 'a'],
      );
    });
  });

  group('HistoryNotifier', () {
    test('record mengganti entri lama manga yang sama', () async {
      final storage = await StorageService.create();
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(readingHistoryProvider.notifier);
      notifier.record(
        ReadingHistoryEntry(
          mangaId: 'a',
          mangaTitle: 'A',
          chapterId: 'c1',
          chapterNumber: '1',
          readAt: DateTime(2026, 1, 1),
        ),
      );
      notifier.record(
        ReadingHistoryEntry(
          mangaId: 'a',
          mangaTitle: 'A',
          chapterId: 'c2',
          chapterNumber: '2',
          readAt: DateTime(2026, 1, 2),
        ),
      );

      final entries = container.read(readingHistoryProvider);
      expect(entries, hasLength(1));
      expect(entries.single.chapterId, 'c2');
      expect(container.read(historyEntryProvider('a'))?.chapterNumber, '2');
    });
  });
}
