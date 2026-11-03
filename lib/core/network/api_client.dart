// Core HTTP client untuk MangaDex dan sumber eksternal lainnya.
//
// MangaDex syarat wajib:
// - User-Agent unik & identitas aplikasi
// - Rate limit ~1 req/detik (single-flight)
// - Tangani 429 dengan Retry-After
import 'package:dio/dio.dart';

class ApiClient {
  static const Duration _throttleInterval = Duration(milliseconds: 1100);

  final Dio _dio;
  DateTime? _lastRequest;

  ApiClient({
    required String baseUrl,
    required String userAgent,
    int connectTimeout = 30,
    int receiveTimeout = 30,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: connectTimeout),
          receiveTimeout: Duration(seconds: receiveTimeout),
          headers: {
            'User-Agent': userAgent,
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Single-flight throttle agar tidak melanggar rate limit MangaDex.
          // Dart adalah single-threaded per isolate, jadi pengecekan variabel
          // ini cukup aman tanpa lock eksternal.
          if (_lastRequest != null) {
            final elapsed = DateTime.now().difference(_lastRequest!);
            if (elapsed < _throttleInterval) {
              await Future.delayed(_throttleInterval - elapsed);
            }
          }
          _lastRequest = DateTime.now();
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Retry otomatis pada 429 (Too Many Requests).
          if (error.response?.statusCode == 429) {
            final retryAfter = error.response?.headers.value('retry-after');
            final delay = retryAfter != null
                ? int.tryParse(retryAfter) ?? 5
                : 5;
            await Future.delayed(Duration(seconds: delay));
            return handler.resolve(await _dio.fetch(error.requestOptions));
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<T>(path, queryParameters: query);
    return response.data as T;
  }

  void dispose() {
    _dio.close();
  }
}

/// Global singleton agar rate-limit berlaku di seluruh aplikasi.
final ApiClient mangaDexClient = ApiClient(
  baseUrl: 'https://api.mangadex.org',
  userAgent: 'Isekaiku/1.0.0 (+https://isekaiku.app)',
);
