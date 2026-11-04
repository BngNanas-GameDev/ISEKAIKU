import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/models/manga_tag.dart';
import '../manga_providers.dart';
import 'widgets/manga_card.dart';

/// Jelajah katalog dengan filter genre, status, tahun, dan urutan.
class BrowsePage extends ConsumerWidget {
  const BrowsePage({super.key});

  static const Map<String, String> _statusLabels = <String, String>{
    'ongoing': 'Berjalan',
    'completed': 'Tamat',
    'hiatus': 'Hiatus',
    'cancelled': 'Dibatalkan',
  };

  static const Map<BrowseOrder, String> _orderLabels = <BrowseOrder, String>{
    BrowseOrder.popular: 'Populer',
    BrowseOrder.latest: 'Terbaru',
    BrowseOrder.rating: 'Rating',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(browseFilterProvider);
    final results = ref.watch(browseResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Jelajah', style: AppTypography.titleLarge),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset filter',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: filter.isEmpty && filter.order == BrowseOrder.popular
                ? null
                : () => ref.read(browseFilterProvider.notifier).reset(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _Filters(filter: filter),
          Expanded(
            child: switch (results) {
              AsyncData(:final value) when value.isEmpty => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      'Tidak ada judul yang cocok dengan filter ini.\n'
                      'Coba kurangi genre atau ubah status.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ),
              AsyncData(:final value) => CustomScrollView(
                  slivers: <Widget>[
                    MangaGrid(items: value),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
              AsyncError(:final error) => ErrorRetry(
                  error: error,
                  onRetry: () => ref.invalidate(browseResultsProvider),
                ),
              _ => const CustomScrollView(
                  slivers: <Widget>[
                    MangaGridSkeleton(),
                    SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxl),
                    ),
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.filter});

  final BrowseFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(browseFilterProvider.notifier);
    final tags = ref.watch(mangaTagsProvider);

    final years = <int>[
      for (var year = DateTime.now().year; year >= 1990; year--) year,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            0,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _Picker<String?>(
                  label: 'Status',
                  value: filter.status,
                  items: <String?>[null, ...BrowsePage._statusLabels.keys],
                  labelOf: (value) =>
                      value == null ? 'Semua' : BrowsePage._statusLabels[value]!,
                  onChanged: notifier.setStatus,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _Picker<int?>(
                  label: 'Tahun',
                  value: filter.year,
                  items: <int?>[null, ...years],
                  labelOf: (value) => value?.toString() ?? 'Semua',
                  onChanged: notifier.setYear,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _Picker<BrowseOrder>(
                  label: 'Urutan',
                  value: filter.order,
                  items: BrowsePage._orderLabels.keys.toList(),
                  labelOf: (value) => BrowsePage._orderLabels[value]!,
                  onChanged: notifier.setOrder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          height: 40,
          child: switch (tags) {
            AsyncData(:final value) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                itemCount: value.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.s),
                itemBuilder: (context, index) {
                  final MangaTag tag = value[index];
                  final selected = filter.tagIds.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name, style: AppTypography.labelSmall),
                    selected: selected,
                    onSelected: (_) => notifier.toggleTag(tag.id),
                    showCheckmark: false,
                  );
                },
              ),
            AsyncError() => const SizedBox.shrink(),
            _ => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          },
        ),
        const Divider(height: AppSpacing.l),
      ],
    );
  }
}

class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.surfaceContainerHigh,
          style: AppTypography.labelSmall,
          icon: const Icon(Icons.expand_more, size: 18),
          hint: Text(label, style: AppTypography.labelSmall),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelOf(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall,
                  ),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}
