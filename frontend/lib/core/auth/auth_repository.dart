import 'package:dio/dio.dart';

import '../errors/api_exception.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'token_storage.dart';

/// Owns the session lifecycle: sign in, restore on app start, refresh, change password and sign out.
class AuthRepository {
  AuthRepository({required this._authApi, required this._storage, required this._apiDio});

  final AuthApi _authApi;
  final TokenStorage _storage;
  final Dio _apiDio;

  Future<AuthUser> signIn(String email, String password) async {
    final tokens = await _authApi.login(email.trim(), password);
    await _storage.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    return tokens.user;
  }

  /// Restores the previous session from the stored refresh token. Returns null when there is none or it has expired.
  Future<AuthUser?> restore() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      return null;
    }
    try {
      final tokens = await _authApi.refresh(refreshToken);
      await _storage.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      return tokens.user;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _apiDio.put<void>(
        '/api/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthUser> fetchMe() async {
    try {
      final response = await _apiDio.get<Map<String, dynamic>>('/api/me');
      return AuthUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> signOut() async {
    final refreshToken = await _storage.readRefreshToken();
    await _storage.clear();
    if (refreshToken != null) {
      try {
        await _authApi.logout(refreshToken);
      } on ApiException {
        // Signing out locally is enough; the token expires on its own.
      }
    }
  }
}
