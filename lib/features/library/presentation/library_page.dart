import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../account/presentation/account_dialog.dart';
import '../../manga/presentation/widgets/manga_card.dart';
import '../data/library_backup.dart';
import '../data/models/library_models.dart';
import '../library_providers.dart';

/// Pustaka: manga yang diikuti + riwayat baca.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followedMangaProvider);
    final history = ref.watch(readingHistoryProvider);
    final signedIn =
        AppConfig.hasSupabase && ref.watch(currentUserProvider) != null;
    final sort = ref.watch(librarySortProvider);

    final sortedFollowed = List<FollowedManga>.of(followed);
    if (sort == LibrarySort.titleAz) {
      sortedFollowed.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Pustaka', style: AppTypography.titleLarge),
          actions: <Widget>[
            if (history.isNotEmpty)
              IconButton(
                tooltip: 'Hapus semua riwayat',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _confirmClearHistory(context, ref),
              ),
            PopupMenuButton<String>(
              tooltip: 'Backup Pustaka',
              onSelected: (value) async {
                if (value == 'export') {
                  _export(context, ref);
                } else if (value == 'import') {
                  _import(context, ref);
                } else if (value == 'account') {
                  showAccountDialog(context);
                } else if (value == 'sync') {
                  await _sync(context, ref);
                } else if (value == 'sort_newest') {
                  ref.read(librarySortProvider.notifier).set(LibrarySort.newest);
                } else if (value == 'sort_title') {
                  ref.read(librarySortProvider.notifier).set(LibrarySort.titleAz);
                } else if (value == 'donate') {
                  context.push('/donate');
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                CheckedPopupMenuItem<String>(
                  value: 'sort_newest',
                  checked: sort == LibrarySort.newest,
                  child: const Text('Urutkan: Terbaru'),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'sort_title',
                  checked: sort == LibrarySort.titleAz,
                  child: const Text('Urutkan: Judul A–Z'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'export',
                  child: Text('Ekspor ke clipboard'),
                ),
                const PopupMenuItem<String>(
                  value: 'import',
                  child: Text('Impor dari clipboard'),
                ),
                if (signedIn) ...<PopupMenuEntry<String>>[
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'sync',
                    child: Text('Sinkronkan sekarang'),
                  ),
                ],
                if (AppConfig.hasSupabase) ...<PopupMenuEntry<String>>[
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'account',
                    child: Text('Akun & sinkronisasi'),
                  ),
                ],
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'donate',
                  child: Text('Dukung Isekaiku'),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.onSurface,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            dividerColor: AppColors.outlineVariant,
            labelStyle: AppTypography.labelLarge,
            tabs: <Widget>[
              Tab(text: 'Diikuti (${followed.length})'),
              Tab(text: 'Riwayat (${history.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _FollowedTab(items: sortedFollowed),
            _HistoryTab(items: history),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Hapus riwayat?', style: AppTypography.titleMedium),
        content: const Text(
          'Semua riwayat baca akan dihapus. Manga di daftar Diikuti tidak '
          'terpengaruh.',
          style: AppTypography.bodySmall,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(readingHistoryProvider.notifier).clear();
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final backup = ref.read(libraryBackupServiceProvider).export();
    await Clipboard.setData(ClipboardData(text: backup.encode()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Backup disalin: ${backup.followed.length} diikuti, '
            '${backup.history.length} riwayat.',
          ),
        ),
      );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportDialog(),
    );
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final summary = await ref.read(libraryBackupServiceProvider).import(raw);
      ref.read(followedMangaProvider.notifier).reload();
      ref.read(readingHistoryProvider.notifier).reload();
      ref.read(readChaptersProvider.notifier).reload();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Impor selesai: ${summary.followed} diikuti, '
              '${summary.history} riwayat.',
            ),
          ),
        );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    await ref.read(syncNotifierProvider.notifier).syncNow();
    if (!context.mounted) return;

    final state = ref.read(syncNotifierProvider);
    final text = switch (state.phase) {
      SyncPhase.done => 'Sinkronisasi selesai.',
      SyncPhase.error => state.message ?? 'Sinkronisasi gagal.',
      SyncPhase.syncing => 'Sinkronisasi berjalan…',
      SyncPhase.idle => 'Tidak ada yang disinkronkan.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      setState(() => _error = 'Clipboard kosong.');
      return;
    }
    _controller.text = text;
    setState(() => _error = null);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Tempel teks backup terlebih dahulu.');
      return;
    }
    if (LibraryBackup.decode(text) == null) {
      setState(() => _error = 'Teks bukan backup Isekaiku yang valid.');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Impor Pustaka', style: AppTypography.titleMedium),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tempel teks backup yang diekspor dari aplikasi ini. Data akan '
              'digabungkan, bukan menimpa.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              style: AppTypography.labelSmall,
              decoration: InputDecoration(
                hintText: '{"app":"isekaiku", ...}',
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Tempel dari clipboard'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Impor'),
        ),
      ],
    );
  }
}

class _FollowedTab extends ConsumerWidget {
  const _FollowedTab({required this.items});

  final List<FollowedManga> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.bookmark_border,
        title: 'Belum ada manga diikuti',
        subtitle:
            'Buka halaman manga lalu tekan tombol ikuti untuk menyimpannya '
            'di sini.',
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.xs,
          ),
          child: Text(
            'Tekan lama kartu untuk berhenti mengikuti.',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
              childAspectRatio: 0.58,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _FollowedCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _FollowedCard extends ConsumerWidget {
  const _FollowedCard({required this.item});

  final FollowedManga item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _confirmUnfollow(context, ref),
      child: MangaCard(manga: item.toManga()),
    );
  }

  Future<void> _confirmUnfollow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Berhenti mengikuti?', style: AppTypography.titleMedium),
        content: Text(
          item.title,
          style: AppTypography.bodySmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(followedMangaProvider.notifier).remove(item.id);
    }
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.items});

  final List<ReadingHistoryEntry> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'Belum ada riwayat baca',
        subtitle: 'Chapter yang kamu buka akan muncul di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.outlineVariant),
      itemBuilder: (context, index) {
        final entry = items[index];
        return _HistoryTile(entry: entry);
      },
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final ReadingHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs,
      ),
      leading: _CoverThumb(url: entry.coverUrl),
      title: Text(
        entry.mangaTitle.isEmpty ? 'Tanpa judul' : entry.mangaTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        '${entry.chapterLabel}  •  ${_relativeTime(entry.readAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall,
      ),
      trailing: IconButton(
        tooltip: 'Hapus dari riwayat',
        icon: const Icon(
          Icons.close,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
        onPressed: () =>
            ref.read(readingHistoryProvider.notifier).remove(entry.mangaId),
      ),
      onTap: () {
        final uri = Uri(
          path: '/manga/${entry.mangaId}/read/${entry.chapterId}',
          queryParameters: <String, String>{
            'title': entry.chapterTitle,
            'number': entry.chapterNumber,
          },
        );
        context.push(uri.toString());
      },
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: AppColors.surfaceContainerHigh,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 16,
        color: AppColors.onSurfaceVariant,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: SizedBox(
        width: 44,
        height: 60,
        child: url == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: AppColors.surfaceContainerHigh),
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.m),
            Text(title, style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "baru saja", "5 menit lalu", "3 hari lalu", lalu tanggal.
String _relativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  final d = time.day.toString().padLeft(2, '0');
  final m = time.month.toString().padLeft(2, '0');
  return '$d/$m/${time.year}';
}
