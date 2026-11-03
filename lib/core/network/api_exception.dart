import 'package:dio/dio.dart';

/// Exception yang dilempar oleh lapisan API.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  /// True bila kegagalan terjadi sebelum server menjawab
  /// (DNS, koneksi ditolak, TLS diputus, timeout).
  final bool isNetworkFailure;

  ApiException({
    this.statusCode,
    required this.message,
    this.isNetworkFailure = false,
  });

  /// Pesan ramah pengguna untuk ditampilkan di UI.
  String get userMessage {
    if (isNetworkFailure) {
      return 'Tidak bisa terhubung ke server. Jaringanmu mungkin memblokir '
          'MangaDex — coba pakai VPN atau jaringan lain.';
    }
    if (statusCode == 429) {
      return 'Terlalu banyak permintaan ke MangaDex. Coba lagi sebentar.';
    }
    if (statusCode != null && statusCode! >= 500) {
      return 'Server MangaDex sedang bermasalah ($statusCode).';
    }
    if (statusCode == 404) {
      return 'Data tidak ditemukan.';
    }
    return message.isNotEmpty ? message : 'Terjadi kesalahan ($statusCode).';
  }

  @override
  String toString() =>
      'ApiException${statusCode != null ? ' $statusCode' : ''}: $message';
}

ApiException dioErrorToApiException(DioException error) {
  final response = error.response;
  final status = response?.statusCode;

  final type = error.type;
  final networkFailure = response == null &&
      (type == DioExceptionType.connectionError ||
          type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.unknown ||
          type == DioExceptionType.badCertificate);

  final detail = response?.statusMessage?.isNotEmpty == true
      ? response!.statusMessage!
      : (error.message ?? type.name);

  return ApiException(
    statusCode: status,
    message: detail,
    isNetworkFailure: networkFailure,
  );
}
