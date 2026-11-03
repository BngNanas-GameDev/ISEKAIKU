import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'data/mangadex_api.dart';
import 'data/models/manga.dart';

final mangaDexApiProvider = Provider<MangaDexApi>((ref) => MangaDexApi());

/// Kunci penyimpanan setting reader.
const String readerLanguageKey = 'reader.chapterLanguage';
const String readerDataSaverKey = 'reader.dataSaver';
const String readerWebtoonKey = 'reader.webtoon';

/// Bahasa chapter yang diminta (id, lalu fallback en).
///
/// Persisten: pilihan terakhir dipakai lagi saat aplikasi dibuka ulang.
final chapterLanguageProvider =
    StateNotifierProvider<PersistentStringNotifier, String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PersistentStringNotifier(
    storage,
    readerLanguageKey,
    storage.getString(readerLanguageKey, fallback: 'id'),
  );
});

/// Kualitas gambar reader: true = data-saver (hemat kuota).
final dataSaverProvider =
    StateNotifierProvider<PersistentBoolNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PersistentBoolNotifier(
    storage,
    readerDataSaverKey,
    storage.getBool(readerDataSaverKey, fallback: true),
  );
});

/// Mode reader: true = webtoon (scroll vertikal), false = paged.
final webtoonModeProvider =
    StateNotifierProvider<PersistentBoolNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PersistentBoolNotifier(
    storage,
    readerWebtoonKey,
    storage.getBool(readerWebtoonKey, fallback: false),
  );
});

/// Manga populer untuk beranda.
final popularMangaProvider = FutureProvider.autoDispose<List<Manga>>((ref) {
  return ref.watch(mangaDexApiProvider).popular(limit: 20);
});

/// Manga terbaru untuk beranda.
final latestMangaProvider = FutureProvider.autoDispose<List<Manga>>((ref) {
  return ref.watch(mangaDexApiProvider).latest(limit: 20);
});

final mangaDetailProvider =
    FutureProvider.autoDispose.family<Manga, String>((ref, id) {
  return ref.watch(mangaDexApiProvider).byId(id);
});

final chapterListProvider =
    FutureProvider.autoDispose.family<List<Chapter>, String>((ref, mangaId) {
  final language = ref.watch(chapterLanguageProvider);
  return ref.watch(mangaDexApiProvider).chapters(mangaId, language: language);
});

final chapterPagesProvider =
    FutureProvider.autoDispose.family<ChapterPages, String>((ref, chapterId) {
  return ref.watch(mangaDexApiProvider).pages(chapterId);
});

/// Hasil pencarian berdasarkan kata kunci.
final searchResultsProvider =
    FutureProvider.autoDispose.family<List<Manga>, String>((ref, query) {
  if (query.trim().isEmpty) return <Manga>[];
  return ref.watch(mangaDexApiProvider).search(query.trim());
});
