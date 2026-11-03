import 'package:flutter/material.dart';
import 'package:isekaiku/core/licensing.dart';
import 'package:isekaiku/core/theme/app_colors.dart';
import 'package:isekaiku/core/theme/app_theme.dart';
import 'package:isekaiku/core/theme/app_typography.dart';
import 'package:isekaiku/core/widgets/iseakaiku_wordmark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAppLicenses();
  runApp(const IsekaikuApp());
}

class IsekaikuApp extends StatelessWidget {
  const IsekaikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dev route: buka `?dev=design` di web untuk review token tanpa navigasi.
    final isDesignPreview = Uri.base.queryParameters['dev'] == 'design';

    return MaterialApp(
      title: 'Isekaiku',
      debugShowCheckedModeBanner: false,
      theme: appDarkTheme(),
      darkTheme: appDarkTheme(),
      themeMode: ThemeMode.dark,
      home: isDesignPreview
          ? const IsekaikuDesignSystemPreview()
          : const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const IsekaikuWordmark(size: 64),
            ),
            const SizedBox(height: 24),            const Text(
              'Manga & Anime Portal',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Dark theme — Asimov font — Riverpod',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IsekaikuDesignSystemPreview(),
                  ),
                );
              },
              child: const Text('Design System Preview'),
            ),
          ],
        ),
      ),
    );
  }
}
