import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../account/account_providers.dart';
import 'data/forum_repository.dart';
import 'data/models/forum_models.dart';

final forumRepositoryProvider = Provider<ForumRepository>(
  (ref) => ForumRepository(ref.watch(supabaseClientProvider)),
);

/// Filter kategori; `null` berarti semua kategori.
final forumCategoryFilterProvider = StateProvider<ForumCategory?>(
  (ref) => null,
);

final forumSortProvider = StateProvider<ForumSort>((ref) => ForumSort.terbaru);

/// Daftar topik sesuai filter aktif.
final forumThreadsProvider = FutureProvider.autoDispose<List<ForumThread>>((
  ref,
) async {
  final category = ref.watch(forumCategoryFilterProvider);
  final sort = ref.watch(forumSortProvider);
  final blocked = await ref.watch(blockedUserIdsProvider.future);

  return ref
      .watch(forumRepositoryProvider)
      .threads(category: category, sort: sort, blockedUserIds: blocked);
});

/// Satu topik beserta balasannya.
final forumThreadProvider = FutureProvider.autoDispose
    .family<ForumThreadDetail?, String>((ref, threadId) async {
      final blocked = await ref.watch(blockedUserIdsProvider.future);
      return ref
          .watch(forumRepositoryProvider)
          .thread(threadId, blockedUserIds: blocked);
    });

/// Topik yang ditulis pengguna saat ini (tab Akun).
final myForumThreadsProvider = FutureProvider.autoDispose<List<ForumThread>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const <ForumThread>[];
  return ref.watch(forumRepositoryProvider).threadsByAuthor(user.id);
});
