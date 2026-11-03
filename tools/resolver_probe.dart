// Uji DohResolver asli aplikasi (bukan tiruan).
// Jalankan: dart run tools/resolver_probe.dart
import 'dart:io';

import 'package:isekaiku/core/network/doh/doh_resolver.dart';

Future<void> log(String s) async {
  stdout.write('$s\n');
  await stdout.flush();
}

Future<void> main() async {
  final DohResolver resolver = DohResolver();
  final List<String> hosts = <String>[
    'api.mangadex.org',
    'cloudflare-dns.com',
    'dns.google',
  ];

  for (final String host in hosts) {
    final List<InternetAddress> addrs = await resolver.resolve(host);
    if (addrs.isEmpty) {
      await log('$host => GAGAL (kosong)');
    } else {
      await log('$host => ${addrs.map((a) => a.address).join(", ")}');
    }
  }

  // Cache hit kedua harus instan (tanpa jaringan).
  final Stopwatch sw = Stopwatch()..start();
  await resolver.resolve('api.mangadex.org');
  sw.stop();
  await log('cache hit: ${sw.elapsedMilliseconds} ms');

  exit(0);
}
