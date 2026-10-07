import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_api.dart';
import '../auth/token_storage.dart';

/// Adds the access token to every request. On a 401 it refreshes the session once (shared by concurrent requests)
/// and retries; if refreshing fails it clears the tokens and calls [onSessionExpired].
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._storage,
    required this._authApi,
    required this._retryDio,
    required this._onSessionExpired,
  });

  static const _retriedKey = 'maktab.retried';

  final TokenStorage _storage;
  final AuthApi _authApi;
  final Dio _retryDio;
  final void Function() _onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra[_retriedKey] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      return handler.next(err);
    }

    // Another queued request may already have refreshed the token.
    final sentToken = (request.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
    if (_storage.accessToken != null && _storage.accessToken != sentToken) {
      return _retry(request, handler, err);
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      _onSessionExpired();
      return handler.next(err);
    }
    try {
      final tokens = await _authApi.refresh(refreshToken);
      await _storage.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    } catch (_) {
      await _storage.clear();
      _onSessionExpired();
      return handler.next(err);
    }
    return _retry(request, handler, err);
  }

  Future<void> _retry(RequestOptions request, ErrorInterceptorHandler handler, DioException original) async {
    request.extra[_retriedKey] = true;
    request.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
    try {
      handler.resolve(await _retryDio.fetch<dynamic>(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
