import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isekaiku/core/network/doh/doh_resolver.dart';

void main() {
  group('parseDohAnswer', () {
    test('mengambil record A dan TTL', () {
      const body = '''
{
  "Status": 0,
  "Answer": [
    {"name": "api.mangadex.org", "type": 1, "TTL": 120, "data": "104.26.10.5"},
    {"name": "api.mangadex.org", "type": 1, "TTL": 300, "data": "104.26.11.5"},
    {"name": "api.mangadex.org", "type": 28, "TTL": 60, "data": "2606:4700::1"}
  ]
}
''';

      final DohAnswer answer = parseDohAnswer(body);

      expect(answer.addresses, hasLength(2));
      expect(answer.addresses.first, InternetAddress('104.26.10.5'));
      expect(answer.addresses.last, InternetAddress('104.26.11.5'));
      // TTL terkecil dipakai sebagai batas cache.
      expect(answer.ttl, const Duration(seconds: 120));
    });

    test('mengabaikan record non-A', () {
      const body = '''
{"Status": 0, "Answer": [{"type": 28, "TTL": 300, "data": "2606:4700::1"}]}
''';

      final DohAnswer answer = parseDohAnswer(body);

      expect(answer.isEmpty, isTrue);
      expect(answer.ttl, const Duration(minutes: 5));
    });

    test('jawaban tanpa Answer dianggap kosong', () {
      const body = '{"Status": 3}';
      final DohAnswer answer = parseDohAnswer(body);
      expect(answer.isEmpty, isTrue);
    });

    test('payload bukan JSON melempar FormatException', () {
      expect(() => parseDohAnswer('<html>blocked</html>'),
          throwsA(isA<FormatException>()));
    });

    test('data IP tidak valid dilewati', () {
      const body = '''
{"Answer": [{"type": 1, "TTL": 300, "data": "bukan-ip"}]}
''';
      final DohAnswer answer = parseDohAnswer(body);
      expect(answer.isEmpty, isTrue);
    });
  });

  group('DohProvider.queryUri', () {
    test('membangun URL Cloudflare dengan parameter benar', () {
      final DohProvider provider = defaultDohProviders.first;
      final Uri uri = provider.queryUri('api.mangadex.org');

      expect(uri.scheme, 'https');
      expect(uri.host, 'cloudflare-dns.com');
      expect(uri.path, '/dns-query');
      expect(uri.queryParameters['name'], 'api.mangadex.org');
      expect(uri.queryParameters['type'], 'A');
    });

    test('membangun URL Google dengan parameter benar', () {
      final DohProvider provider = defaultDohProviders.last;
      final Uri uri = provider.queryUri('api.mangadex.org');

      expect(uri.host, 'dns.google');
      expect(uri.path, '/resolve');
      expect(uri.queryParameters['name'], 'api.mangadex.org');
    });

    test('bootstrap IP tidak kosong untuk semua provider', () {
      for (final DohProvider provider in defaultDohProviders) {
        expect(provider.bootstrapIps, isNotEmpty,
            reason: '${provider.name} harus punya IP bootstrap');
        for (final String ip in provider.bootstrapIps) {
          expect(InternetAddress.tryParse(ip), isNotNull,
              reason: 'IP bootstrap ${provider.name} tidak valid: $ip');
        }
      }
    });
  });
}
