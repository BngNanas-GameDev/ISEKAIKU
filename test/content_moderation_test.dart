import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/moderation/content_moderation.dart';

void main() {
  group('konten wajar', () {
    test('komentar biasa diizinkan', () {
      final result = ContentModeration.check(
        'Manga ini bagus banget, art-nya keren dan ceritanya rapi.',
      );
      expect(result.allowed, isTrue);
      expect(result.violation, isNull);
    });

    test('angka dan tanda baca wajar diizinkan', () {
      expect(ContentModeration.check('Chapter 12 mantap! 9/10').allowed, isTrue);
    });
  });

  group('aturan 1: tautan eksternal', () {
    test('URL lengkap ditolak', () {
      final result = ContentModeration.check('baca di https://situs.com/x');
      expect(result.allowed, isFalse);
      expect(result.violation, ModerationViolation.externalLink);
      expect(result.message, ContentModeration.messageLink);
    });

    test('domain telanjang ditolak', () {
      expect(
        ContentModeration.check('sumbernya di contoh.co id').violation,
        ModerationViolation.externalLink,
      );
      expect(
        ContentModeration.check('ada di www.toko.net').violation,
        ModerationViolation.externalLink,
      );
    });

    test('obfuscation [.] dan dot com ditolak', () {
      expect(
        ContentModeration.check('cek contoh[.]com ya').violation,
        ModerationViolation.externalLink,
      );
      expect(
        ContentModeration.check('lihat contoh dot com').violation,
        ModerationViolation.externalLink,
      );
    });

    test('tautan pesan dan shortlink ditolak', () {
      expect(
        ContentModeration.check('gabung t.me/grupnya').violation,
        ModerationViolation.externalLink,
      );
      expect(
        ContentModeration.check('pakai bit.ly/abc').violation,
        ModerationViolation.externalLink,
      );
    });
  });

  group('aturan 2: judi online', () {
    test('kata kunci judi ditolak', () {
      expect(
        ContentModeration.check('slot gacor hari ini').violation,
        ModerationViolation.gambling,
      );
      expect(
        ContentModeration.check('cari maxwin di togel').violation,
        ModerationViolation.gambling,
      );
    });

    test('leetspeak dan spasi tetap tertangkap', () {
      expect(
        ContentModeration.check('SL0T G4C0R').violation,
        ModerationViolation.gambling,
      );
      expect(
        ContentModeration.check('g a c o r bgt').violation,
        ModerationViolation.gambling,
      );
      expect(
        ContentModeration.check('gaccor').violation,
        ModerationViolation.gambling,
      );
    });
  });

  group('aturan 3: narkoba', () {
    test('kata kunci narkoba ditolak', () {
      expect(
        ContentModeration.check('ada yang jual sabu?').violation,
        ModerationViolation.drugs,
      );
      expect(
        ContentModeration.check('NARKOBA itu berbahaya').violation,
        ModerationViolation.drugs,
      );
      expect(
        ContentModeration.check('ganja kering').violation,
        ModerationViolation.drugs,
      );
    });
  });

  group('validasi dasar', () {
    test('komentar kosong ditolak', () {
      final result = ContentModeration.check('   ');
      expect(result.allowed, isFalse);
      expect(result.violation, ModerationViolation.invalid);
      expect(result.message, ContentModeration.messageEmpty);
    });

    test('komentar terlalu panjang ditolak', () {
      final result = ContentModeration.check('a' * (ContentModeration.maxLength + 1));
      expect(result.allowed, isFalse);
      expect(result.violation, ModerationViolation.invalid);
      expect(result.message, ContentModeration.messageTooLong);
    });
  });

  group('detail', () {
    test('matched berisi pemicu untuk log moderator', () {
      final result = ContentModeration.check('promo gacor');
      expect(result.matched, 'gacor');
    });

    test('teks normal yang mengandung kata mirip tidak ditolak', () {
      // "deposit" memang masuk daftar judi, tetapi "komik" tidak boleh
      // ikut tertolak hanya karena mengandung "omik".
      expect(ContentModeration.check('komik favoritku').allowed, isTrue);
    });
  });
}
