import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'data/library_store.dart';
import 'data/models/library_models.dart';

final libraryStoreProvider = Provider<LibraryStore>(
  (ref) => LibraryStore(ref.watch(storageServiceProvider)),
);

/// Daftar manga yang diikuti, urut dari yang terbaru.
class FollowedNotifier extends StateNotifier<List<FollowedManga>> {
  FollowedNotifier(this._store) : super(_store.loadFollowed());

  final LibraryStore _store;

  bool isFollowing(String mangaId) => state.any((e) => e.id == mangaId);

  /// Tambah kalau belum ada, hapus kalau sudah ada.
  void toggle(FollowedManga manga) {
    if (isFollowing(manga.id)) {
      remove(manga.id);
      return;
    }
    state = <FollowedManga>[manga, ...state];
    _store.saveFollowed(state);
  }

  void remove(String mangaId) {
    state = state.where((e) => e.id != mangaId).toList();
    _store.saveFollowed(state);
  }
}

final followedMangaProvider =
    StateNotifierProvider<FollowedNotifier, List<FollowedManga>>(
  (ref) => FollowedNotifier(ref.watch(libraryStoreProvider)),
);

/// Apakah manga ini sudah diikuti.
final isFollowingProvider = Provider.family<bool, String>((ref, mangaId) {
  return ref
      .watch(followedMangaProvider)
      .any((entry) => entry.id == mangaId);
});

/// Riwayat baca, satu entri per manga (chapter terakhir).
class HistoryNotifier extends StateNotifier<List<ReadingHistoryEntry>> {
  HistoryNotifier(this._store) : super(_store.loadHistory());

  final LibraryStore _store;

  /// Catat/segarkan riwayat sebuah manga.
  void record(ReadingHistoryEntry entry) {
    final next = <ReadingHistoryEntry>[
      entry,
      ...state.where((e) => e.mangaId != entry.mangaId),
    ];
    state = next.length > LibraryStore.historyLimit
        ? next.sublist(0, LibraryStore.historyLimit)
        : next;
    _store.saveHistory(state);
  }

  void remove(String mangaId) {
    state = state.where((e) => e.mangaId != mangaId).toList();
    _store.saveHistory(state);
  }

  void clear() {
    state = const <ReadingHistoryEntry>[];
    _store.saveHistory(state);
  }

  /// Chapter terakhir yang dibaca untuk manga ini, kalau ada.
  ReadingHistoryEntry? entryFor(String mangaId) {
    for (final entry in state) {
      if (entry.mangaId == mangaId) return entry;
    }
    return null;
  }
}

final readingHistoryProvider =
    StateNotifierProvider<HistoryNotifier, List<ReadingHistoryEntry>>(
  (ref) => HistoryNotifier(ref.watch(libraryStoreProvider)),
);

/// Riwayat untuk satu manga (dipakai untuk menandai progres terakhir).
final historyEntryProvider =
    Provider.family<ReadingHistoryEntry?, String>((ref, mangaId) {
  final entries = ref.watch(readingHistoryProvider);
  for (final entry in entries) {
    if (entry.mangaId == mangaId) return entry;
  }
  return null;
});
