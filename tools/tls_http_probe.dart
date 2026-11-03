// Diagnostik: TLS handshake lalu kirim HTTP/1.1 mentah, dengan batas waktu keras.
// Jalankan: dart run tools/tls_http_probe.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> log(String s) async {
  stdout.write('$s\n');
  await stdout.flush();
}

Future<void> probe(String ip, String sni) async {
  await log('=== IP $ip, SNI "$sni" ===');
  Socket? raw;
  try {
    raw = await Socket.connect(ip, 443, timeout: const Duration(seconds: 10));
    await log('  TCP OK');

    final SecureSocket tls = await SecureSocket.secure(
      raw,
      host: sni,
      onBadCertificate: (cert) => true,
    ).timeout(const Duration(seconds: 10));
    await log('  TLS OK  alpn=${tls.selectedProtocol ?? "-"}');

    tls.write(
      'GET /ping HTTP/1.1\r\n'
      'Host: $sni\r\n'
      'User-Agent: Isekaiku-probe/0.1\r\n'
      'Accept: application/json\r\n'
      'Connection: close\r\n'
      '\r\n',
    );
    await tls.flush();
    await log('  Request terkirim, menunggu respons...');

    final List<int> bytes = <int>[];
    final Completer<void> done = Completer<void>();

    final StreamSubscription<List<int>> sub = tls.listen(
      (List<int> chunk) {
        bytes.addAll(chunk);
        if (bytes.length > 4000 && !done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object e) {
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );

    await done.future.timeout(const Duration(seconds: 12), onTimeout: () {
      return;
    });
    await sub.cancel();
    tls.destroy();

    final String text = latin1.decode(bytes);
    await log('  DITERIMA: ${bytes.length} byte');
    if (text.isEmpty) {
      await log('  (tidak ada data — koneksi ditutup tanpa respons)');
    } else {
      final String statusLine = text.split('\r\n').first;
      await log('  STATUS: "$statusLine"');
      final int idx = text.indexOf('\r\n\r\n');
      if (idx >= 0) {
        final String body = text.substring(idx + 4).trim();
        await log('  BODY: "${body.length > 220 ? body.substring(0, 220) : body}"');
      }
    }
  } on TimeoutException {
    await log('  TIMEOUT');
  } catch (e) {
    final String msg = e.toString().replaceAll('\n', ' ');
    await log('  GAGAL: ${msg.length > 170 ? msg.substring(0, 170) : msg}');
  } finally {
    raw?.destroy();
  }
  await log('');
}

Future<void> main() async {
  await probe('45.129.229.2', 'api.mangadex.org');
  await probe('45.129.229.1', 'api.mangadex.org');
  exit(0);
}
