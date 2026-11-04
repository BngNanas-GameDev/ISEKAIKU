import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Kotak abu-abu pengganti konten saat memuat.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.m,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton grid manga (3 kolom, rasio 2:3).
class MangaGridSkeleton extends StatelessWidget {
  const MangaGridSkeleton({super.key, this.count = 9});

  final int count;

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
        itemCount: count,
        itemBuilder: (context, index) => const SkeletonBox(),
      ),
    );
  }
}

/// Skeleton carousel untuk blok "Populer".
class PopularCarouselSkeleton extends StatelessWidget {
  const PopularCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        itemCount: 3,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, index) => const AspectRatio(
          aspectRatio: 0.72,
          child: SkeletonBox(radius: AppRadius.l),
        ),
      ),
    );
  }
}

/// Skeleton halaman detail manga.
class MangaDetailSkeleton extends StatelessWidget {
  const MangaDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonBox(height: 240, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.l),
          const SkeletonBox(width: 220, height: 22),
          const SizedBox(height: AppSpacing.s),
          const SkeletonBox(width: 140, height: 14),
          const SizedBox(height: AppSpacing.l),
          for (var i = 0; i < 5; i++) ...<Widget>[
            const SkeletonBox(height: 14),
            const SizedBox(height: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}
