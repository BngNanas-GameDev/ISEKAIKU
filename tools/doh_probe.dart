// Skrip diagnostik: uji DoH + koneksi HTTPS ke IP hasil DoH.
// Jalankan: dart run tools/doh_probe.dart
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const String host = 'api.mangadex.org';

  stdout.writeln('=== 1. Query DoH (Cloudflare) ===');
  final HttpClient dohClient = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  List<String> ips = <String>[];
  try {
    final req = await dohClient.getUrl(
      Uri.parse('https://cloudflare-dns.com/dns-query?name=$host&type=A'),
    );
    req.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    stdout.writeln('HTTP ${res.statusCode}');
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final answers = decoded['Answer'] as List<dynamic>? ?? <dynamic>[];
    for (final a in answers) {
      final m = a as Map<String, dynamic>;
      if (m['type'] == 1) {
        ips.add(m['data'] as String);
        stdout.writeln('  A ${m['data']} (TTL ${m['TTL']})');
      }
    }
  } catch (e) {
    stdout.writeln('DoH GAGAL: $e');
  } finally {
    dohClient.close(force: true);
  }

  stdout.writeln('\n=== 2. DNS sistem (pembanding) ===');
  try {
    final sys = await InternetAddress.lookup(host);
    for (final a in sys) {
      stdout.writeln('  ${a.address} (${a.type.name})');
    }
  } catch (e) {
    stdout.writeln('DNS sistem GAGAL: $e');
  }

  stdout.writeln('\n=== 3. HTTPS ke IP hasil DoH (SNI tetap $host) ===');
  for (final ip in ips.take(2)) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..connectionFactory = (Uri url, String? ph, int? pp) {
        return Socket.startConnect(ip, 443);
      };
    try {
      final req = await client.getUrl(Uri.parse('https://$host/ping'));
      req.headers.set(HttpHeaders.userAgentHeader,
          'Isekaiku/0.1.0 (https://github.com/BngNanas-GameDev/ISEKAIKU)');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      stdout.writeln('  $ip => HTTP ${res.statusCode}  body="${body.trim()}"');
    } catch (e) {
      stdout.writeln('  $ip => GAGAL: $e');
    } finally {
      client.close(force: true);
    }
  }

  stdout.writeln('\n=== 4. HTTPS biasa (DNS sistem, kontrol) ===');
  final ctl = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await ctl.getUrl(Uri.parse('https://$host/ping'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    stdout.writeln('  HTTP ${res.statusCode}  body="${body.trim()}"');
  } catch (e) {
    stdout.writeln('  GAGAL: $e');
  } finally {
    ctl.close(force: true);
  }
}
