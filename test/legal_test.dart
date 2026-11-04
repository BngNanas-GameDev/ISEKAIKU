import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/storage/storage_providers.dart';
import 'package:isekaiku/core/storage/storage_service.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/features/account/presentation/birth_date_page.dart';
import 'package:isekaiku/features/legal/legal_content.dart';
import 'package:isekaiku/features/legal/legal_providers.dart';
import 'package:isekaiku/features/legal/presentation/legal_onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('dokumen legal', () {
    test('syarat dan privasi memiliki isi', () {
      expect(LegalContent.version, isNotEmpty);
      expect(LegalContent.terms.sections, isNotEmpty);
      expect(LegalContent.privacy.sections, isNotEmpty);
      expect(LegalContent.contactUrl, startsWith('https://'));
    });

    test('privasi menyebut tanggal lahir disimpan dan tidak bisa diubah', () {
      final text = LegalContent.privacy.sections
          .map((section) => section.body)
          .join(' ')
          .toLowerCase();

      expect(text, contains('tanggal lahir'));
      expect(text, contains('tidak dapat diubah'));
    });
  });

  group('persetujuan legal', () {
    test('bawaan belum disetujui', () async {
      final storage = await StorageService.create();
      final notifier = LegalAcceptanceNotifier(storage);

      expect(notifier.state, isFalse);
    });

    test('accept menyimpan versi terbaru', () async {
      final storage = await StorageService.create();
      final notifier = LegalAcceptanceNotifier(storage);

      notifier.accept();

      expect(notifier.state, isTrue);
      expect(storage.getString(legalAcceptedVersionKey), LegalContent.version);
    });

    test('versi lama dianggap belum disetujui', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legalAcceptedVersionKey: 'versi-lama',
      });

      final storage = await StorageService.create();
      final notifier = LegalAcceptanceNotifier(storage);

      expect(notifier.state, isFalse);
    });
  });

  group('halaman onboarding', () {
    testWidgets('tombol aktif setelah checkbox dicentang', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = await StorageService.create();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: MaterialApp(
            theme: appDarkTheme(),
            home: const LegalOnboardingPage(),
          ),
        ),
      );

      final button = find.widgetWithText(FilledButton, 'Setuju & Lanjut');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

      await tester.tap(button);
      await tester.pump();

      expect(storage.getString(legalAcceptedVersionKey), LegalContent.version);
    });

    testWidgets('formulir tanggal lahir tidak menyebut konten 18+', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BirthDatePage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lengkapi profil'), findsOneWidget);
      expect(find.textContaining('18+'), findsNothing);
      expect(find.textContaining('Erotika'), findsNothing);
      expect(find.textContaining('tidak dapat diubah'), findsOneWidget);
    });
  });
}
