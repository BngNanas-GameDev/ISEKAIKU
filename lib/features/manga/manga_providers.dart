import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'data/chapter_availability.dart';
import 'data/mangadex_api.dart';
import 'data/models/manga.dart';
import 'data/models/manga_tag.dart';

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
final dataSaverProvider = StateNotifierProvider<PersistentBoolNotifier, bool>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return PersistentBoolNotifier(
    storage,
    readerDataSaverKey,
    storage.getBool(readerDataSaverKey, fallback: true),
  );
});

/// Tampilkan judul dengan rating erotika/dewasa (18+).
///
/// Nonaktif secara bawaan: MangaDex menyembunyikan judul rating `erotica`
/// dan `pornographic` dari daftar, sehingga judul seperti itu tidak muncul
/// di pencarian sampai opsi ini dinyalakan.
const String catalogAdultKey = 'catalog.showAdult';

final showAdultContentProvider =
    StateNotifierProvider<PersistentBoolNotifier, bool>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return PersistentBoolNotifier(
        storage,
        catalogAdultKey,
        storage.getBool(catalogAdultKey, fallback: false),
      );
    });

/// Mode reader: true = webtoon (scroll vertikal), false = paged.
final webtoonModeProvider = StateNotifierProvider<PersistentBoolNotifier, bool>(
  (ref) {
    final storage = ref.watch(storageServiceProvider);
    return PersistentBoolNotifier(
      storage,
      readerWebtoonKey,
      storage.getBool(readerWebtoonKey, fallback: false),
    );
  },
);

/// Manga populer untuk beranda.
///
/// Judul yang tidak punya chapter pada bahasa terpilih disaring keluar.
final popularMangaProvider = FutureProvider.autoDispose<List<Manga>>((
  ref,
) async {
  final language = ref.watch(chapterLanguageProvider);
  final adult = ref.watch(showAdultContentProvider);
  final list = await ref
      .watch(mangaDexApiProvider)
      .popular(limit: 20, language: language, adult: adult);
  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language, adult: adult);
});

/// Manga terbaru untuk beranda.
final latestMangaProvider = FutureProvider.autoDispose<List<Manga>>((
  ref,
) async {
  final language = ref.watch(chapterLanguageProvider);
  final adult = ref.watch(showAdultContentProvider);
  final list = await ref
      .watch(mangaDexApiProvider)
      .latest(limit: 20, language: language, adult: adult);
  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language, adult: adult);
});

final mangaDetailProvider = FutureProvider.autoDispose.family<Manga, String>((
  ref,
  id,
) {
  return ref.watch(mangaDexApiProvider).byId(id);
});

final chapterListProvider = FutureProvider.autoDispose
    .family<List<Chapter>, String>((ref, mangaId) {
      final language = ref.watch(chapterLanguageProvider);
      final adult = ref.watch(showAdultContentProvider);
      return ref
          .watch(mangaDexApiProvider)
          .chapters(mangaId, language: language, adult: adult);
    });

final chapterPagesProvider = FutureProvider.autoDispose
    .family<ChapterPages, String>((ref, chapterId) {
      return ref.watch(mangaDexApiProvider).pages(chapterId);
    });

/// Hasil pencarian berdasarkan kata kunci.
///
/// Pencarian **tidak** menyaring judul tanpa chapter: kalau pengguna mencari
/// judul tertentu, hasilnya harus tetap muncul. Halaman detail yang akan
/// menjelaskan bila chapter pada bahasa aktif belum tersedia.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Manga>, String>((ref, query) async {
      if (query.trim().isEmpty) return <Manga>[];
      final adult = ref.watch(showAdultContentProvider);
      return ref.watch(mangaDexApiProvider).search(query.trim(), adult: adult);
    });

// ---------------------------------------------------------------------------
// Jelajah (genre + filter)
// ---------------------------------------------------------------------------

/// Daftar tag (genre) untuk filter. Diambil sekali per sesi.
final mangaTagsProvider = FutureProvider.autoDispose<List<MangaTag>>((ref) {
  return ref.watch(mangaDexApiProvider).tags();
});

enum BrowseOrder { popular, latest, rating }

/// Kriteria jelajah yang sedang aktif.
class BrowseFilter {
  const BrowseFilter({
    this.tagIds = const <String>{},
    this.status,
    this.year,
    this.order = BrowseOrder.popular,
  });

  final Set<String> tagIds;
  final String? status;
  final int? year;
  final BrowseOrder order;

  bool get isEmpty => tagIds.isEmpty && status == null && year == null;

  BrowseFilter copyWith({
    Set<String>? tagIds,
    String? status,
    bool clearStatus = false,
    int? year,
    bool clearYear = false,
    BrowseOrder? order,
  }) {
    return BrowseFilter(
      tagIds: tagIds ?? this.tagIds,
      status: clearStatus ? null : (status ?? this.status),
      year: clearYear ? null : (year ?? this.year),
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BrowseFilter &&
        other.status == status &&
        other.year == year &&
        other.order == order &&
        other.tagIds.length == tagIds.length &&
        other.tagIds.containsAll(tagIds);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(tagIds), status, year, order);
}

class BrowseFilterNotifier extends StateNotifier<BrowseFilter> {
  BrowseFilterNotifier() : super(const BrowseFilter());

  void toggleTag(String tagId) {
    final next = <String>{...state.tagIds};
    if (!next.remove(tagId)) next.add(tagId);
    state = state.copyWith(tagIds: next);
  }

  void setStatus(String? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: status);
  }

  void setYear(int? year) {
    state = year == null
        ? state.copyWith(clearYear: true)
        : state.copyWith(year: year);
  }

  void setOrder(BrowseOrder order) => state = state.copyWith(order: order);

  void reset() => state = const BrowseFilter();
}

final browseFilterProvider =
    StateNotifierProvider<BrowseFilterNotifier, BrowseFilter>(
      (ref) => BrowseFilterNotifier(),
    );

/// Hasil jelajah sesuai filter aktif.
final browseResultsProvider = FutureProvider.autoDispose<List<Manga>>((
  ref,
) async {
  final filter = ref.watch(browseFilterProvider);
  final language = ref.watch(chapterLanguageProvider);
  final adult = ref.watch(showAdultContentProvider);

  final order = switch (filter.order) {
    BrowseOrder.popular => 'followedCount',
    BrowseOrder.latest => 'latestUploadedChapter',
    BrowseOrder.rating => 'rating',
  };

  final list = await ref
      .watch(mangaDexApiProvider)
      .browse(
        language: language,
        tagIds: filter.tagIds.toList(),
        status: filter.status,
        year: filter.year,
        order: order,
        limit: 24,
        adult: adult,
      );

  return ref
      .watch(chapterAvailabilityProvider)
      .filterAvailable(list, (manga) => manga.id, language, adult: adult);
});
