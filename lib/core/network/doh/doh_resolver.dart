// Resolver DNS-over-HTTPS (DoH).
//
// Kenapa ada modul ini: sebagian ISP di Indonesia membajak DNS dan mengarahkan
// `api.mangadex.org` ke halaman blokir (mis. block.myrepublic.co.id). Karena
// pembajakannya di level DNS, HTTPS ke IP yang benar tetap aman dan sah — yang
// perlu hanya "menerjemahkan" nama domain tanpa lewat DNS sistem.
//
// Cara kerja:
// - Query A-record dikirim lewat HTTPS ke resolver publik (Cloudflare/Google).
// - Endpoint DoH itu sendiri dihubungi lewat IP bootstrap yang di-hardcode,
//   supaya tidak terjadi rekursi (butuh DNS untuk menghubungi DoH).
// - Hasil di-cache sesuai TTL jawaban.
// - Kalau semua provider gagal, pemanggil boleh fallback ke DNS sistem.
//
// Catatan keamanan: setelah IP didapat, koneksi TLS ke IP tersebut tetap
// memakai hostname asli untuk SNI + validasi sertifikat, sehingga tidak
// melemahkan keamanan (lihat SecureSocket.secure(host: ...) di dart:io).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Satu endpoint DoH beserta IP bootstrap-nya.
///
/// [bootstrapIps] dipakai untuk menghubungi endpoint DoH tanpa lewat DNS
/// sistem. Sertifikat tetap divalidasi terhadap [host].
class DohProvider {
  const DohProvider({
    required this.name,
    required this.host,
    required this.bootstrapIps,
    required this.queryPath,
    this.queryNameParameter = 'name',
    this.typeParameter = 'type',
    this.acceptHeader = 'application/dns-json',
  });

  final String name;
  final String host;
  final List<String> bootstrapIps;
  final String queryPath;
  final String queryNameParameter;
  final String typeParameter;
  final String acceptHeader;

  /// URI query untuk [hostname] dengan tipe record [type] (default A / IPv4).
  Uri queryUri(String hostname, {String type = 'A'}) => Uri.https(
        host,
        queryPath,
        <String, String>{queryNameParameter: hostname, typeParameter: type},
      );
}

/// Provider DoH bawaan: Cloudflare lebih dulu, lalu Google.
const List<DohProvider> defaultDohProviders = <DohProvider>[
  DohProvider(
    name: 'Cloudflare',
    host: 'cloudflare-dns.com',
    bootstrapIps: <String>['1.1.1.1', '1.0.0.1'],
    queryPath: '/dns-query',
  ),
  DohProvider(
    name: 'Google',
    host: 'dns.google',
    bootstrapIps: <String>['8.8.8.8', '8.8.4.4'],
    queryPath: '/resolve',
  ),
];

/// Hasil parsing jawaban DoH.
class DohAnswer {
  const DohAnswer({required this.addresses, required this.ttl});

  final List<InternetAddress> addresses;
  final Duration ttl;

  bool get isEmpty => addresses.isEmpty;
}

/// Parse payload JSON DoH (format Cloudflare/Google: `{"Answer": [...]}`).
///
/// Hanya record A (type == 1) yang diambil. Melempar [FormatException] bila
/// payload bukan objek JSON.
DohAnswer parseDohAnswer(String body) {
  final dynamic decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Jawaban DoH bukan objek JSON.');
  }

  final dynamic rawAnswers = decoded['Answer'];
  final List<dynamic> answers =
      rawAnswers is List ? rawAnswers : const <dynamic>[];

  final List<InternetAddress> addresses = <InternetAddress>[];
  int ttlSeconds = 300;

  for (final dynamic raw in answers) {
    if (raw is! Map<String, dynamic>) continue;
    if (raw['type'] != 1) continue; // 1 = A record (IPv4)
    final dynamic data = raw['data'];
    if (data is! String) continue;
    final InternetAddress? address = InternetAddress.tryParse(data);
    if (address == null) continue;
    addresses.add(address);
    final dynamic ttl = raw['TTL'];
    if (ttl is num) {
      final int value = ttl.toInt();
      if (value > 0 && value < ttlSeconds) ttlSeconds = value;
    }
  }

  return DohAnswer(
    addresses: addresses,
    ttl: Duration(seconds: ttlSeconds.clamp(30, 3600)),
  );
}

