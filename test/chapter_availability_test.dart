import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/manga/data/chapter_availability.dart';
import 'package:isekaiku/features/manga/data/mangadex_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API palsu: jumlah chapter diatur per manga.
class _FakeApi extends MangaDexApi {
  _FakeApi(this.counts);

  final Map<String, int> counts;
  int calls = 0;

  @override
  Future<int> chapterCount(String mangaId, {required String language}) async {
    calls++;
    final value = counts[mangaId];
    if (value == null) throw Exception('jaringan gagal');
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('memanggil API saat cache kosong lalu menyimpan hasilnya', () async {
    final storage = await StorageService.create();
    final api = _FakeApi(<String, int>{'a': 12});
    final service = ChapterAvailability(api, storage);

    expect(await service.count('a', 'id'), 12);
    expect(api.calls, 1);

    // Panggilan kedua memakai cache.
    expect(await service.count('a', 'id'), 12);
    expect(api.calls, 1);
  });

  test('cache per bahasa tidak saling menimpa', () async {
    final storage = await StorageService.create();
    final api = _FakeApi(<String, int>{'a': 5});
    final service = ChapterAvailability(api, storage);

    await service.count('a', 'id');
    await service.count('a', 'en');

    expect(api.calls, 2);
    expect(storage.getString('avail.id.a'), isNotEmpty);
    expect(storage.getString('avail.en.a'), isNotEmpty);
  });

  test('cache kedaluwarsa memicu panggilan ulang', () async {
    final storage = await StorageService.create();
    final api = _FakeApi(<String, int>{'a': 3});
    final service = ChapterAvailability(api, storage);

    // Simulasikan entri lama (di luar TTL).
    final old = DateTime.now()
        .subtract(ChapterAvailability.ttl + const Duration(minutes: 5))
        .millisecondsSinceEpoch;
    await storage.setString('avail.id.a', '$old|3');

    expect(await service.count('a', 'id'), 3);
    expect(api.calls, 1, reason: 'cache kedaluwarsa harus diambil ulang');
  });

  test('gagal jaringan mengembalikan null (judul tetap tampil)', () async {
    final storage = await StorageService.create();
    final api = _FakeApi(<String, int>{});
    final service = ChapterAvailability(api, storage);

    expect(await service.count('hilang', 'id'), isNull);
  });

  test('filterAvailable membuang judul tanpa chapter, mempertahankan yang '
      'belum diketahui', () async {
    final storage = await StorageService.create();
    final api = _FakeApi(<String, int>{'ada': 4, 'kosong': 0});
    final service = ChapterAvailability(api, storage);

    final result = await service.filterAvailable(
      <String>['ada', 'kosong', 'tidak-diketahui'],
      (id) => id,
      'id',
    );

    expect(result, <String>['ada', 'tidak-diketahui']);
  });
}
