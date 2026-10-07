import 'package:dio/dio.dart';

import '../errors/api_exception.dart';

/// Runs a Dio request and turns any failure into an [ApiException], so repositories stay one-liners.
Future<T> apiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// Formats a date as the API expects (`yyyy-MM-dd`).
String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
