import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../account/presentation/account_dialog.dart';
import '../data/forum_format.dart';
import '../data/forum_validation.dart';
import '../data/models/forum_models.dart';
import '../forum_providers.dart';
import 'widgets/forum_widgets.dart';

/// Detail satu topik + balasan.
class ForumThreadPage extends ConsumerStatefulWidget {
  const ForumThreadPage({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends ConsumerState<ForumThreadPage> {
  final TextEditingController _reply = TextEditingController();
  final TextEditingController _reportReason = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _replyFocus = FocusNode();

  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    _reportReason.dispose();
    _scroll.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ForumThreadDetail?> detail = ref.watch(
      forumThreadProvider(widget.threadId),
    );
    final User? user = ref.watch(currentUserProvider);
    final ForumThread? thread = detail.valueOrNull?.thread;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Diskusi', style: AppTypography.titleLarge),
        actions: <Widget>[
          if (thread != null)
            PopupMenuButton<String>(
              tooltip: 'Opsi topik',
              onSelected: (value) {
                if (value == 'report') {
                  _report('thread', thread.id);
                } else if (value == 'delete') {
                  _deleteThread();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                if (user != null)
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Laporkan topik'),
                  ),
                if (user?.id == thread.authorId)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Hapus topik'),
                  ),
              ],
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ThreadError(
          onRetry: () => ref.invalidate(forumThreadProvider(widget.threadId)),
        ),
        data: (value) {
          if (value == null) {
            return const _ThreadMissing();
          }
          return _buildThread(value, user);
        },
      ),
      bottomNavigationBar: thread == null ? null : _buildReplyBar(thread, user),
    );
  }

  Widget _buildThread(ForumThreadDetail detail, User? user) {
    final ForumThread thread = detail.thread;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(forumThreadProvider(widget.threadId).future),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: <Widget>[
          _ThreadHeader(thread: thread),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.s,
            ),
            child: Text(
              'Balasan (${detail.posts.length})',
              style: AppTypography.labelLarge,
            ),
          ),
          if (detail.posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Text(
                'Belum ada balasan. Jadi yang pertama menanggapi.',
                style: AppTypography.bodySmall,
              ),
            )
          else
            for (final ForumPost post in detail.posts)
              _PostTile(
                post: post,
                canDelete: user?.id == post.authorId,
                onReport: user == null ? null : () => _report('post', post.id),
                onDelete: user?.id == post.authorId
                    ? () => _deletePost(post)
                    : null,
              ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(ForumThread thread, User? user) {
    if (thread.isLocked) {
      return _BottomBar(
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.lock_outline,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                'Topik dikunci. Balasan baru tidak bisa ditambahkan.',
                style: AppTypography.labelSmall,
              ),
            ),
          ],
        ),
      );
    }

    if (user == null) {
      return _BottomBar(
        child: FilledButton.icon(
          onPressed: () => showAccountDialog(context),
          icon: const Icon(Icons.login, size: 18),
          label: const Text('Masuk untuk membalas'),
        ),
      );
    }

    return _BottomBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _reply,
              focusNode: _replyFocus,
              minLines: 1,
              maxLines: 4,
              maxLength: ForumValidation.bodyMaxLength,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Tulis balasan…',
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          IconButton.filled(
            tooltip: 'Kirim balasan',
            onPressed: _sending ? null : _sendReply,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final String? error = ForumValidation.bodyError(_reply.text);
    if (error != null) {
      _snack(error);
      return;
    }

    final String? userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      _snack('Masuk dulu untuk membalas.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(forumRepositoryProvider)
          .createPost(
            userId: userId,
            threadId: widget.threadId,
            body: _reply.text,
          );

      _reply.clear();
      ref.invalidate(forumThreadProvider(widget.threadId));
      ref.invalidate(forumThreadsProvider);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } on PostgrestException catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack('Balasan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteThread() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus topik?'),
        content: const Text(
          'Topik beserta seluruh balasannya akan dihapus permanen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(forumRepositoryProvider).deleteThread(widget.threadId);
      ref.invalidate(forumThreadsProvider);
      if (mounted) context.pop();
    } catch (_) {
      _snack('Topik gagal dihapus. Coba lagi.');
    }
  }

  Future<void> _deletePost(ForumPost post) async {
    try {
      await ref.read(forumRepositoryProvider).deletePost(post.id);
      ref.invalidate(forumThreadProvider(widget.threadId));
      ref.invalidate(forumThreadsProvider);
    } catch (_) {
      _snack('Balasan gagal dihapus. Coba lagi.');
    }
  }

  Future<void> _report(String targetType, String targetId) async {
    _reportReason.clear();
    bool sending = false;
    String? error;

    final bool? sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Laporkan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ceritakan singkat masalahnya. Laporan akan ditinjau '
                  'moderator.',
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _reportReason,
                  maxLength: ForumValidation.reasonMaxLength,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Alasan',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final String? invalid = ForumValidation.reasonError(
                          _reportReason.text,
                        );
                        if (invalid != null) {
                          setDialogState(() => error = invalid);
                          return;
                        }

                        setDialogState(() {
                          sending = true;
                          error = null;
                        });
                        try {
                          await ref
                              .read(forumRepositoryProvider)
                              .report(
                                targetType: targetType,
                                targetId: targetId,
                                reason: _reportReason.text,
                              );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } on PostgrestException catch (exception) {
                          setDialogState(() {
                            sending = false;
                            error = exception.message;
                          });
                        } catch (_) {
                          setDialogState(() {
                            sending = false;
                            error = 'Laporan gagal dikirim. Coba lagi.';
                          });
                        }
                      },
                child: Text(sending ? 'Mengirim…' : 'Kirim'),
              ),
            ],
          );
        },
      ),
    );

    if (sent == true) {
      _snack('Laporan terkirim. Terima kasih.');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.thread});

  final ForumThread thread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
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
                ForumFormat.relative(thread.createdAt),
                style: AppTypography.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SelectableText(thread.title, style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: <Widget>[
              ForumAvatar(name: thread.authorName, size: 28),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  thread.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge,
                ),
              ),
              if (thread.isLocked)
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          SelectableText(thread.body, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.canDelete,
    this.onReport,
    this.onDelete,
  });

  final ForumPost post;
  final bool canDelete;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.s,
        AppSpacing.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ForumAvatar(name: post.authorName, size: 32),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge,
                      ),
                    ),
                    Text(
                      ForumFormat.relative(post.createdAt),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(post.body, style: AppTypography.bodyMedium),
              ],
            ),
          ),
          if (onReport != null || onDelete != null)
            SizedBox(
              width: 32,
              height: 32,
              child: PopupMenuButton<String>(
                tooltip: 'Opsi balasan',
                padding: EdgeInsets.zero,
                iconSize: 18,
                onSelected: (value) {
                  if (value == 'report') {
                    onReport?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  if (onReport != null)
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Text('Laporkan'),
                    ),
                  if (canDelete && onDelete != null)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Hapus balasan'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.s,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: child,
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Diskusi gagal dimuat. Periksa koneksi.',
              textAlign: TextAlign.center,
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

class _ThreadMissing extends StatelessWidget {
  const _ThreadMissing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Text(
          'Topik ini sudah dihapus atau disembunyikan moderator.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}
