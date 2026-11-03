/// Filter konten untuk ruang diskusi (komentar/forum).
///
/// Aturan yang ditegakkan:
/// 1. Tidak boleh menyertakan tautan eksternal
/// 2. Tidak boleh promosi judi online
/// 3. Tidak boleh konten narkoba
///
/// Catatan penting:
/// - Ini lapisan **klien** untuk umpan balik instan. Penegakan sebenarnya
///   harus di server (trigger Postgres / Edge Function), karena klien bisa
///   dimodifikasi.
/// - Filter kata kunci selalu bisa diakali. Di sini dinormalisasi sederhana:
///   huruf kecil, leetspeak umum, huruf berulang, dan semua pemisah dibuang.
/// - Untuk diskusi sah tentang topik sensitif, filter bisa menghasilkan
///   positif palsu. Jika mengganggu, persempit jadi pola promosi
///   (mis. "jual", "stok", "order").
library;

enum ModerationViolation {
  invalid,
  externalLink,
  gambling,
  drugs,
}

class ModerationResult {
  const ModerationResult._({
    required this.allowed,
    this.violation,
    this.message,
    this.matched,
  });

  const ModerationResult.allowed() : this._(allowed: true);

  const ModerationResult.blocked(
    ModerationViolation violation,
    String message, {
    String? matched,
  }) : this._(
          allowed: false,
          violation: violation,
          message: message,
          matched: matched,
        );

  final bool allowed;
  final ModerationViolation? violation;

  /// Pesan siap tampil ke pengguna.
  final String? message;

  /// Potongan teks yang memicu (untuk log moderator).
  final String? matched;
}

class ContentModeration {
  const ContentModeration._();

  /// Panjang maksimum satu komentar.
  static const int maxLength = 1000;

  static const String messageLink = 'Tautan eksternal tidak diizinkan.';
  static const String messageGambling = 'Konten terkait judi online dilarang.';
  static const String messageDrugs = 'Konten terkait narkoba dilarang.';
  static const String messageTooLong =
      'Komentar terlalu panjang (maksimum $maxLength karakter).';
  static const String messageEmpty = 'Komentar tidak boleh kosong.';

  // --- 1. Tautan eksternal --------------------------------------------

  /// Mendeteksi URL lengkap, domain telanjang, dan trik obfuscation umum
  /// seperti `[.]`, `(.)`, atau "dot com".
  static final RegExp _urlPattern = RegExp(
    r'(https?:\/\/|hxxps?:\/\/|www\.)'
    r'|\[\.\]|\(\.\)|\{\.\}'
    r'|\bdot\s+(com|net|org|id|xyz|me|tv|link|site|online|store|shop)\b'
    r'|\b(t\.me|wa\.me|bit\.ly|tinyurl|linktr\.ee|discord\.gg|s\.id'
    r'|rebrand\.ly|cutt\.ly|shorturl|is\.gd)\b'
    r'|\b[a-z0-9][a-z0-9-]{0,62}\.'
    r'(com|net|org|id|xyz|me|tv|link|site|online|store|shop|info|biz'
    r'|ru|cc|io|co|ly|to|app|dev|pro|my|sg|fun|live|top|club|vip)\b',
    caseSensitive: false,
  );

  // --- 2. Judi online -------------------------------------------------

  static const List<String> _gamblingWords = <String>[
    'judol',
    'judi',
    'judionline',
    'slot',
    'slot88',
    'slotgacor',
    'gacor',
    'maxwin',
    'scatter',
    'togel',
    'toto',
    'bandar',
    'bandarq',
    'casino',
    'kasino',
    'sbobet',
    'pragmatic',
    'zeus',
    'olympus',
    'mahjongways',
    'rtp',
    'deposit',
    'depo',
    'taruhan',
    'betting',
    'parlay',
    'jackpot',
    'bonusnewmember',
    'linkalternatif',
    'situsjudol',
  ];

  // --- 3. Narkoba -----------------------------------------------------

  static const List<String> _drugWords = <String>[
    'narkoba',
    'narkotika',
    'narkotik',
    'sabu',
    'shabu',
    'ganja',
    'marijuana',
    'kanabis',
    'cannabis',
    'ekstasi',
    'ecstasy',
    'heroin',
    'kokain',
    'cocaine',
    'morfin',
    'opium',
    'psikotropika',
    'tembakaugorila',
    'obatterlarang',
    'jualobat',
    'dmt',
    'lsd',
  ];

  /// Periksa [text]. `allowed == false` berarti harus ditolak.
  static ModerationResult check(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const ModerationResult.blocked(
        ModerationViolation.invalid,
        messageEmpty,
      );
    }
    if (trimmed.length > maxLength) {
      return const ModerationResult.blocked(
        ModerationViolation.invalid,
        messageTooLong,
      );
    }

    // 1. Tautan eksternal — diperiksa pada teks asli supaya domain yang sah
    //    tetap terdeteksi sebelum normalisasi.
    final link = _urlPattern.firstMatch(trimmed);
    if (link != null) {
      return ModerationResult.blocked(
        ModerationViolation.externalLink,
        messageLink,
        matched: link.group(0),
      );
    }

    final compact = _compact(trimmed);

    for (final word in _gamblingWords) {
      if (compact.contains(word)) {
        return ModerationResult.blocked(
          ModerationViolation.gambling,
          messageGambling,
          matched: word,
        );
      }
    }

    for (final word in _drugWords) {
      if (compact.contains(word)) {
        return ModerationResult.blocked(
          ModerationViolation.drugs,
          messageDrugs,
          matched: word,
        );
      }
    }

    return const ModerationResult.allowed();
  }

  /// Normalisasi untuk pencocokan kata:
  /// huruf kecil → leetspeak → aksen → huruf berulang → buang pemisah.
  static String _compact(String input) {
    var value = input.toLowerCase();

    const Map<String, String> leet = <String, String>{
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '8': 'b',
      '9': 'g',
    };
    value = value.split('').map((c) => leet[c] ?? c).join();

    const Map<String, String> accents = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'í': 'i',
      'ì': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    value = value.split('').map((c) => accents[c] ?? c).join();

    // Huruf berulang 2+ kali → satu huruf ("gaccor" / "gaacor" → "gacor").
    value = value.replaceAllMapped(
      RegExp(r'(.)\1+'),
      (match) => match.group(1)!,
    );

    // Buang semua yang bukan huruf/angka, agar "g a c o r" tetap tertangkap.
    return value.replaceAll(RegExp('[^a-z0-9]'), '');
  }
}
