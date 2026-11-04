import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/manga.dart';
import '../../../../core/images/cover_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../manga_providers.dart';

/// Kartu manga 2:3 dengan overlay judul.
class MangaCard extends ConsumerWidget {
  final Manga manga;

  const MangaCard({super.key, required this.manga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool dataSaver = ref.watch(dataSaverProvider);
    final String? cover = coverUrlFor(manga.coverUrl, dataSaver: dataSaver);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int decodeWidth = ((MediaQuery.sizeOf(context).width / 3) * dpr)
        .round();

    return GestureDetector(
      onTap: () => context.push('/manga/${manga.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: ColoredBox(
          color: AppColors.surfaceContainer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null)
                CachedNetworkImage(
                  imageUrl: cover,
                  memCacheWidth: decodeWidth,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) =>
                      const ColoredBox(color: AppColors.surfaceContainerHigh),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else
                const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
              // Gradient agar judul tetap terbaca.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xE6222831)],
                  ),
                ),
              ),
              if (manga.contentRating == 'erotica' ||
                  manga.contentRating == 'pornographic')
                const Positioned(
                  top: AppSpacing.s,
                  left: AppSpacing.s,
                  child: _AdultBadge(),
                ),
              Positioned(
                left: AppSpacing.s,
                right: AppSpacing.s,
                bottom: AppSpacing.s,
                child: Text(
                  manga.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Penanda konten dewasa pada kartu.
class _AdultBadge extends StatelessWidget {
  const _AdultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}

/// Grid manga yang bisa dipakai di beranda dan pencarian.
class MangaGrid extends StatelessWidget {
  final List<Manga> items;

  const MangaGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.m,
          mainAxisSpacing: AppSpacing.m,
          childAspectRatio: 0.58,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => MangaCard(manga: items[index]),
      ),
    );
  }
}

/// Tampilan error dengan tombol coba lagi.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.error, required this.onRetry});

  static String _message(Object error) {
    if (error is ApiException) return error.userMessage;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Gagal memuat data.\n${_message(error)}',
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.l),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
