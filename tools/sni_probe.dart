// Diagnostik: apakah blokir terjadi di level SNI (nama domain pada TLS)?
// Jalankan: dart run tools/sni_probe.dart
import 'dart:async';
import 'dart:io';

Future<void> probe(String label, String ip, String sniHost) async {
  stdout.write('$label (IP $ip, SNI "$sniHost") => ');
  Socket? raw;
  try {
    raw = await Socket.connect(ip, 443, timeout: const Duration(seconds: 12));
    final SecureSocket tls = await SecureSocket.secure(
      raw,
      host: sniHost,
      onBadCertificate: (cert) => true,
    ).timeout(const Duration(seconds: 12));
    stdout.writeln('TLS OK (alpn=${tls.selectedProtocol ?? "-"})');
    tls.destroy();
  } on TimeoutException {
    stdout.writeln('TIMEOUT');
  } catch (e) {
    final String msg = e.toString().replaceAll('\n', ' ');
    stdout.writeln('GAGAL: ${msg.length > 130 ? msg.substring(0, 130) : msg}');
  } finally {
    raw?.destroy();
  }
}

Future<void> main() async {
  const List<String> mangadexIps = <String>['45.129.229.1', '45.129.229.2'];

  stdout.writeln('=== A. SNI asli (api.mangadex.org) ===');
  for (final ip in mangadexIps) {
    await probe('  MangaDex', ip, 'api.mangadex.org');
  }

  stdout.writeln('\n=== B. SNI berbeda, IP MangaDex sama ===');
  for (final ip in mangadexIps) {
    await probe('  MangaDex', ip, 'www.google.com');
  }

  stdout.writeln('\n=== C. IP tidak diblokir (kontrol) ===');
  await probe('  Cloudflare', '1.1.1.1', 'cloudflare-dns.com');

  stdout.writeln('\nKesimpulan:');
  stdout.writeln('  A gagal + B berhasil  -> blokir berbasis SNI (DoH saja TIDAK cukup)');
  stdout.writeln('  A gagal + B gagal     -> IP server diblokir / server mati');
  stdout.writeln('  A berhasil            -> DoH cukup, blokir hanya di DNS');
}
