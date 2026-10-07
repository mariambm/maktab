import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_api.dart';
import '../auth/auth_repository.dart';
import '../auth/session_controller.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage(const FlutterSecureStorage()));

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(Dio(_baseOptions())));

/// The Dio instance every feature repository uses: authenticated, with transparent token refresh.
final apiDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      authApi: ref.watch(authApiProvider),
      retryDio: Dio(_baseOptions()),
      onSessionExpired: () => ref.read(sessionControllerProvider.notifier).sessionExpired(),
    ),
  );
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    authApi: ref.watch(authApiProvider),
    storage: ref.watch(tokenStorageProvider),
    apiDio: ref.watch(apiDioProvider),
  ),
);
