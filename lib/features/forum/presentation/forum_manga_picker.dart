import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../manga/data/models/manga.dart';
import '../../manga/manga_providers.dart';

/// Pilih manga untuk dilampirkan ke topik Rekomendasi.
Future<Manga?> showMangaPicker(BuildContext context) {
  return showModalBottomSheet<Manga>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLow,
    builder: (context) => const _MangaPickerSheet(),
  );
}

class _MangaPickerSheet extends ConsumerStatefulWidget {
  const _MangaPickerSheet();

  @override
  ConsumerState<_MangaPickerSheet> createState() => _MangaPickerSheetState();
}

class _MangaPickerSheetState extends ConsumerState<_MangaPickerSheet> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  String _value = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _value = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_value));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.s),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Cari manga untuk direkomendasikan…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: _value.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Text(
                          'Ketik judul manga yang ingin kamu rekomendasikan.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    )
                  : results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text(
                            'Pencarian gagal. Periksa koneksi lalu coba lagi.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xxl),
                              child: Text(
                                'Tidak ada manga yang cocok.',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xxl,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final Manga manga = items[index];
                            return ListTile(
                              onTap: () => Navigator.of(context).pop(manga),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.l,
                                vertical: AppSpacing.xs,
                              ),
                              leading: _Cover(url: manga.coverUrl),
                              title: Text(
                                manga.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium,
                              ),
                              subtitle: manga.author.isEmpty
                                  ? null
                                  : Text(
                                      manga.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSmall,
                                    ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: SizedBox(
        width: 44,
        height: 60,
        child: url == null
            ? const ColoredBox(
                color: AppColors.surfaceContainer,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: AppColors.surfaceContainer),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.surfaceContainer,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}
