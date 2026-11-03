import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/iseakaiku_wordmark.dart';
import '../manga_providers.dart';
import 'widgets/manga_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(popularMangaProvider);
    final latest = ref.watch(latestMangaProvider);

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
                        onPressed: () => context.go('/search'),
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------------- Populer ----------------
              _SectionHeader(
                title: 'Populer',
                onRetry: () => ref.invalidate(popularMangaProvider),
              ),
              ...switch (popular) {
                AsyncData(:final value) when value.isNotEmpty => <Widget>[
                    MangaGrid(items: value),
                  ],
                AsyncData() => <Widget>[
                    const SliverToBoxAdapter(
                      child: _EmptyNote(text: 'Belum ada manga untuk bahasa ini.'),
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
                _ => <Widget>[const _LoadingSliver()],
              },

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
                      child: _EmptyNote(
                        text: 'Gagal memuat update terbaru.',
                      ),
                    ),
                  ],
                _ => <Widget>[const _LoadingSliver()],
              },
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    'Sumber data: MangaDex',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall,
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

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
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
