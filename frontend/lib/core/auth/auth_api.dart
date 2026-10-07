import 'package:dio/dio.dart';

import '../errors/api_exception.dart';
import 'auth_models.dart';

/// Calls to `/api/auth` and `/api/me`. Uses its own [Dio] without the refresh interceptor so a failed refresh can
/// never recurse.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<TokenResponse> login(String email, String password) =>
      _post('/api/auth/login', {'email': email, 'password': password});

  Future<TokenResponse> refresh(String refreshToken) => _post('/api/auth/refresh', {'refreshToken': refreshToken});

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>('/api/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TokenResponse> _post(String path, Map<String, String> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return TokenResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
