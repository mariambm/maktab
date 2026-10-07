import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/errors/api_exception.dart';

void main() {
  final request = RequestOptions(path: '/api/users');

  test('parses the standard error body including field errors', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 400,
          data: {
            'status': 400,
            'error': 'VALIDATION_ERROR',
            'message': 'Validation failed',
            'fieldErrors': {'firstName': 'First name is required'},
          },
        ),
      ),
    );

    expect(error.code, 'VALIDATION_ERROR');
    expect(error.statusCode, 400);
    expect(error.message, 'Validation failed');
    expect(error.fieldErrors, {'firstName': 'First name is required'});
  });

  test('a missing response is a network error', () {
    final error = ApiException.fromDio(
      DioException(requestOptions: request, type: DioExceptionType.connectionError),
    );
    expect(error.isNetworkError, isTrue);
  });

  test('a non-JSON body still yields a usable error', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 502, data: '<html>'),
      ),
    );
    expect(error.code, ApiException.unknown);
    expect(error.statusCode, 502);
  });
}
