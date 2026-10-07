import 'package:dio/dio.dart';

/// A failure from the Maktab API, parsed from its standard error body. [code] mirrors the backend's `error` field
/// (for example `VALIDATION_ERROR`), or `NETWORK_ERROR` when the server could not be reached.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiException(code: networkError);
    }
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final fields = data['fieldErrors'];
      return ApiException(
        code: data['error'] as String? ?? unknown,
        message: data['message'] as String?,
        statusCode: response.statusCode,
        fieldErrors: fields is Map<String, dynamic>
            ? fields.map((key, value) => MapEntry(key, value.toString()))
            : const {},
      );
    }
    return ApiException(code: unknown, statusCode: response.statusCode);
  }

  static const networkError = 'NETWORK_ERROR';
  static const unknown = 'UNKNOWN';

  final String code;
  final String? message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isNetworkError => code == networkError;
  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => 'ApiException($code, $statusCode)';
}
