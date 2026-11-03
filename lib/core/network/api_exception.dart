import 'package:dio/dio.dart';

/// Exception yang dilempar oleh lapisan API.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() =>
      'ApiException${statusCode != null ? ' $statusCode' : ''}: $message';
}

ApiException dioErrorToApiException(DioException error) {
  final status = error.response?.statusCode;
  final msg = error.response?.statusMessage ?? error.message ?? '';
  return ApiException(statusCode: status, message: msg);
}
