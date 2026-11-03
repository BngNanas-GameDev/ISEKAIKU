import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'data/chapter_availability.dart';
import 'data/mangadex_api.dart';
import 'data/models/manga.dart';

final mangaDexApiProvider = Provider<MangaDexApi>((ref) => MangaDexApi());

/// Pemeriksa + cache ketersediaan chapter per judul.
final chapterAvailabilityProvider = Provider<ChapterAvailability>(
  (ref) => ChapterAvailability(
    ref.watch(mangaDexApiProvider),
    ref.watch(storageServiceProvider),
  ),
);

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
///
/// Judul yang tidak punya chapter pada bahasa terpilih disaring keluar.
final popularMangaProvider =
    FutureProvider.autoDispose<List<Manga>>((ref) async {
  final language = ref.watch(chapterLanguageProvider);
  final list = await ref
      .watch(mangaDexApiProvider)
      .popular(limit: 20, language: language);
  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language);
});

/// Manga terbaru untuk beranda.
final latestMangaProvider =
    FutureProvider.autoDispose<List<Manga>>((ref) async {
  final language = ref.watch(chapterLanguageProvider);
  final list = await ref
      .watch(mangaDexApiProvider)
      .latest(limit: 20, language: language);
  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language);
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
    FutureProvider.autoDispose.family<List<Manga>, String>((ref, query) async {
  if (query.trim().isEmpty) return <Manga>[];
  final language = ref.watch(chapterLanguageProvider);
  final list = await ref.watch(mangaDexApiProvider).search(query.trim());
  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language);
});
