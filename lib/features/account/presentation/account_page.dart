import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../forum/data/models/forum_models.dart';
import '../../forum/forum_providers.dart';
import '../../forum/presentation/widgets/forum_widgets.dart';
import '../../legal/legal_content.dart';
import '../../legal/presentation/legal_pages.dart';
import '../account_providers.dart';
import '../data/models/profile_models.dart';
import '../data/profile_validation.dart';
import 'account_dialog.dart';

/// Tab Akun: profil, statistik, dan aktivitas forum.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.hasSupabase) {
      return const _AccountUnavailable();
    }

    final User? user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Akun', style: AppTypography.titleLarge),
        actions: <Widget>[
          if (user != null)
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmSignOut(context, ref),
            ),
        ],
      ),
      body: user == null ? const _SignedOutView() : _ProfileView(user: user),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Pustaka dan riwayat di perangkat tetap tersimpan. Sinkronisasi '
          'berhenti sampai kamu masuk lagi.',
          style: AppTypography.bodySmall,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    ref.invalidate(currentProfileProvider);
    ref.invalidate(myForumThreadsProvider);
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final AsyncValue<ProfileStats> stats = ref.watch(
      profileStatsProvider(user.id),
    );
    final AsyncValue<List<ForumThread>> threads = ref.watch(
      myForumThreadsProvider,
    );
    final int readCount = ref.watch(readMangaCountProvider);

    final UserProfile? data = profile.valueOrNull;
    final String name = data?.displayName ?? _nameFromUser(user);
    final String bio = data?.bio.trim() ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(profileStatsProvider(user.id));
        ref.invalidate(myForumThreadsProvider);
        await Future.wait(<Future<void>>[
          ref.read(currentProfileProvider.future),
          ref.read(profileStatsProvider(user.id).future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.m,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Avatar(
                  name: name,
                  url: data?.avatarUrl ?? _avatarFromUser(user),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: AppTypography.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        bio.isEmpty ? 'Belum ada bio.' : bio,
                        style: AppTypography.bodySmall.copyWith(
                          color: bio.isEmpty
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                          ),
                        ),
                        onPressed: () => _editProfile(context, ref, name, bio),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit profil'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _Stat(value: '$readCount', label: 'Dibaca'),
                ),
                Expanded(
                  child: _Stat(
                    value: stats.valueOrNull == null
                        ? '—'
                        : '${stats.valueOrNull!.followers}',
                    label: 'Pengikut',
                    onTap: () => _showFollowList(
                      context,
                      ref,
                      title: 'Pengikut',
                      provider: followersProvider(user.id),
                    ),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: stats.valueOrNull == null
                        ? '—'
                        : '${stats.valueOrNull!.following}',
                    label: 'Mengikuti',
                    onTap: () => _showFollowList(
                      context,
                      ref,
                      title: 'Mengikuti',
                      provider: followingProvider(user.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.s,
            ),
            child: Row(
              children: <Widget>[
                Text('Aktivitas forum', style: AppTypography.titleMedium),
                const Spacer(),
                Text(
                  threads.valueOrNull == null
                      ? ''
                      : '${threads.valueOrNull!.length} topik',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),
          ...threads.when(
            loading: () => <Widget>[
              const Padding(
                padding: EdgeInsets.all(AppSpacing.l),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ],
            error: (error, stack) => <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(
                  'Aktivitas gagal dimuat. Tarik ke bawah untuk mencoba lagi.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
            data: (items) {
              if (items.isEmpty) {
                return <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Text(
                      'Belum menulis thread. Mulai diskusi di tab Forum.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ];
              }

              return <Widget>[
                for (final thread in items)
                  ForumThreadTile(
                    thread: thread,
                    onTap: () => context.push('/forum/${thread.id}'),
                  ),
              ];
            },
          ),
          const SizedBox(height: AppSpacing.l),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: AppColors.onSurfaceVariant,
            ),
            title: Text('Syarat Layanan', style: AppTypography.bodyMedium),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.onSurfaceVariant,
            ),
            title: Text('Kebijakan Privasi', style: AppTypography.bodyMedium),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/legal/privacy'),
          ),
          ListTile(
            leading: const Icon(
              Icons.public,
              color: AppColors.onSurfaceVariant,
            ),
            title: Text(
              'Sumber data: MangaDex',
              style: AppTypography.bodyMedium,
            ),
            subtitle: Text(
              'mangadex.org • penggunaan non-komersial',
              style: AppTypography.labelSmall,
            ),
            trailing: const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => launchUrl(
              Uri.parse('https://mangadex.org'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            child: Text(
              'Versi dokumen ${LegalContent.version}',
              style: AppTypography.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String name,
    String bio,
  ) async {
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _EditProfileDialog(initialName: name, initialBio: bio),
    );
    if (saved != true) return;

    ref.invalidate(currentProfileProvider);
    // Nama penulis ikut berubah di forum.
    ref.invalidate(forumThreadsProvider);
    ref.invalidate(forumThreadProvider);
    ref.invalidate(myForumThreadsProvider);
    ref.invalidate(followersProvider);
    ref.invalidate(followingProvider);
  }

  void _showFollowList(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required AutoDisposeFutureProvider<List<UserProfile>> provider,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _FollowListDialog(title: title, provider: provider),
    );
  }

  static String _nameFromUser(User user) {
    final dynamic meta = user.userMetadata;
    final dynamic fullName = meta?['full_name'] ?? meta?['name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final String? email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Pengguna Isekaiku';
  }

  static String? _avatarFromUser(User user) {
    final dynamic meta = user.userMetadata;
    final dynamic avatar = meta?['avatar_url'] ?? meta?['picture'];
    if (avatar is String && avatar.trim().isNotEmpty) return avatar.trim();
    return null;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(name);

    return Container(
      width: 84,
      height: 84,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: url == null
          ? Center(child: Text(initials, style: AppTypography.headlineSmall))
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: Text(initials, style: AppTypography.headlineSmall),
              ),
              errorWidget: (context, url, error) => Center(
                child: Text(initials, style: AppTypography.headlineSmall),
              ),
            ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          children: <Widget>[
            Text(value, style: AppTypography.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialBio,
  });

  final String initialName;
  final String initialBio;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _bio = TextEditingController(
    text: widget.initialBio,
  );

  String? _nameError;
  String? _bioError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? nameError = ProfileValidation.usernameError(_name.text);
    final String? bioError = ProfileValidation.bioError(_bio.text);

    setState(() {
      _nameError = nameError;
      _bioError = bioError;
      _error = null;
    });
    if (nameError != null || bioError != null) return;

    final String? userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      setState(() => _error = 'Sesi login berakhir.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(accountRepositoryProvider)
          .updateProfile(userId: userId, username: _name.text, bio: _bio.text);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      setState(() {
        _saving = false;
        _error = switch (error.code) {
          '23505' => 'Nama itu sudah dipakai. Pilih nama lain.',
          '23514' => 'Nama tidak memenuhi aturan. Coba nama lain.',
          _ => error.message,
        };
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Tidak bisa menyimpan. Periksa koneksi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Edit profil', style: AppTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: ProfileValidation.usernameMax,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nama tampilan',
                hintText: 'Mis. Budi Santoso',
                errorText: _nameError,
                helperText: 'Tampil di forum dan profil.',
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _bio,
              minLines: 3,
              maxLines: 5,
              maxLength: ProfileValidation.bioMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Ceritakan manga favoritmu…',
                errorText: _bioError,
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s),
              Text(
                _error!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan…' : 'Simpan'),
        ),
      ],
    );
  }
}

class _FollowListDialog extends ConsumerWidget {
  const _FollowListDialog({required this.title, required this.provider});

  final String title;
  final AutoDisposeFutureProvider<List<UserProfile>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UserProfile>> users = ref.watch(provider);

    return AlertDialog(
      title: Text(title, style: AppTypography.titleMedium),
      content: SizedBox(
        width: 360,
        height: 360,
        child: users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Gagal memuat daftar.', style: AppTypography.bodySmall),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'Belum ada pengguna.',
                  style: AppTypography.bodySmall,
                ),
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final UserProfile user = items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ForumAvatar(name: user.displayName, size: 34),
                  title: Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxl),
        const Icon(
          Icons.account_circle_outlined,
          size: 64,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Masuk untuk profil komunitas',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Dengan akun Google, kamu bisa menulis thread di forum, mengikuti '
          'pembaca lain, dan menyinkronkan Pustaka antar perangkat.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.l),
        FilledButton.icon(
          onPressed: () => showAccountDialog(context),
          icon: const Icon(Icons.login, size: 18),
          label: const Text('Masuk dengan Google'),
        ),
        const SizedBox(height: AppSpacing.l),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.description_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          title: Text('Syarat Layanan', style: AppTypography.bodyMedium),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const TermsPage()),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          title: Text('Kebijakan Privasi', style: AppTypography.bodyMedium),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const PrivacyPage()),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.public, color: AppColors.onSurfaceVariant),
          title: Text('Sumber data: MangaDex', style: AppTypography.bodyMedium),
          subtitle: Text(
            'mangadex.org • penggunaan non-komersial',
            style: AppTypography.labelSmall,
          ),
          trailing: const Icon(
            Icons.open_in_new,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          onTap: () => launchUrl(
            Uri.parse('https://mangadex.org'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}

class _AccountUnavailable extends StatelessWidget {
  const _AccountUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Akun', style: AppTypography.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.account_circle_outlined,
              size: 56,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Akun belum aktif',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Profil komunitas membutuhkan koneksi Supabase. Fitur baca dan '
              'Pustaka lokal tetap berjalan.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
