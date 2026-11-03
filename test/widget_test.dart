import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/theme/app_colors.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/core/widgets/iseakaiku_wordmark.dart';

void main() {
  testWidgets('theme memakai background palet gelap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme(),
        home: const Scaffold(body: SizedBox()),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.background);
    expect(Theme.of(context).colorScheme.primary, AppColors.primary);
  });

  testWidgets('wordmark menampilkan dua warna brand', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: IsekaikuWordmark(size: 32))),
      ),
    );

    expect(find.text('ISEKAIKU'), findsOneWidget);

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(IsekaikuWordmark),
        matching: find.byType(RichText),
      ),
    );

    final spans = <TextSpan>[];
    void collect(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text != null) spans.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          collect(child);
        }
      }
    }

    collect(richText.text);

    final isekai = spans.firstWhere((s) => s.text == 'ISEKAI');
    final ku = spans.firstWhere((s) => s.text == 'KU');

    expect(isekai.style!.color, AppColors.onSurface);
    expect(ku.style!.color, AppColors.primary);
  });

  testWidgets('wordmark muat di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: IsekaikuWordmark(size: 64))),
      ),
    );

    // Tidak boleh ada overflow; FittedBox mengecilkan wordmark.
    expect(tester.takeException(), isNull);
  });
}
