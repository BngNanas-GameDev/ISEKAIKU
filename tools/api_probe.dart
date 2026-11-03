// Uji A/B: apakah hasAvailableChapters benar-benar menyaring.
// Jalankan: dart run tools/api_probe.dart
import 'dart:convert';
import 'dart:io';

import 'package:isekaiku/core/network/doh/doh_http_overrides.dart';

const String frierenId = '77bee52c-d2d6-44ad-a33a-1734c1fe696a';

Future<Map<String, dynamic>> getJson(HttpClient c, String url) async {
  final req = await c.getUrl(Uri.parse(url));
  req.headers.set('User-Agent', 'Isekaiku-probe/0.1');
  req.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode}: ${body.substring(0, 140)}');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> run(HttpClient c, String label, String url) async {
  final json = await getJson(c, url);
  final ids = (json['data'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((e) => e['id'])
      .toSet();
  stdout.writeln('$label total=${json['total']} '
      'frieren=${ids.contains(frierenId) ? "ADA" : "tidak ada"}');
}

Future<void> main() async {
  HttpOverrides.global = DohHttpOverrides();
  final c = HttpClient();
  const base = 'https://api.mangadex.org';
  const common = 'limit=100&contentRating[]=safe&contentRating[]=suggestive'
      '&availableTranslatedLanguage[]=id&order[followedCount]=desc';

  try {
    await run(c, 'A tanpa filter      ', '$base/manga?$common');
    await run(c, 'B hasAvailable=true  ', '$base/manga?$common&hasAvailableChapters=true');
    await run(c, 'C hasAvailable=false ', '$base/manga?$common&hasAvailableChapters=false');

    // Cek feed Frieren langsung: apakah benar 0 untuk id+en.
    for (final lang in <String>['id', 'en']) {
      final feed = await getJson(
        c,
        '$base/manga/$frierenId/feed?limit=1&translatedLanguage[]=$lang',
      );
      stdout.writeln('feed Frieren [$lang] total=${feed['total']}');
    }
  } catch (e) {
    stdout.writeln('GAGAL: $e');
  } finally {
    c.close(force: true);
  }
  exit(0);
}
