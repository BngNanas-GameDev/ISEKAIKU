import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profile_models.dart';

/// Profil publik + hubungan pengikut.
///
/// Semua penulisan mengandalkan RLS: pengguna hanya bisa mengubah profilnya
/// sendiri dan hanya bisa follow/unfollow atas namanya sendiri.
class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile?> profile(String userId) async {
    final profiles = await _profiles(<String>[userId]);
    return profiles.isEmpty ? null : profiles.first;
  }

  /// Ubah nickname dan bio sekaligus.
  ///
  /// Keunikan nickname dijaga index `lower(username)` di server; bentrok
  /// muncul sebagai error 23505.
  Future<void> updateProfile({
    required String userId,
    required String username,
    required String bio,
  }) async {
    await _client
        .from('profiles')
        .update(<String, dynamic>{
          'username': username.trim(),
          'bio': bio.trim(),
        })
        .eq('id', userId);
  }

  /// Isi tanggal lahir sekali. Server menolak perubahan berikutnya.
  Future<void> updateBirthDate(String userId, DateTime date) async {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String value = "${date.year.toString().padLeft(4, '0')}-$month-$day";

    await _client
        .from('profiles')
        .update(<String, dynamic>{'birth_date': value})
        .eq('id', userId);
  }

  Future<ProfileStats> stats(String userId) async {
    final followers = await _followIds(
      select: 'follower_id',
      filterColumn: 'following_id',
      userId: userId,
    );
    final following = await _followIds(
      select: 'following_id',
      filterColumn: 'follower_id',
      userId: userId,
    );

    return ProfileStats(
      followers: followers.length,
      following: following.length,
    );
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    if (followerId == followingId) return false;

    final row = await _client
        .from('user_follows')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow(String followerId, String followingId) async {
    if (followerId == followingId) return;

    await _client.from('user_follows').upsert(<String, dynamic>{
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollow(String followerId, String followingId) async {
    await _client
        .from('user_follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  /// Daftar id pengguna yang diblokir (untuk menyaring forum).
  Future<Set<String>> blockedUserIds(String userId) async {
    final rows = await _client
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', userId);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row['blocked_user_id'])
        .whereType<String>()
        .toSet();
  }

  Future<List<UserProfile>> blockedUsers(String userId) async {
    final ids = (await blockedUserIds(userId)).toList(growable: false);
    return _profiles(ids);
  }

  Future<void> blockUser(String userId, String blockedId) async {
    if (userId == blockedId) return;

    await _client.from('user_blocks').upsert(<String, dynamic>{
      'user_id': userId,
      'blocked_user_id': blockedId,
    });
  }

  Future<void> unblockUser(String userId, String blockedId) async {
    await _client
        .from('user_blocks')
        .delete()
        .eq('user_id', userId)
        .eq('blocked_user_id', blockedId);
  }

  Future<List<UserProfile>> followers(String userId) async {
    final ids = await _followIds(
      select: 'follower_id',
      filterColumn: 'following_id',
      userId: userId,
    );
    return _profiles(ids);
  }

  Future<List<UserProfile>> following(String userId) async {
    final ids = await _followIds(
      select: 'following_id',
      filterColumn: 'follower_id',
      userId: userId,
    );
    return _profiles(ids);
  }

  Future<List<String>> _followIds({
    required String select,
    required String filterColumn,
    required String userId,
  }) async {
    final rows = await _client
        .from('user_follows')
        .select(select)
        .eq(filterColumn, userId);

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row[select])
        .whereType<String>()
        .toList(growable: false);
  }

  /// Ambil profil. Bila kolom bio/avatar belum ada (migrasi 0003 belum
  /// dijalankan), jatuh ke kolom lama supaya halaman tetap terbuka.
  Future<List<UserProfile>> _profiles(List<String> ids) async {
    if (ids.isEmpty) return const <UserProfile>[];

    List<dynamic> rows;
    try {
      rows = await _client
          .from('profiles')
          .select('id, username, bio, avatar_url, birth_date')
          .inFilter('id', ids);
    } on PostgrestException {
      rows = await _client
          .from('profiles')
          .select('id, username')
          .inFilter('id', ids);
    }

    return rows
        .cast<Map<String, dynamic>>()
        .map(UserProfile.tryFromRow)
        .whereType<UserProfile>()
        .toList(growable: false);
  }
}
