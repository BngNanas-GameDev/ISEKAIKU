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
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: Duration(seconds: connectTimeout),
            receiveTimeout: Duration(seconds: receiveTimeout),
            // MangaDex memakai parameter array: includes[], contentRating[], dsb.
            listFormat: ListFormat.multiCompatible,
            headers: {
              'User-Agent': userAgent,
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          // Throttle sederhana: Dart satu thread per isolate, aman tanpa lock.
          if (_lastRequest != null) {
            final elapsed = DateTime.now().difference(_lastRequest!);
            if (elapsed < _throttleInterval) {
              await Future.delayed(_throttleInterval - elapsed);
            }
          }
          _lastRequest = DateTime.now();
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Retry otomatis sekali pada 429 (Too Many Requests).
          if (error.response?.statusCode == 429) {
            final retryAfter = error.response?.headers.value('retry-after');
            final delay =
                retryAfter != null ? int.tryParse(retryAfter) ?? 5 : 5;
            await Future.delayed(Duration(seconds: delay));
            try {
              final response = await _dio.fetch<dynamic>(error.requestOptions);
              handler.resolve(response);
            } on DioException catch (retryError) {
              handler.next(retryError);
            }
            return;
          }
          handler.next(error);
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
///
/// Base URL bisa diarahkan ke mirror/proxy lewat
/// `--dart-define=MANGADEX_BASE_URL=...` (mis. saat ISP memblokir MangaDex).
const String mangaDexBaseUrl = String.fromEnvironment(
  'MANGADEX_BASE_URL',
  defaultValue: 'https://api.mangadex.org',
);

final ApiClient mangaDexClient = ApiClient(
  baseUrl: mangaDexBaseUrl,
  userAgent: 'Isekaiku/0.1.0 (https://github.com/BngNanas-GameDev/ISEKAIKU)',
);
