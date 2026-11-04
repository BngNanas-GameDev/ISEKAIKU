/// Model profil publik pengguna.
library;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.bio = '',
    this.avatarUrl,
    this.birthDate,
    this.birthDateKnown = true,
  });

  final String id;
  final String username;
  final String bio;
  final String? avatarUrl;

  /// Tanggal lahir (sekali isi, tidak bisa diubah).
  final DateTime? birthDate;

  /// False bila kolom `birth_date` belum ada di server (migrasi belum jalan),
  /// sehingga aplikasi tidak memaksa pengisian yang pasti gagal.
  final bool birthDateKnown;

  bool get hasBirthDate => birthDate != null;

  String get displayName =>
      username.trim().isEmpty ? 'Pengguna Isekaiku' : username.trim();

  /// `null` bila baris tidak lengkap.
  static UserProfile? tryFromRow(Map<String, dynamic> row) {
    final dynamic id = row['id'];
    if (id is! String) return null;

    final dynamic username = row['username'];
    final dynamic bio = row['bio'];
    final dynamic avatar = row['avatar_url'];
    final dynamic birth = row['birth_date'];

    return UserProfile(
      id: id,
      username: username is String ? username : '',
      bio: bio is String ? bio : '',
      avatarUrl: avatar is String && avatar.trim().isNotEmpty
          ? avatar.trim()
          : null,
      birthDate: birth is String ? DateTime.tryParse(birth) : null,
      birthDateKnown: row.containsKey('birth_date'),
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
