import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/images/cover_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/iseakaiku_wordmark.dart';
import '../../../core/widgets/skeleton.dart';
import '../../account/presentation/account_dialog.dart';
import '../../legal/presentation/about_dialog.dart';
import '../../library/data/models/library_models.dart';
import '../../library/library_providers.dart';
import '../data/models/manga.dart';
import '../manga_providers.dart';
import 'adult_content_toggle.dart';
import 'widgets/manga_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(popularMangaProvider);
    final latest = ref.watch(latestMangaProvider);
    final bool adult = ref.watch(showAdultContentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () async {
            ref.invalidate(popularMangaProvider);
            ref.invalidate(latestMangaProvider);
            await Future.wait(<Future<dynamic>>[
              ref.read(popularMangaProvider.future),
              ref.read(latestMangaProvider.future),
            ]);
          },
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  child: Row(
                    children: [
                      const IsekaikuWordmark(size: 22),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Jelajah genre',
                        onPressed: () => context.push('/browse'),
                        icon: const Icon(
                          Icons.tune,
                          color: AppColors.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.go('/search'),
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.onSurface,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Menu',
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.onSurface,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'about':
                              showAboutAppDialog(context);
                            case 'privacy':
                              context.push('/legal/privacy');
                            case 'terms':
                              context.push('/legal/terms');
                            case 'adult':
                              toggleAdultContent(context, ref);
                            case 'account':
                              showAccountDialog(context);
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'about',
                            child: Text('Info aplikasi'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'privacy',
                            child: Text('Kebijakan Privasi'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'terms',
                            child: Text('Syarat Layanan'),
                          ),
                          CheckedPopupMenuItem<String>(
                            value: 'adult',
                            checked: adult,
                            child: const Text('Konten 18+'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'account',
                            child: Text('Akun & Sinkronisasi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: _ContinueReadingCard()),

              // ---------------- Populer ----------------
              _SectionHeader(
                title: 'Populer',
                onRetry: () => ref.invalidate(popularMangaProvider),
              ),
              ...switch (popular) {
                AsyncData(:final value) when value.isNotEmpty => <Widget>[
                  _PopularCarousel(items: value),
                ],
                AsyncData() => <Widget>[
                  const SliverToBoxAdapter(
                    child: _EmptyNote(
                      text: 'Belum ada manga untuk bahasa ini.',
                    ),
                  ),
                ],
                AsyncError(:final error) => <Widget>[
                  SliverToBoxAdapter(
                    child: ErrorRetry(
                      error: error,
                      onRetry: () => ref.invalidate(popularMangaProvider),
                    ),
                  ),
                ],
                _ => <Widget>[
                  const SliverToBoxAdapter(child: PopularCarouselSkeleton()),
                ],
              },

              // ---------------- Donate ----------------
              const SliverToBoxAdapter(child: _DonateBanner()),

              // ---------------- Terbaru ----------------
              _SectionHeader(
                title: 'Update terbaru',
                onRetry: () => ref.invalidate(latestMangaProvider),
              ),
              ...switch (latest) {
                AsyncData(:final value) when value.isNotEmpty => <Widget>[
                  MangaGrid(items: value),
                ],
                AsyncData() => <Widget>[
                  const SliverToBoxAdapter(
                    child: _EmptyNote(text: 'Tidak ada update terbaru.'),
                  ),
                ],
                AsyncError() => <Widget>[
                  SliverToBoxAdapter(
                    child: _EmptyNote(text: 'Gagal memuat update terbaru.'),
                  ),
                ],
                _ => <Widget>[const MangaGridSkeleton()],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _SectionHeader({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.m,
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(title, style: AppTypography.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;

  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xl,
      ),
      child: Text(text, style: AppTypography.bodySmall),
    );
  }
}

/// Kartu "Lanjut baca": chapter terakhir yang dibuka + posisi halaman.
class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(continueReadingProvider);
    if (entry == null) return const SizedBox.shrink();

    final progress = entry.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.m),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context, entry),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: <Widget>[
                _ContinueCover(url: entry.coverUrl),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Lanjut baca',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.mangaTitle.isEmpty
                            ? 'Tanpa judul'
                            : entry.mangaTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.page > 0
                            ? '${entry.chapterLabel}  •  ${entry.positionLabel}'
                            : entry.chapterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall,
                      ),
                      if (progress != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.s),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, ReadingHistoryEntry entry) {
    final uri = Uri(
      path: '/manga/${entry.mangaId}/read/${entry.chapterId}',
      queryParameters: <String, String>{
        'title': entry.chapterTitle,
        'number': entry.chapterNumber,
        if (entry.page > 0) 'page': '${entry.page}',
      },
    );
    context.push(uri.toString());
  }
}

class _ContinueCover extends ConsumerWidget {
  const _ContinueCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? cover = coverUrlFor(
      url,
      dataSaver: ref.watch(dataSaverProvider),
    );
    const fallback = ColoredBox(
      color: AppColors.surfaceContainerHigh,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 18,
        color: AppColors.onSurfaceVariant,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: SizedBox(
        width: 52,
        height: 70,
        child: cover == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: AppColors.surfaceContainerHigh),
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}

/// Carousel horizontal untuk blok "Populer".
class _PopularCarousel extends StatefulWidget {
  const _PopularCarousel({required this.items});

  final List<Manga> items;

  @override
  State<_PopularCarousel> createState() => _PopularCarouselState();
}

class _PopularCarouselState extends State<_PopularCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.76,
  );
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return SliverToBoxAdapter(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: items.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? AppSpacing.l : AppSpacing.s,
                    right: AppSpacing.s,
                  ),
                  child: _PopularCard(manga: items[index]),
                );
              },
            ),
          ),
          if (items.length > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _page ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PopularCard extends ConsumerWidget {
  const _PopularCard({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool adult =
        manga.contentRating == 'erotica' ||
        manga.contentRating == 'pornographic';
    final String? cover = coverUrlFor(
      manga.coverUrl,
      dataSaver: ref.watch(dataSaverProvider),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.l),
      onTap: () => context.push('/manga/${manga.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (cover != null)
              CachedNetworkImage(
                imageUrl: cover,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: AppColors.surfaceContainerHigh),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.surfaceContainerHigh,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              const ColoredBox(
                color: AppColors.surfaceContainerHigh,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0xF2222831)],
                ),
              ),
            ),
            if (adult)
              Positioned(
                top: AppSpacing.s,
                left: AppSpacing.s,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Text(
                    '18+',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.background,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.m,
              right: AppSpacing.m,
              bottom: AppSpacing.m,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    manga.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium,
                  ),
                  if (manga.author.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      manga.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner dukungan di bawah carousel Populer.
class _DonateBanner extends StatelessWidget {
  const _DonateBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.xs,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Semantics(
        button: true,
        label: 'Dukung Isekaiku',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: () => context.push('/donate'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.l),
            child: AspectRatio(
              aspectRatio: 2.7,
              child: Image.asset(
                'assets/donate/DOnate.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: AppColors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Text(
                    'Dukung Isekaiku',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
