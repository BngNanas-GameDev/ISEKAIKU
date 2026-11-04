import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/forum_validation.dart';
import '../data/models/forum_models.dart';
import '../forum_providers.dart';
import 'widgets/forum_widgets.dart';

/// Formulir topik baru.
class ForumComposePage extends ConsumerStatefulWidget {
  const ForumComposePage({super.key});

  @override
  ConsumerState<ForumComposePage> createState() => _ForumComposePageState();
}

class _ForumComposePageState extends ConsumerState<ForumComposePage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  ForumCategory _category = ForumCategory.umum;
  String? _titleError;
  String? _bodyError;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? titleError = ForumValidation.titleError(_title.text);
    final String? bodyError = ForumValidation.bodyError(_body.text);

    setState(() {
      _titleError = titleError;
      _bodyError = bodyError;
      _error = null;
    });
    if (titleError != null || bodyError != null) return;

    final String? userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      setState(() => _error = 'Sesi login berakhir. Masuk lagi untuk menulis.');
      return;
    }

    setState(() => _sending = true);
    try {
      final String threadId = await ref
          .read(forumRepositoryProvider)
          .createThread(
            userId: userId,
            category: _category,
            title: _title.text,
            body: _body.text,
          );

      ref.invalidate(forumThreadsProvider);
      if (!mounted) return;
      context.pushReplacement('/forum/$threadId');
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Tidak bisa mengirim topik. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Topik baru', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: <Widget>[
          Text('Kategori', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: <Widget>[
              for (final ForumCategory category in ForumCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: _category == category,
                  showCheckmark: false,
                  avatar: CircleAvatar(
                    radius: 4,
                    backgroundColor: forumCategoryColor(category),
                  ),
                  labelStyle: AppTypography.labelSmall.copyWith(
                    color: _category == category
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _title,
            maxLength: ForumValidation.titleMaxLength,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Judul',
              hintText: 'Mis. Rekomendasi manga isekai selain Frieren',
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _body,
            minLines: 8,
            maxLines: null,
            maxLength: ForumValidation.bodyMaxLength,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Isi topik',
              hintText: 'Tulis detailnya di sini…',
              errorText: _bodyError,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Tautan eksternal, promosi judi, dan konten narkoba akan ditolak '
            'otomatis. Hormati sesama pembaca.',
            style: AppTypography.labelSmall,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            Text(
              _error!,
              style: AppTypography.labelSmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(_sending ? 'Mengirim…' : 'Kirim topik'),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}
