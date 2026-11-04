import '../../../core/moderation/content_moderation.dart';

/// Validasi isi forum sebelum dikirim ke server.
///
/// Server tetap punya `check` constraint sendiri; ini untuk umpan balik
/// instan supaya pengguna tidak menunggu perjalanan jaringan.
abstract class ForumValidation {
  const ForumValidation._();

  static const int titleMinLength = 5;
  static const int titleMaxLength = 120;
  static const int bodyMaxLength = 5000;
  static const int reasonMinLength = 3;
  static const int reasonMaxLength = 300;

  /// Pesan kesalahan judul, atau `null` bila valid.
  static String? titleError(String value) {
    final title = value.trim();
    if (title.isEmpty) return 'Judul tidak boleh kosong.';
    if (title.length < titleMinLength) {
      return 'Judul minimal $titleMinLength karakter.';
    }
    if (title.length > titleMaxLength) {
      return 'Judul maksimal $titleMaxLength karakter.';
    }

    // Judul juga ikut difilter (mis. tautan/judi di judul).
    return _moderationError(title);
  }

  /// Pesan kesalahan isi topik/balasan, atau `null` bila valid.
  static String? bodyError(String value) {
    final body = value.trim();
    if (body.isEmpty) return 'Isi tidak boleh kosong.';
    if (body.length > bodyMaxLength) {
      return 'Isi maksimal $bodyMaxLength karakter.';
    }

    return _moderationError(body);
  }

  /// Pesan kesalahan alasan laporan, atau `null` bila valid.
  static String? reasonError(String value) {
    final reason = value.trim();
    if (reason.length < reasonMinLength) {
      return 'Alasan minimal $reasonMinLength karakter.';
    }
    if (reason.length > reasonMaxLength) {
      return 'Alasan maksimal $reasonMaxLength karakter.';
    }
    return null;
  }

  static String? _moderationError(String text) {
    final result = ContentModeration.check(text, maxLength: bodyMaxLength);
    return result.allowed ? null : result.message;
  }
}
