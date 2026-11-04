import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/storage/storage_service.dart';
import 'data/library_backup.dart';
import 'data/library_store.dart';
import 'data/models/library_models.dart';

final libraryStoreProvider = Provider<LibraryStore>(
  (ref) => LibraryStore(ref.watch(storageServiceProvider)),
);

final libraryBackupServiceProvider = Provider<LibraryBackupService>(
  (ref) => LibraryBackupService(ref.watch(libraryStoreProvider)),
);

/// Urutan tampilan tab Diikuti.
enum LibrarySort { newest, titleAz }

const String librarySortKey = 'library.sort';

class LibrarySortNotifier extends StateNotifier<LibrarySort> {
  LibrarySortNotifier(this._storage, LibrarySort initial) : super(initial);

  final StorageService _storage;

  void set(LibrarySort value) {
    if (value == state) return;
    state = value;
    _storage.setString(
      librarySortKey,
      value == LibrarySort.titleAz ? 'title' : 'newest',
    );
  }
}

final librarySortProvider =
    StateNotifierProvider<LibrarySortNotifier, LibrarySort>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final raw = storage.getString(librarySortKey, fallback: 'newest');
  return LibrarySortNotifier(
    storage,
    raw == 'title' ? LibrarySort.titleAz : LibrarySort.newest,
  );
});

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
    // Tombstone: supaya sync berikutnya tidak memunculkannya lagi.
    _store.recordDeletedFollowed(mangaId);
  }

  /// Muat ulang dari penyimpanan (dipakai setelah impor backup).
  void reload() {
    state = _store.loadFollowed();
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
    _store.recordDeletedHistory(mangaId);
  }

  void clear() {
    final ids = state.map((e) => e.mangaId).toSet();
    state = const <ReadingHistoryEntry>[];
    _store.saveHistory(state);
    for (final id in ids) {
      _store.recordDeletedHistory(id);
    }
  }

  /// Chapter terakhir yang dibaca untuk manga ini, kalau ada.
  ReadingHistoryEntry? entryFor(String mangaId) {
    for (final entry in state) {
      if (entry.mangaId == mangaId) return entry;
    }
    return null;
  }

  /// Muat ulang dari penyimpanan (dipakai setelah impor backup).
  void reload() {
    state = _store.loadHistory();
  }
}

final readingHistoryProvider =
    StateNotifierProvider<HistoryNotifier, List<ReadingHistoryEntry>>(
  (ref) => HistoryNotifier(ref.watch(libraryStoreProvider)),
);

/// Chapter yang sudah pernah dibuka, per manga.
class ReadChaptersNotifier extends StateNotifier<Map<String, Set<String>>> {
  ReadChaptersNotifier(this._store) : super(_store.loadReadChapters());

  final LibraryStore _store;

  void markRead(String mangaId, String chapterId) {
    final current = state[mangaId] ?? const <String>{};
    if (current.contains(chapterId)) return;
    _commit(<String, Set<String>>{
      ...state,
      mangaId: <String>{...current, chapterId},
    });
  }

  void unmarkRead(String mangaId, String chapterId) {
    final current = state[mangaId];
    if (current == null || !current.contains(chapterId)) return;
    _commit(<String, Set<String>>{
      ...state,
      mangaId: <String>{...current}..remove(chapterId),
    });
  }

  void markAllRead(String mangaId, Iterable<String> chapterIds) {
    final current = state[mangaId] ?? const <String>{};
    _commit(<String, Set<String>>{
      ...state,
      mangaId: <String>{...current, ...chapterIds},
    });
  }

  void clearManga(String mangaId) {
    if (!state.containsKey(mangaId)) return;
    final next = Map<String, Set<String>>.of(state)..remove(mangaId);
    _commit(next);
  }

  /// Muat ulang dari penyimpanan (dipakai setelah impor backup).
  void reload() {
    state = _store.loadReadChapters();
  }

  void _commit(Map<String, Set<String>> next) {
    state = next;
    _store.saveReadChapters(next);
  }
}

final readChaptersProvider =
    StateNotifierProvider<ReadChaptersNotifier, Map<String, Set<String>>>(
  (ref) => ReadChaptersNotifier(ref.watch(libraryStoreProvider)),
);

/// Chapter yang sudah dibaca untuk satu manga.
final readChapterIdsProvider =
    Provider.family<Set<String>, String>((ref, mangaId) {
  return ref.watch(readChaptersProvider)[mangaId] ?? const <String>{};
});

/// Apakah satu chapter sudah pernah dibuka.
final isChapterReadProvider =
    Provider.family<bool, (String, String)>((ref, key) {
  final (mangaId, chapterId) = key;
  return ref.watch(readChapterIdsProvider(mangaId)).contains(chapterId);
});

/// Entri riwayat paling baru — dipakai kartu "Lanjut baca".
final continueReadingProvider = Provider<ReadingHistoryEntry?>((ref) {
  final entries = ref.watch(readingHistoryProvider);
  return entries.isEmpty ? null : entries.first;
});

/// Riwayat untuk satu manga (dipakai untuk menandai progres terakhir).
final historyEntryProvider =
    Provider.family<ReadingHistoryEntry?, String>((ref, mangaId) {
  final entries = ref.watch(readingHistoryProvider);
  for (final entry in entries) {
    if (entry.mangaId == mangaId) return entry;
  }
  return null;
});
