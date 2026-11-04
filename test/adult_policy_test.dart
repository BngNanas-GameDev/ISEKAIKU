import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/features/manga/data/adult_policy.dart';
import 'package:isekaiku/features/manga/manga_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('usia minimum', () {
    test('konten 18+, aplikasi 13+', () {
      expect(AdultPolicy.minimumAge, 18);
      expect(AdultPolicy.appMinimumAge, 13);
    });

    test('hari ulang tahun ke-18 dihitung sudah dewasa', () {
      final now = DateTime(2026, 11, 4);
      final birth = DateTime(2008, 11, 4);

      expect(AdultPolicy.ageOn(birth, now: now), 18);
      expect(AdultPolicy.isAdult(birth, now: now), isTrue);
    });

    test('sehari sebelum ulang tahun ke-18 masih di bawah umur', () {
      final now = DateTime(2026, 11, 4);
      final birth = DateTime(2008, 11, 5);

      expect(AdultPolicy.ageOn(birth, now: now), 17);
      expect(AdultPolicy.isAdult(birth, now: now), isFalse);
    });

    test('lahir 29 Februari mengikuti tanggal normal', () {
      final birth = DateTime(2008, 2, 29);

      expect(AdultPolicy.isAdult(birth, now: DateTime(2026, 2, 28)), isFalse);
      expect(AdultPolicy.isAdult(birth, now: DateTime(2026, 3, 1)), isTrue);
    });

    test('di bawah 13 tahun tidak boleh memakai aplikasi', () {
      final now = DateTime(2026, 11, 4);

      expect(AdultPolicy.canUseApp(DateTime(2015, 1, 1), now: now), isFalse);
      expect(AdultPolicy.canUseApp(DateTime(2013, 11, 4), now: now), isTrue);
    });

    test('tanggal lahir di masa depan tidak lolos', () {
      final birth = DateTime(2027, 1, 1);
      expect(AdultPolicy.isAdult(birth, now: DateTime(2026, 11, 4)), isFalse);
    });
  });

  group('validasi tanggal lahir', () {
    final now = DateTime(2026, 11, 4);

    test('tanggal nyata diterima', () {
      expect(AdultPolicy.birthDate(4, 11, 2000, now: now), isNotNull);
    });

    test('31 Februari ditolak', () {
      expect(AdultPolicy.birthDate(31, 2, 2000, now: now), isNull);
    });

    test('bulan dan tahun tidak wajar ditolak', () {
      expect(AdultPolicy.birthDate(1, 13, 2000, now: now), isNull);
      expect(AdultPolicy.birthDate(1, 1, 1800, now: now), isNull);
      expect(AdultPolicy.birthDate(1, 1, 2027, now: now), isNull);
    });
  });

  group('status konten 18+ tersimpan', () {
    test('bawaan mati', () async {
      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      expect(notifier.state, isFalse);
    });

    test('enable dan disable tersimpan', () async {
      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      notifier.enable();
      expect(notifier.state, isTrue);
      expect(storage.getBool(catalogAdultKey), isTrue);

      notifier.disable();
      expect(notifier.state, isFalse);
      expect(storage.getBool(catalogAdultKey), isFalse);
    });

    test('tidak ada masa berlaku: flag tetap aktif setelah 31 hari', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        catalogAdultKey: true,
      });

      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      expect(notifier.state, isTrue);
    });

    test('kunci lama cap waktu dibersihkan', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'catalog.adultSince': '2026-11-04T00:00:00Z',
      });

      final storage = await StorageService.create();
      AdultContentNotifier(storage);

      expect(storage.getString('catalog.adultSince'), isEmpty);
    });
  });
}
