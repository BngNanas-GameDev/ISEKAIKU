import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Kerangka dengan bottom navigation untuk tab utama.
class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  static const List<String> _locations = <String>['/', '/search', '/library'];

  int _indexFor(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _locations.indexWhere(
      (path) => path == '/' ? location == '/' : location.startsWith(path),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            backgroundColor: AppColors.surfaceContainerLow,
            indicatorColor: AppColors.primary.withAlpha(48),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: index,
            onDestinationSelected: (value) => context.go(_locations[value]),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: AppColors.primary),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: AppColors.primary),
                label: 'Cari',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark, color: AppColors.primary),
                label: 'Pustaka',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder pustaka (M2: follow lokal + riwayat).
class LibraryPlaceholderPage extends StatelessWidget {
  const LibraryPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Pustaka', style: AppTypography.titleLarge),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pustaka dan riwayat baca tersedia di M2.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
