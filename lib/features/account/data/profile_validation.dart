/// Validasi nickname dan bio profil.
///
/// Server tetap menegakkan aturan (constraint + index unik); ini untuk
/// umpan balik instan sebelum request dikirim.
abstract class ProfileValidation {
  const ProfileValidation._();

  static const int usernameMin = 3;
  static const int usernameMax = 24;
  static const int bioMax = 160;

  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ._-]*$');
  static final RegExp _doubleSpace = RegExp(r'\s{2,}');

  /// Pesan kesalahan nickname, atau `null` bila valid.
  static String? usernameError(String value) {
    final String name = value.trim();
    if (name.length < usernameMin) {
      return 'Nama minimal $usernameMin karakter.';
    }
    if (name.length > usernameMax) {
      return 'Nama maksimal $usernameMax karakter.';
    }
    if (!_allowed.hasMatch(name)) {
      return 'Gunakan huruf, angka, spasi, titik, garis bawah, atau '
          'tanda hubung.';
    }
    if (_doubleSpace.hasMatch(name)) {
      return 'Hindari spasi ganda.';
    }
    return null;
  }

  /// Pesan kesalahan bio, atau `null` bila valid.
  static String? bioError(String value) {
    if (value.trim().length > bioMax) {
      return 'Bio maksimal $bioMax karakter.';
    }
    return null;
  }
}
