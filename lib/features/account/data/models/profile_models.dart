/// Model profil publik pengguna.
library;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.bio = '',
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String bio;
  final String? avatarUrl;

  String get displayName =>
      username.trim().isEmpty ? 'Pengguna Isekaiku' : username.trim();

  /// `null` bila baris tidak lengkap.
  static UserProfile? tryFromRow(Map<String, dynamic> row) {
    final dynamic id = row['id'];
    if (id is! String) return null;

    final dynamic username = row['username'];
    final dynamic bio = row['bio'];
    final dynamic avatar = row['avatar_url'];

    return UserProfile(
      id: id,
      username: username is String ? username : '',
      bio: bio is String ? bio : '',
      avatarUrl: avatar is String && avatar.trim().isNotEmpty
          ? avatar.trim()
          : null,
    );
  }
}

/// Jumlah pengikut dan yang diikuti.
class ProfileStats {
  const ProfileStats({required this.followers, required this.following});

  final int followers;
  final int following;

  static const ProfileStats empty = ProfileStats(followers: 0, following: 0);
}
