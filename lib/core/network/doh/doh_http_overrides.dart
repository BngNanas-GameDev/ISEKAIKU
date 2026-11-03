// Pemasangan DoH secara global lewat HttpOverrides.
//
// Dipasang sekali di `main()` SEBELUM `runApp()`:
//
//   HttpOverrides.global = DohHttpOverrides();
//
// Efeknya: setiap `HttpClient` yang dibuat aplikasi (Dio, cached_network_image,
// NetworkImage) akan memakai resolver DoH untuk mencari IP.
//
// PENTING — cara kerja HttpClient.connectionFactory:
// Saat connectionFactory dipasang, HttpClient TIDAK membungkus socket dengan
// TLS sendiri. Konstruktor `_HttpClientConnection` menerima socket apa adanya
// (parameter `false` di posisi `_proxyTunnel`, bukan `isSecure`). Jadi untuk
// URL https, factory WAJIB mengembalikan socket yang sudah di-TLS.
//
// Kalau factory mengembalikan socket TCP mentah ke port 443, server akan
// menerima teks HTTP polos dan langsung menutup koneksi. Itulah yang membuat
// request gagal dengan "Connection closed before full header was received".
//
// Karena itu di sini kita lakukan SecureSocket.secure(raw, host: url.host)
// dengan hostname ASLI. SNI tetap api.mangadex.org dan sertifikat tetap
// divalidasi terhadap hostname tersebut — keamanan tidak berkurang.
//
// Kalau DoH gagal, otomatis fallback ke DNS sistem supaya aplikasi tidak mati
// total di jaringan yang memblokir DoH sekalipun.

import 'dart:async';
import 'dart:io';

import 'doh_resolver.dart';

/// Resolver global, bisa diakses untuk invalidasi cache.
final DohResolver dohResolver = DohResolver();

class DohHttpOverrides extends HttpOverrides {
  DohHttpOverrides({DohResolver? resolver, this.enabled = true})
      : _resolver = resolver ?? dohResolver;

  final DohResolver _resolver;

  /// Bisa dimatikan lewat `--dart-define=DISABLE_DOH=true`.
  final bool enabled;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    if (enabled) {
      client.connectionFactory =
          (Uri url, String? proxyHost, int? proxyPort) =>
              _connect(url, proxyHost, proxyPort, context);
    }
    return client;
  }

  Future<ConnectionTask<Socket>> _connect(
    Uri url,
    String? proxyHost,
    int? proxyPort,
    SecurityContext? context,
  ) async {
    // Kalau ada proxy, biarkan HttpClient yang mengurus CONNECT + TLS.
    // Cukup sambungkan ke host proxy apa adanya.
    if (proxyHost != null && proxyHost.isNotEmpty) {
      final ConnectionTask<Socket> proxyTask = await Socket.startConnect(
        _resolveProxyHost(proxyHost),
        proxyPort ?? url.port,
      );
      return proxyTask;
    }

    // IP literal / localhost / .local tidak perlu DoH.
    if (InternetAddress.tryParse(url.host) != null ||
        url.host == 'localhost' ||
        url.host.endsWith('.local')) {
      return _connectAndSecure(url, url.host, context);
    }

    final List<InternetAddress> addresses = await _resolver.resolve(url.host);
    if (addresses.isEmpty) {
      // DoH gagal: pakai DNS sistem lewat hostname biasa.
      return _connectAndSecure(url, url.host, context);
    }

    // Sambung ke IP hasil DoH, lalu bungkus TLS dengan hostname asli.
    return _connectAndSecure(url, addresses.first.address, context);
  }

  String _resolveProxyHost(String proxyHost) => proxyHost;

  /// Sambung ke [target] (IP atau hostname) lalu bungkus TLS bila perlu.
  Future<ConnectionTask<Socket>> _connectAndSecure(
    Uri url,
    String target,
    SecurityContext? context,
  ) async {
    final ConnectionTask<Socket> rawTask =
        await Socket.startConnect(target, url.port);
    final Socket raw = await rawTask.socket;

    if (url.scheme == 'https') {
      // host: url.host -> SNI + validasi sertifikat memakai nama domain asli,
      // meskipun socket tersambung ke IP hasil DoH.
      final SecureSocket secure = await SecureSocket.secure(
        raw,
        host: url.host,
        context: context,
      );
      return ConnectionTask.fromSocket<Socket>(
        Future<Socket>.value(secure),
        () {},
      );
    }

    return ConnectionTask.fromSocket<Socket>(
      Future<Socket>.value(raw),
      () {},
    );
  }
}
