import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/models/manga.dart';
import '../manga_providers.dart';
import 'widgets/manga_card.dart';

/// Reader manga: mode paged (geser horizontal) atau webtoon (scroll vertikal).
class ReaderPage extends ConsumerStatefulWidget {
  final String mangaId;
  final String chapterId;
  final String chapterTitle;
  final String chapterNumber;

  const ReaderPage({
    super.key,
    required this.mangaId,
    required this.chapterId,
    this.chapterTitle = '',
    this.chapterNumber = '',
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _chromeVisible = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(chapterPagesProvider(widget.chapterId));
    final saver = ref.watch(dataSaverProvider);
    final webtoon = ref.watch(webtoonModeProvider);

    return Scaffold(
      backgroundColor: AppColors.readerBg,
      body: switch (pagesAsync) {
        AsyncData(:final value) => _buildReader(value, saver, webtoon),
        AsyncError(:final error) => SafeArea(
            child: Stack(
              children: <Widget>[
                ErrorRetry(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(chapterPagesProvider(widget.chapterId)),
                ),
                Positioned(
                  top: AppSpacing.s,
                  left: AppSpacing.s,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
        _ => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
      },
    );
  }

  Widget _buildReader(ChapterPages pages, bool saver, bool webtoon) {
    final urls = pages.urls(saver: saver);

    if (urls.isEmpty) {
      return const Center(
        child: Text('Chapter tidak memiliki halaman.', style: AppTypography.bodySmall),
      );
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            child: webtoon
                ? ListView.builder(
                    itemCount: urls.length,
                    itemBuilder: (context, index) => _ReaderImage(
                      url: urls[index],
                      fit: BoxFit.fitWidth,
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: urls.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _prefetch(urls, index);
                    },
                    itemBuilder: (context, index) => InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: _ReaderImage(
                        url: urls[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        ),
        if (_chromeVisible) ...<Widget>[
          _TopBar(
            title: _chapterLabel,
            onBack: () => context.pop(),
            onSettings: _showSettings,
          ),
          if (!webtoon)
            _PageIndicator(
              current: _currentPage + 1,
              total: urls.length,
            ),
        ],
      ],
    );
  }

  String get _chapterLabel {
    if (widget.chapterTitle.isNotEmpty) return widget.chapterTitle;
    if (widget.chapterNumber.isNotEmpty) return 'Chapter ${widget.chapterNumber}';
    return 'Reader';
  }

  /// Prefetch 2 halaman berikutnya agar geser terasa mulus.
  void _prefetch(List<String> urls, int index) {
    for (var i = index + 1; i <= index + 2 && i < urls.length; i++) {
      precacheImage(CachedNetworkImageProvider(urls[i]), context);
    }
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final webtoon = ref.watch(webtoonModeProvider);
          final saver = ref.watch(dataSaverProvider);
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pengaturan reader', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.l),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mode webtoon', style: AppTypography.bodyMedium),
                  subtitle: const Text(
                    'Scroll vertikal, cocok untuk chapter panjang',
                    style: AppTypography.labelSmall,
                  ),
                  value: webtoon,
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      ref.read(webtoonModeProvider.notifier).state = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hemat kuota', style: AppTypography.bodyMedium),
                  subtitle: const Text(
                    'Pakai gambar kualitas data-saver',
                    style: AppTypography.labelSmall,
                  ),
                  value: saver,
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      ref.read(dataSaverProvider.notifier).state = value,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReaderImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _ReaderImage({required this.url, required this.fit});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xF2000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _PageIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.xxl,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(150),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            '$current / $total',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
