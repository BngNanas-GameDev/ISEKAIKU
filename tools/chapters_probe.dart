// Diagnostik: apakah MangaDex mengembalikan chapter untuk manga populer?
// Jalankan: dart run tools/chapters_probe.dart
import 'dart:io';

import 'package:isekaiku/core/network/doh/doh_http_overrides.dart';
import 'package:isekaiku/features/manga/data/mangadex_api.dart';

Future<void> log(String s) async {
  stdout.write('$s\n');
  await stdout.flush();
}

Future<void> main() async {
  HttpOverrides.global = DohHttpOverrides();

  final api = MangaDexApi();
  final popular = await api.popular(limit: 5);
  await log('manga populer: ${popular.length}');

  for (final manga in popular) {
    final chapters = await api.chapters(manga.id, language: 'en');
    await log('  ${manga.title} => ${chapters.length} chapter (en+fallback)');
  }

  exit(0);
}
