import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/search_history.dart';
import '../manga_providers.dart';
import 'widgets/manga_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchPage({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).add(query);
    setState(() => _query = query);
  }

  void _useQuery(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    ref.read(searchHistoryProvider.notifier).add(query);
    setState(() => _query = query);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_query));
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _submit,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Cari judul manga...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty && history.isNotEmpty
                  ? _buildHistory(history)
                  : switch (results) {
                      AsyncData(:final value) when value.isEmpty => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Text(
                              _query.trim().isEmpty
                                  ? 'Ketik judul untuk mulai mencari.'
                                  : 'Tidak ada hasil untuk "$_query".',
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
                          onRetry: () =>
                              ref.invalidate(searchResultsProvider(_query)),
                        ),
                      _ => const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(List<String> history) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Pencarian terakhir', style: AppTypography.labelLarge),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).clear(),
              child: Text(
                'Hapus',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: history
              .map(
                (query) => ActionChip(
                  label: Text(query, style: AppTypography.labelSmall),
                  onPressed: () => _useQuery(query),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Ketik untuk mencari judul baru.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
