import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/images/cover_image.dart';

void main() {
  group('hemat data sampul', () {
    const String base =
        'https://uploads.mangadex.org/covers/abc/def.512.jpg';

    test('tanpa hemat data memakai URL asli', () {
      expect(coverUrlFor(base, dataSaver: false), base);
    });

    test('hemat data menurunkan 512 ke 256', () {
      expect(
        coverUrlFor(base, dataSaver: true),
        'https://uploads.mangadex.org/covers/abc/def.256.jpg',
      );
    });

    test('ukuran 1024 juga diturunkan', () {
      expect(
        coverUrlFor(
          'https://uploads.mangadex.org/covers/abc/def.1024.png',
          dataSaver: true,
        ),
        'https://uploads.mangadex.org/covers/abc/def.256.png',
      );
    });

    test('URL 256 tetap 256', () {
      const String small =
          'https://uploads.mangadex.org/covers/abc/def.256.jpg';
      expect(coverUrlFor(small, dataSaver: true), small);
    });

    test('URL tanpa pola tidak berubah', () {
      const String other = 'https://example.com/cover.jpg';
      expect(coverUrlFor(other, dataSaver: true), other);
    });

    test('null dan string kosong aman', () {
      expect(coverUrlFor(null, dataSaver: true), isNull);
      expect(coverUrlFor('', dataSaver: true), '');
    });
  });
}
