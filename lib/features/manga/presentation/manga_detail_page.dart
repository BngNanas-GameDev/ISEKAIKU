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

class MangaDetailPage extends ConsumerWidget {
  final String mangaId;

  const MangaDetailPage({super.key, required this.mangaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(mangaDetailProvider(mangaId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (detail) {
        AsyncData(:final value) => _DetailBody(manga: value),
        AsyncError(:final error) => SafeArea(
            child: ErrorRetry(
              error: error,
              onRetry: () => ref.invalidate(mangaDetailProvider(mangaId)),
            ),
          ),
        _ => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final Manga manga;

  const _DetailBody({required this.manga});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    final chapters = ref.watch(chapterListProvider(manga.id));
    final language = ref.watch(chapterLanguageProvider);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          expandedHeight: 320,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (manga.coverUrl != null)
                  CachedNetworkImage(
                    imageUrl: manga.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ColoredBox(color: AppColors.surfaceContainer),
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: AppColors.surfaceContainer),
                  )
                else
                  const ColoredBox(color: AppColors.surfaceContainer),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x99222831),
                        Color(0x00222831),
                        Color(0xF2222831),
                      ],
                      stops: <double>[0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  bottom: AppSpacing.m,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        manga.title,
                        style: AppTypography.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (manga.author.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          manga.author,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: <Widget>[
                    _MetaChip(label: _statusLabel(manga.status)),
                    if (manga.year.isNotEmpty) _MetaChip(label: manga.year),
                    _MetaChip(label: _ratingLabel(manga.contentRating)),
                    _MetaChip(label: '${_formatCount(manga.follows)} follower'),
                  ],
                ),
                if (manga.genres.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: manga.genres
                        .take(8)
                        .map((genre) => _GenreChip(label: genre))
                        .toList(),
                  ),
                ],
                if (manga.description.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    manga.description,
                    maxLines: _expanded ? null : 4,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? 'Sembunyikan' : 'Selengkapnya',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.m),
                const Divider(),
                Row(
                  children: <Widget>[
                    Text('Chapter', style: AppTypography.titleLarge),
                    const Spacer(),
                    SegmentedButton<String>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          AppTypography.labelSmall,
                        ),
                      ),
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(value: 'id', label: Text('ID')),
                        ButtonSegment<String>(value: 'en', label: Text('EN')),
                      ],
                      selected: <String>{language},
                      onSelectionChanged: (value) => ref
                          .read(chapterLanguageProvider.notifier)
                          .state = value.first,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
              ],
            ),
          ),
        ),
        ...switch (chapters) {
          AsyncData(:final value) when value.isEmpty => <Widget>[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.l),
                  child: Text('Belum ada chapter tersedia.',
                      style: AppTypography.bodySmall),
                ),
              ),
            ],
          AsyncData(:final value) => <Widget>[
              SliverList.builder(
                itemCount: value.length,
                itemBuilder: (context, index) => _ChapterTile(
                  mangaId: manga.id,
                  chapter: value[index],
                ),
              ),
            ],
          AsyncError(:final error) => <Widget>[
              SliverToBoxAdapter(
                child: ErrorRetry(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(chapterListProvider(manga.id)),
                ),
              ),
            ],
          _ => <Widget>[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
        },
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  String _statusLabel(String status) {    switch (status) {
      case 'completed':
        return 'Tamat';
      case 'hiatus':
        return 'Hiatus';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Berjalan';
    }
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'safe':
        return 'Aman';
      case 'suggestive':
        return 'Saran';
      case 'erotica':
        return 'Erotika';
      case 'pornographic':
        return 'Dewasa';
      default:
        return rating;
    }
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class _ChapterTile extends StatelessWidget {
  final String mangaId;
  final Chapter chapter;

  const _ChapterTile({required this.mangaId, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final label = chapter.chapterNumber.isEmpty
        ? 'Oneshot'
        : 'Chapter ${chapter.chapterNumber}';

    return ListTile(
      tileColor: AppColors.background,
      onTap: () {
        final query = <String, String>{
          'title': chapter.title,
          'number': chapter.chapterNumber,
        };
        final uri = Uri(
          path: '/manga/$mangaId/read/${chapter.id}',
          queryParameters: query,
        );
        context.push(uri.toString());
      },
      title: Text(
        chapter.title.isEmpty ? label : chapter.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        '$label  •  ${chapter.language.toUpperCase()}  •  ${chapter.pages} halaman',
        style: AppTypography.labelSmall,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.onSurface),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;

  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(38),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}
