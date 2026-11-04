import 'dart:async';

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
                  animate: true,
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: _AnimatedAssetIcon(
                  frames: <String>['assets/Cari/s1.png', 'assets/Cari/s2.png'],
                ),
                selectedIcon: _AnimatedAssetIcon(
                  frames: <String>['assets/Cari/s1.png', 'assets/Cari/s2.png'],
                  animate: true,
                ),
                label: 'Cari',
              ),
              NavigationDestination(
                icon: _AnimatedAssetIcon(
                  frames: <String>['assets/Pustaka/p1.png', 'assets/Pustaka/p2.png'],
                ),
                selectedIcon: _AnimatedAssetIcon(
                  frames: <String>['assets/Pustaka/p1.png', 'assets/Pustaka/p2.png'],
                  animate: true,
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

/// Ikon navigasi dari aset, beranimasi bergantian saat tab aktif.
///
/// Saat tidak aktif, hanya frame pertama yang ditampilkan agar hemat.
class _AnimatedAssetIcon extends StatefulWidget {
  const _AnimatedAssetIcon({
    required this.frames,
    this.animate = false,
  });

  final List<String> frames;
  final bool animate;

  @override
  State<_AnimatedAssetIcon> createState() => _AnimatedAssetIconState();
}

class _AnimatedAssetIconState extends State<_AnimatedAssetIcon> {
  Timer? _timer;
  int _frame = 0;

  static const double _size = 26;
  static const Duration _interval = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedAssetIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.frames.length != widget.frames.length) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    _timer?.cancel();
    _frame = 0;
    if (!widget.animate || widget.frames.length < 2) return;

    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % widget.frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int cacheSize = (_size * dpr).round();

    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: Image.asset(
          widget.frames[_frame.clamp(0, widget.frames.length - 1)],
          key: ValueKey<int>(_frame),
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
