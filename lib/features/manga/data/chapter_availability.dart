import '../../../core/storage/storage_service.dart';
import 'mangadex_api.dart';

/// Mengecek berapa chapter yang benar-benar bisa dibaca untuk satu manga
/// pada satu bahasa, lalu menyimpannya di cache lokal.
///
/// Hasil cache dipakai untuk menyaring judul tanpa chapter dari daftar
/// (Beranda, Pencarian) tanpa memanggil API berulang kali.
///
/// Nilai balik [count]:
/// - `null` → belum diketahui (jaringan gagal) → judul tetap ditampilkan
/// - `0`    → tidak ada chapter yang bisa dibaca
/// - `> 0`  → jumlah chapter
class ChapterAvailability {
  ChapterAvailability(this._api, this._storage);

  final MangaDexApi _api;
  final StorageService _storage;

  /// Umur cache. Ketersediaan chapter jarang berubah, 6 jam cukup.
  static const Duration ttl = Duration(hours: 6);

  /// Cache dipisah per mode konten: mengaktifkan 18+ bisa mengubah hasil.
  String _key(String mangaId, String language, bool adult) =>
      'avail.$language.${adult ? 'adult' : 'std'}.$mangaId';

  Future<int?> count(
    String mangaId,
    String language, {
    bool adult = false,
  }) async {
    final String raw = _storage.getString(_key(mangaId, language, adult));
    if (raw.isNotEmpty) {
      final int sep = raw.indexOf('|');
      if (sep > 0) {
        final int? ts = int.tryParse(raw.substring(0, sep));
        final int? value = int.tryParse(raw.substring(sep + 1));
        if (ts != null && value != null) {
          final int age = DateTime.now().millisecondsSinceEpoch - ts;
          if (age >= 0 && age < ttl.inMilliseconds) return value;
        }
      }
    }

    try {
      final int value = await _api.chapterCount(
        mangaId,
        language: language,
        adult: adult,
      );
      await _storage.setString(
        _key(mangaId, language, adult),
        '${DateTime.now().millisecondsSinceEpoch}|$value',
      );
      return value;
    } catch (_) {
      // Jaringan bermasalah: jangan sembunyikan judul karena hal yang
      // belum tentu benar.
      return null;
    }
  }

  /// Saring [items], buang yang terbukti tidak punya chapter.
  Future<List<T>> filterAvailable<T>(
    List<T> items,
    String Function(T item) idOf,
    String language, {
    bool adult = false,
  }) async {
    if (items.isEmpty) return items;

    final List<MapEntry<T, int?>> checked = await Future.wait(
      items.map(
        (T item) async => MapEntry<T, int?>(
          item,
          await count(idOf(item), language, adult: adult),
        ),
      ),
    );

    return checked
        .where((MapEntry<T, int?> e) => e.value == null || e.value! > 0)
        .map((MapEntry<T, int?> e) => e.key)
        .toList(growable: false);
  }

  /// Buang cache satu judul (mis. setelah pengguna membuka detail).
  Future<void> invalidate(
    String mangaId,
    String language, {
    bool adult = false,
  }) {
    return _storage.remove(_key(mangaId, language, adult));
  }
}