/// Resolver DoH dengan cache dan fallback antar-provider.
class DohResolver {
  DohResolver({List<DohProvider>? providers})
      : _providers = providers ?? defaultDohProviders;

  final List<DohProvider> _providers;
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  final Map<String, DateTime> _negativeCache = <String, DateTime>{};

  static const Duration _negativeTtl = Duration(seconds: 20);
  static const Duration _connectTimeout = Duration(seconds: 8);
  static const Duration _receiveTimeout = Duration(seconds: 8);

  int _roundRobin = 0;

  /// Resolve [hostname] ke daftar alamat IPv4.
  ///
  /// Mengembalikan list kosong bila semua provider gagal; pemanggil sebaiknya
  /// fallback ke resolusi sistem.
  Future<List<InternetAddress>> resolve(String hostname) async {
    final _CacheEntry? cached = _cache[hostname];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.addresses;
    }

    final DateTime? blockedUntil = _negativeCache[hostname];
    if (blockedUntil != null && blockedUntil.isAfter(DateTime.now())) {
      return const <InternetAddress>[];
    }

    for (final DohProvider provider in _providers) {
      try {
        final DohAnswer answer = await _query(provider, hostname);
        if (!answer.isEmpty) {
          _cache[hostname] = _CacheEntry(
            answer.addresses,
            DateTime.now().add(answer.ttl),
          );
          _negativeCache.remove(hostname);
          return answer.addresses;
        }
      } catch (_) {
        // Provider ini gagal; coba provider berikutnya.
      }
    }

    _negativeCache[hostname] = DateTime.now().add(_negativeTtl);
    return const <InternetAddress>[];
  }

  Future<DohAnswer> _query(DohProvider provider, String hostname) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = _connectTimeout
      ..idleTimeout = _receiveTimeout
      ..connectionFactory = _bootstrapFactory(provider);

    try {
      final HttpClientRequest request = await client.getUrl(
        provider.queryUri(hostname),
      );
      request.headers.set(HttpHeaders.acceptHeader, provider.acceptHeader);
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('${provider.name} HTTP ${response.statusCode}');
      }
      return parseDohAnswer(body);
    } finally {
      client.close(force: true);
    }
  }

  /// Koneksi ke endpoint DoH memakai IP bootstrap (tanpa DNS sistem).
  ///
  /// PENTING: saat `connectionFactory` dipasang, `HttpClient` TIDAK membungkus
  /// socket dengan TLS sendiri. Untuk URL https (endpoint DoH), factory wajib
  /// mengembalikan socket yang sudah di-TLS. Kalau tidak, request HTTP polos
  /// dikirim ke port 443 dan server langsung menutup koneksi — resolver DoH
  /// akan selalu gagal dan aplikasi fallback ke DNS sistem yang dibajak ISP.
  Future<ConnectionTask<Socket>> Function(Uri, String?, int?)
      _bootstrapFactory(DohProvider provider) {
    return (Uri url, String? proxyHost, int? proxyPort) async {
      final String ip = (url.host == provider.host &&
              provider.bootstrapIps.isNotEmpty)
          ? provider.bootstrapIps[_roundRobin % provider.bootstrapIps.length]
          : url.host;
      _roundRobin++;

      final ConnectionTask<Socket> rawTask =
          await Socket.startConnect(ip, url.port);
      final Socket raw = await rawTask.socket;

      if (url.scheme == 'https') {
        final SecureSocket secure = await SecureSocket.secure(
          raw,
          host: url.host,
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
    };
  }

  void clearCache() {
    _cache.clear();
    _negativeCache.clear();
  }

  /// Buang entri cache untuk satu host (mis. setelah error koneksi).
  void invalidate(String hostname) {
    _cache.remove(hostname);
    _negativeCache.remove(hostname);
  }
}

class _CacheEntry {
  _CacheEntry(this.addresses, this.expiresAt);

  final List<InternetAddress> addresses;
  final DateTime expiresAt;
}
