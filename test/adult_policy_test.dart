import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/features/manga/data/adult_policy.dart';
import 'package:isekaiku/features/manga/manga_providers.dart';
import 'package:isekaiku/features/manga/presentation/widgets/adult_age_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('usia minimum', () {
    test('ambang kebijakan adalah 18 tahun', () {
      expect(AdultPolicy.minimumAge, 18);
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

    test('enable menyimpan status dan waktu verifikasi', () async {
      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      notifier.enable();

      expect(notifier.state, isTrue);
      expect(storage.getBool(catalogAdultKey), isTrue);
      expect(storage.getString(catalogAdultSinceKey), isNotEmpty);
    });

    test('disable menghapus status dan waktu verifikasi', () async {
      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      notifier.enable();
      notifier.disable();

      expect(notifier.state, isFalse);
      expect(storage.getBool(catalogAdultKey), isFalse);
      expect(storage.getString(catalogAdultSinceKey), isEmpty);
    });

    test('verifikasi lebih dari 30 hari otomatis mati', () async {
      final old = DateTime.now()
          .subtract(adultVerificationTtl + const Duration(days: 1))
          .toUtc()
          .toIso8601String();
      SharedPreferences.setMockInitialValues(<String, Object>{
        catalogAdultKey: true,
        catalogAdultSinceKey: old,
      });

      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      expect(notifier.state, isFalse);
      expect(storage.getBool(catalogAdultKey), isFalse);
    });

    test('verifikasi dalam 30 hari tetap aktif', () async {
      final recent = DateTime.now()
          .subtract(const Duration(days: 10))
          .toUtc()
          .toIso8601String();
      SharedPreferences.setMockInitialValues(<String, Object>{
        catalogAdultKey: true,
        catalogAdultSinceKey: recent,
      });

      final storage = await StorageService.create();
      final notifier = AdultContentNotifier(storage);

      expect(notifier.state, isTrue);
    });
  });

  group('gerbang usia', () {
    Future<void> openGate(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAdultAgeGate(context),
                child: const Text('buka gerbang'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka gerbang'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '1');
    }

    testWidgets('menolak usia di bawah 18', (tester) async {
      await openGate(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(2), '2015');
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(find.textContaining('belum 18'), findsOneWidget);
      // Dialog masih terbuka, belum ada hasil.
      expect(find.text('Verifikasi'), findsOneWidget);
    });

    testWidgets('menolak tanggal tidak valid', (tester) async {
      await openGate(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '31');
      await tester.enterText(fields.at(1), '2');
      await tester.enterText(fields.at(2), '2000');
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Tanggal lahir tidak valid.'), findsOneWidget);
    });

    testWidgets('menerima usia 18+ dan menutup dialog', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showAdultAgeGate(context);
                },
                child: const Text('buka gerbang'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka gerbang'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '1');
      await tester.enterText(fields.at(2), '2000');
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Verifikasi'), findsNothing);
    });
  });
}
