// Uji perbaikan: connectionFactory harus mengembalikan socket yang SUDAH di-TLS.
// Jalankan: dart run tools/fix_probe.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> log(String s) async {
  stdout.write('$s\n');
  await stdout.flush();
}

Future<ConnectionTask<Socket>> factory(Uri url, String? ph, int? pp) async {
  final ConnectionTask<Socket> rawTask =
      await Socket.startConnect('45.129.229.2', url.port);
  final Socket raw = await rawTask.socket;
  if (url.scheme == 'https') {
    final SecureSocket secure = await SecureSocket.secure(
      raw,
      host: url.host, // SNI + validasi sertifikat terhadap hostname asli
    );
    return ConnectionTask.fromSocket<Socket>(Future<Socket>.value(secure), () {});
  }
  return ConnectionTask.fromSocket<Socket>(Future<Socket>.value(raw), () {});
}

Future<void> main() async {
  await log('=== connectionFactory + TLS manual ===');
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..connectionFactory = factory;

  try {
    final HttpClientRequest req =
        await client.getUrl(Uri.parse('https://api.mangadex.org/ping'));
    req.headers.set(HttpHeaders.userAgentHeader,
        'Isekaiku/0.1.0 (https://github.com/BngNanas-GameDev/ISEKAIKU)');
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final HttpClientResponse res = await req.close();
    final String body = await res.transform(utf8.decoder).join();
    await log('  HASIL: HTTP ${res.statusCode}  body="${body.trim()}"');
  } catch (e) {
    final String msg = e.toString().replaceAll('\n', ' ');
    await log('  GAGAL: ${msg.length > 220 ? msg.substring(0, 220) : msg}');
  } finally {
    client.close(force: true);
  }
  exit(0);
}
