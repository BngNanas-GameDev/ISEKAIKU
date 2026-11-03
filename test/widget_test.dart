import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/theme/app_colors.dart';
import 'package:isekaiku/core/widgets/iseakaiku_wordmark.dart';
import 'package:isekaiku/main.dart';

void main() {
  testWidgets('home menampilkan wordmark dan CTA', (WidgetTester tester) async {
    await tester.pumpWidget(const IsekaikuApp());

    expect(find.byType(IsekaikuWordmark), findsOneWidget);
    expect(find.text('Manga & Anime Portal'), findsOneWidget);
    expect(find.text('Design System Preview'), findsOneWidget);
  });

  testWidgets('theme memakai background palet gelap', (WidgetTester tester) async {
    await tester.pumpWidget(const IsekaikuApp());

    final context = tester.element(find.byType(Scaffold).first);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);

    expect(scaffold.backgroundColor, AppColors.background);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('wordmark menampilkan dua warna brand', (WidgetTester tester) async {
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
}
