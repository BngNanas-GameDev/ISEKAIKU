import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../library/data/models/library_models.dart';
import '../../library/library_providers.dart';
import '../data/models/manga.dart';
import '../manga_providers.dart';
import 'widgets/manga_card.dart';

/// Reader manga: mode paged (geser horizontal) atau webtoon (scroll vertikal).
class ReaderPage extends ConsumerStatefulWidget {
  final String mangaId;
  final String chapterId;
  final String chapterTitle;
  final String chapterNumber;

  /// Halaman awal (1-based) saat melanjutkan bacaan.
  final int initialPage;

  const ReaderPage({
    super.key,
    required this.mangaId,
    required this.chapterId,
    this.chapterTitle = '',
    this.chapterNumber = '',
    this.initialPage = 0,
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PageController _pageController;
  late int _currentPage;
  bool _chromeVisible = true;

  int _totalPages = 0;
  bool _firstSaveDone = false;
  bool _endHintShown = false;
  double _overscroll = 0;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage > 0 ? widget.initialPage - 1 : 0;
    _pageController = PageController(initialPage: _currentPage);

    // Modifikasi provider TIDAK boleh dilakukan saat initState (widget tree
    // sedang dibangun), jadi ditunda sampai frame pertama selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(readChaptersProvider.notifier)
          .markRead(widget.mangaId, widget.chapterId);
      _saveProgress(
        page: widget.initialPage > 0 ? widget.initialPage : 1,
        total: _totalPages,
      );
    });
  }

  /// Simpan chapter + posisi halaman sebagai progres terakhir manga ini.
  ///
  /// Ditulis **langsung** memakai detail yang sudah ada di cache, supaya
  /// progres tidak bergantung pada request jaringan. Jika judul/cover belum
  /// ada, dilengkapi di latar belakang.
  void _saveProgress({required int page, required int total}) {
    if (!mounted) return;

    final cached = ref.read(mangaDetailProvider(widget.mangaId)).valueOrNull;
    _write(
      page: page,
      total: total,
      title: cached?.title ?? '',
      coverUrl: cached?.coverUrl,
    );

    if (cached == null) {
      ref
          .read(mangaDetailProvider(widget.mangaId).future)
          .then((detail) {
            if (!mounted) return;
            final current = ref
                .read(readingHistoryProvider.notifier)
                .entryFor(widget.mangaId);
            if (current == null || current.chapterId != widget.chapterId) {
              return;
            }
            _write(
              page: page,
              total: total,
              title: detail.title,
              coverUrl: detail.coverUrl,
            );
          })
          .catchError((Object _) {});
    }
  }

  void _write({
    required int page,
    required int total,
    required String title,
    String? coverUrl,
  }) {
    ref
        .read(readingHistoryProvider.notifier)
        .record(
          ReadingHistoryEntry(
            mangaId: widget.mangaId,
            mangaTitle: title,
            coverUrl: coverUrl,
            chapterId: widget.chapterId,
            chapterNumber: widget.chapterNumber,
            chapterTitle: widget.chapterTitle,
            readAt: DateTime.now(),
            page: page,
            totalPages: total,
          ),
        );
  }

  /// Simpan progres setelah pengguna berhenti membalik halaman.
  void _scheduleSave(int page, int total) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _saveProgress(page: page, total: total);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(chapterPagesProvider(widget.chapterId));
    final saver = ref.watch(dataSaverProvider);
    final webtoon = ref.watch(webtoonModeProvider);

    // Dimuat juga saat reader dibuka langsung (mis. dari kartu "Lanjut baca"),
    // supaya navigasi ke chapter berikutnya/sebelumnya tetap bisa ditentukan.
    ref.watch(chapterListProvider(widget.mangaId));

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

    if (urls.isNotEmpty) {
      _totalPages = urls.length;
      if (!_firstSaveDone) {
        _firstSaveDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _saveProgress(page: _currentPage + 1, total: _totalPages);
        });
      }
    }

    if (urls.isEmpty) {
      return const Center(
        child: Text(
          'Chapter tidak memiliki halaman.',
          style: AppTypography.bodySmall,
        ),
      );
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              // Webtoon: tidak ada konsep halaman, cukup toggle chrome.
              if (webtoon) {
                setState(() => _chromeVisible = !_chromeVisible);
                return;
              }

              final double width = MediaQuery.sizeOf(context).width;
              final double dx = details.localPosition.dx;

              // Ketuk kiri = mundur, kanan = maju, tengah = toggle kontrol.
              // Di ujung chapter, ketuk maju/mundur berpindah chapter.
              if (dx < width * 0.3) {
                if (_totalPages > 0 && _currentPage <= 0) {
                  _goToPreviousChapter();
                } else {
                  _goToPage(_currentPage - 1);
                }
              } else if (dx > width * 0.7) {
                if (_totalPages > 0 && _currentPage >= _totalPages - 1) {
                  _goToNextChapter();
                } else {
                  _goToPage(_currentPage + 1);
                }
              } else {
                setState(() => _chromeVisible = !_chromeVisible);
              }
            },
            child: webtoon
                ? ListView.builder(
                    itemCount: urls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == urls.length) {
                        return _ChapterFooter(
                          hasNext: _adjacentChapter(1) != null,
                          onNext: _goToNextChapter,
                        );
                      }
                      return _ReaderImage(
                        url: urls[index],
                        fit: BoxFit.fitWidth,
                      );
                    },
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Hanya hitung overscroll yang berasal dari geseran jari
                      // (dragDetails != null), supaya koreksi posisi saat
                      // layar pertama dimuat tidak ikut memicu pindah chapter.
                      if (notification is OverscrollNotification) {
                        if (notification.dragDetails == null) return false;

                        final bool atEnd = _currentPage >= _totalPages - 1;
                        final bool atStart = _currentPage <= 0;

                        if (atEnd && notification.overscroll > 0) {
                          _overscroll += notification.overscroll;
                          if (_overscroll > 90) {
                            _overscroll = 0;
                            _goToNextChapter();
                          }
                        } else if (atStart && notification.overscroll < 0) {
                          _overscroll += notification.overscroll.abs();
                          if (_overscroll > 90) {
                            _overscroll = 0;
                            _goToPreviousChapter();
                          }
                        }
                      } else if (notification is ScrollEndNotification) {
                        _overscroll = 0;
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: urls.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _prefetch(urls, index);
                        _scheduleSave(index + 1, urls.length);
                        if (index < urls.length - 1) _endHintShown = false;
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
        ),
        if (_chromeVisible) ...<Widget>[
          _TopBar(
            title: _chapterLabel,
            onBack: () => context.pop(),
            onSettings: _showSettings,
          ),
          if (!webtoon)
            _PageIndicator(current: _currentPage + 1, total: urls.length),
        ],
      ],
    );
  }

  String get _chapterLabel {
    if (widget.chapterTitle.isNotEmpty) return widget.chapterTitle;
    if (widget.chapterNumber.isNotEmpty) {
      return 'Chapter ${widget.chapterNumber}';
    }
    return 'Reader';
  }

  /// Pindah halaman dengan animasi singkat (dipakai tap kiri/kanan).
  void _goToPage(int index) {
    if (_totalPages <= 0) return;
    if (index < 0 || index >= _totalPages) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// Chapter sebelum/berikutnya pada bahasa yang sama.
  Chapter? _adjacentChapter(int delta) {
    final chapters = ref.read(chapterListProvider(widget.mangaId)).valueOrNull;
    if (chapters == null || chapters.isEmpty) return null;

    final int index = chapters.indexWhere(
      (Chapter c) => c.id == widget.chapterId,
    );
    if (index < 0) return null;

    final int target = index + delta;
    if (target < 0 || target >= chapters.length) return null;
    return chapters[target];
  }

  /// Buka [chapter] menggantikan reader saat ini, supaya tombol kembali
  /// tetap menuju halaman detail (bukan menumpuk chapter).
  void _openChapter(Chapter chapter) {
    final Uri uri = Uri(
      path: '/manga/${widget.mangaId}/read/${chapter.id}',
      queryParameters: <String, String>{
        'title': chapter.title,
        'number': chapter.chapterNumber,
      },
    );
    context.pushReplacement(uri.toString());
  }

  void _goToNextChapter() {
    final Chapter? next = _adjacentChapter(1);
    if (next == null) {
      _showEndHint(
        _chaptersLoading ? 'Memuat daftar chapter…' : 'Ini chapter terakhir.',
      );
      return;
    }
    _openChapter(next);
  }

  void _goToPreviousChapter() {
    final Chapter? previous = _adjacentChapter(-1);
    if (previous == null) {
      _showEndHint(
        _chaptersLoading ? 'Memuat daftar chapter…' : 'Ini chapter pertama.',
      );
      return;
    }
    _openChapter(previous);
  }

  bool get _chaptersLoading =>
      ref.read(chapterListProvider(widget.mangaId)).isLoading;

  void _showEndHint(String message) {
    if (_endHintShown) return;
    _endHintShown = true;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) _endHintShown = false;
    });
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
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final webtoon = ref.watch(webtoonModeProvider);
          final saver = ref.watch(dataSaverProvider);
          return SingleChildScrollView(
            // Bisa digulir + padding bawah mengikuti navigation bar Android,
            // supaya switch terakhir dan petunjuk tidak tertutup.
            padding: EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Pengaturan reader', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.l),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Mode webtoon',
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: const Text(
                    'Scroll vertikal, cocok untuk chapter panjang',
                    style: AppTypography.labelSmall,
                  ),
                  value: webtoon,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) =>
                      ref.read(webtoonModeProvider.notifier).set(value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Hemat kuota',
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: const Text(
                    'Pakai gambar kualitas data-saver',
                    style: AppTypography.labelSmall,
                  ),
                  value: saver,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) =>
                      ref.read(dataSaverProvider.notifier).set(value),
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Navigasi halaman: ketuk sisi kanan untuk halaman berikutnya, '
                  'sisi kiri untuk halaman sebelumnya, ketuk tengah untuk '
                  'menampilkan/menyembunyikan kontrol.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
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
    final int decodeWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context) *
                2)
            .round();

    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: decodeWidth,
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
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              IconButton(icon: const Icon(Icons.tune), onPressed: onSettings),
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

/// Penutup chapter pada mode webtoon: tombol lanjut ke chapter berikutnya.
class _ChapterFooter extends StatelessWidget {
  const _ChapterFooter({required this.hasNext, required this.onNext});

  final bool hasNext;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            hasNext ? 'Akhir chapter' : 'Chapter terakhir',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (hasNext) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('Chapter berikutnya'),
            ),
          ],
        ],
      ),
    );
  }
}
