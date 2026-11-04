import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../account/presentation/account_dialog.dart';
import '../data/models/forum_models.dart';
import '../data/forum_repository.dart';
import '../forum_providers.dart';
import 'widgets/forum_widgets.dart';

/// Forum komunitas: daftar topik diskusi.
class ForumPage extends ConsumerWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.hasSupabase) {
      return const _ForumUnavailable();
    }

    final AsyncValue<List<ForumThread>> threads = ref.watch(
      forumThreadsProvider,
    );
    final ForumCategory? category = ref.watch(forumCategoryFilterProvider);
    final ForumSort sort = ref.watch(forumSortProvider);
    final bool signedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Forum', style: AppTypography.titleLarge),
        actions: <Widget>[
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(forumThreadsProvider),
          ),
          IconButton(
            tooltip: 'Akun',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => showAccountDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startCompose(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Tulis'),
      ),
      body: Column(
        children: <Widget>[
          _CategoryBar(
            selected: category,
            onSelected: (value) {
              ref.read(forumCategoryFilterProvider.notifier).state = value;
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.s,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    threads.valueOrNull != null
                        ? '${threads.valueOrNull!.length} diskusi'
                        : threads.hasError
                        ? 'Forum komunitas'
                        : 'Memuat diskusi…',
                    style: AppTypography.labelSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(forumSortProvider.notifier)
                        .state = sort == ForumSort.terbaru
                        ? ForumSort.teraktif
                        : ForumSort.terbaru;
                  },
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: Text(sort.label),
                ),
              ],
            ),
          ),
          if (!signedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: ForumSignInCard(
                compact: true,
                onSignIn: () => showAccountDialog(context),
              ),
            ),
          Expanded(
            child: threads.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ForumError(
                message: _messageFor(error),
                onRetry: () => ref.invalidate(forumThreadsProvider),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(forumThreadsProvider.future),
                child: items.isEmpty
                    ? _EmptyForum(hasFilter: category != null)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xxxl * 3,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ForumThread thread = items[index];
                          return ForumThreadTile(
                            thread: thread,
                            onTap: () => context.push('/forum/${thread.id}'),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCompose(BuildContext context, WidgetRef ref) async {
    if (ref.read(currentUserProvider) == null) {
      await showAccountDialog(context);
      if (!context.mounted) return;
      if (ref.read(currentUserProvider) == null) return;
    }
    context.push('/forum/new');
  }

  String _messageFor(Object error) {
    if (error is PostgrestException) {
      // Tabel forum belum dibuat di server.
      if (error.code == 'PGRST205' || error.code == '42P01') {
        return 'Forum belum disiapkan di server.\n\n'
            'Jalankan supabase/migrations/0002_forum.sql di Supabase, '
            'lalu muat ulang.';
      }
      return 'Tidak bisa memuat forum.\n\n${error.message}';
    }
    return 'Tidak bisa memuat forum. Periksa koneksi lalu coba lagi.';
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final ForumCategory? selected;
  final ValueChanged<ForumCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        children: <Widget>[
          _chip(context, label: 'Semua', value: null),
          for (final ForumCategory category in ForumCategory.values)
            _chip(context, label: category.label, value: category),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required ForumCategory? value,
  }) {
    final bool isSelected = selected == value;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        labelStyle: AppTypography.labelSmall.copyWith(
          color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _EmptyForum extends StatelessWidget {
  const _EmptyForum({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxxl),
        const Icon(
          Icons.forum_outlined,
          size: 56,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          hasFilter ? 'Belum ada topik di kategori ini' : 'Forum masih sepi',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          hasFilter
              ? 'Coba kategori lain, atau buat topik pertama di sini.'
              : 'Jadilah yang pertama membuka diskusi: rekomendasi manga, '
                    'cari teman baca, atau tanya soal aplikasi.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

class _ForumError extends StatelessWidget {
  const _ForumError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxxl),
        const Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.l),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

class _ForumUnavailable extends StatelessWidget {
  const _ForumUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Forum', style: AppTypography.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.forum_outlined,
              size: 56,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Forum belum aktif',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Forum membutuhkan koneksi Supabase. Fitur baca tetap berjalan '
              'tanpa koneksi.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
