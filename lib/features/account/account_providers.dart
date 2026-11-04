import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../library/library_providers.dart';
import 'data/account_repository.dart';
import 'data/models/profile_models.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(supabaseClientProvider)),
);

/// Profil pengguna yang sedang masuk.
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(accountRepositoryProvider).profile(user.id);
});

/// Jumlah pengikut + mengikuti seorang pengguna.
final profileStatsProvider = FutureProvider.autoDispose
    .family<ProfileStats, String>((ref, userId) {
      return ref.watch(accountRepositoryProvider).stats(userId);
    });

/// Apakah pengguna saat ini mengikuti [targetId].
final isFollowingUserProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, targetId) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.id == targetId) return false;
    return ref.watch(accountRepositoryProvider).isFollowing(user.id, targetId);
  },
);

final followersProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, userId) {
      return ref.watch(accountRepositoryProvider).followers(userId);
    });

final followingProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, userId) {
      return ref.watch(accountRepositoryProvider).following(userId);
    });

/// Jumlah manga yang pernah dibaca (gabungan chapter terbaca + riwayat).
final readMangaCountProvider = Provider<int>((ref) {
  final read = ref.watch(readChaptersProvider);
  final history = ref.watch(readingHistoryProvider);

  final ids = <String>{...read.keys};
  for (final entry in history) {
    ids.add(entry.mangaId);
  }
  return ids.length;
});
