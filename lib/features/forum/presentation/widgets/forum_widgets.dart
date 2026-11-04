import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/forum_format.dart';
import '../../data/models/forum_models.dart';

/// Warna aksen per kategori agar mudah dibedakan sekilas.
Color forumCategoryColor(ForumCategory category) {
  switch (category) {
    case ForumCategory.umum:
      return AppColors.primary;
    case ForumCategory.rekomendasi:
      return AppColors.success;
    case ForumCategory.bantuan:
      return AppColors.warning;
    case ForumCategory.offtopic:
      return AppColors.onSurfaceVariant;
  }
}

/// Label kecil berwarna untuk kategori.
class ForumCategoryBadge extends StatelessWidget {
  const ForumCategoryBadge({super.key, required this.category});

  final ForumCategory category;

  @override
  Widget build(BuildContext context) {
    final Color color = forumCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        category.label,
        style: AppTypography.labelSmall.copyWith(color: color, height: 1.1),
      ),
    );
  }
}

/// Avatar inisial untuk penulis forum.
class ForumAvatar extends StatelessWidget {
  const ForumAvatar({super.key, required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        ForumFormat.initials(name),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurface,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Satu baris topik di daftar forum.
class ForumThreadTile extends StatelessWidget {
  const ForumThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
    this.now,
  });

  final ForumThread thread;
  final VoidCallback onTap;

  /// Untuk pengujian waktu relatif.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ForumCategoryBadge(category: thread.category),
                if (thread.isPinned) ...<Widget>[
                  const SizedBox(width: AppSpacing.s),
                  const Icon(
                    Icons.push_pin_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
                const Spacer(),
                Text(
                  ForumFormat.relative(thread.lastActivityAt, now: now),
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              thread.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium,
            ),
            if (thread.body.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                thread.body.trim().replaceAll(RegExp(r'\s+'), ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            Row(
              children: <Widget>[
                ForumAvatar(name: thread.authorName, size: 22),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    thread.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${thread.replyCount}', style: AppTypography.labelSmall),
                if (thread.isLocked) ...<Widget>[
                  const SizedBox(width: AppSpacing.s),
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ajakan masuk sebelum ikut menulis.
class ForumSignInCard extends StatelessWidget {
  const ForumSignInCard({
    super.key,
    required this.onSignIn,
    this.compact = false,
  });

  final VoidCallback onSignIn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Masuk untuk ikut diskusi', style: AppTypography.titleMedium),
          if (!compact) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Membaca forum tetap gratis. Untuk membuat topik, membalas, '
              'atau melapor, masuk dulu dengan Google.',
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Masuk dengan Google'),
            ),
          ),
        ],
      ),
    );
  }
}
