import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

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
                icon: _AnimatedAssetIcon(
                  frames: <String>['assets/Beranda/b1.png', 'assets/Beranda/b2.png'],
                ),
                selectedIcon: _AnimatedAssetIcon(
                  frames: <String>['assets/Beranda/b1.png', 'assets/Beranda/b2.png'],
                  selected: true,
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: _AnimatedAssetIcon(
                  frames: <String>['assets/Cari/s1.png', 'assets/Cari/s2.png'],
                ),
                selectedIcon: _AnimatedAssetIcon(
                  frames: <String>['assets/Cari/s1.png', 'assets/Cari/s2.png'],
                  selected: true,
                ),
                label: 'Cari',
              ),
              NavigationDestination(
                icon: _AnimatedAssetIcon(
                  frames: <String>['assets/Pustaka/p1.png', 'assets/Pustaka/p2.png'],
                ),
                selectedIcon: _AnimatedAssetIcon(
                  frames: <String>['assets/Pustaka/p1.png', 'assets/Pustaka/p2.png'],
                  selected: true,
                ),
                label: 'Pustaka',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikon navigasi dari aset.
///
/// Tidak beranimasi berulang: frame 2 hanya saat tab aktif, frame 1 saat
/// tidak aktif. Pergantiannya memakai cross-fade singkat.
class _AnimatedAssetIcon extends StatelessWidget {
  const _AnimatedAssetIcon({
    required this.frames,
    this.selected = false,
  });

  final List<String> frames;
  final bool selected;

  static const double _size = 26;

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int cacheSize = (_size * dpr).round();

    // Frame 2 milik tab aktif; frame 1 untuk tab lain.
    final int index = selected && frames.length > 1 ? 1 : 0;

    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Image.asset(
          frames[index],
          key: ValueKey<int>(index),
          width: _size,
          height: _size,
          cacheWidth: cacheSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.circle_outlined,
            size: 22,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
