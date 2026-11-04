import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
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

  return ref
      .watch(forumRepositoryProvider)
      .threads(category: category, sort: sort);
});

/// Satu topik beserta balasannya.
final forumThreadProvider = FutureProvider.autoDispose
    .family<ForumThreadDetail?, String>((ref, threadId) {
      return ref.watch(forumRepositoryProvider).thread(threadId);
    });
