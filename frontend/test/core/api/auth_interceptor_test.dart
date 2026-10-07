import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/auth_interceptor.dart';
import 'package:maktab/core/auth/auth_api.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class MockAuthApi extends Mock implements AuthApi {}

/// Accepts only the token named in [validToken]; everything else gets 401.
class FakeServer implements HttpClientAdapter {
  FakeServer(this.validToken);

  String validToken;
  final seenTokens = <String?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final header = options.headers['Authorization'] as String?;
    seenTokens.add(header);
    final ok = header == 'Bearer $validToken';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'ok': true} : {'status': 401, 'error': 'UNAUTHENTICATED'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MockAuthApi api;
  late InMemoryTokenStorage storage;
  late FakeServer server;
  late Dio dio;
  late int expiredCalls;

  setUp(() async {
    api = MockAuthApi();
    storage = InMemoryTokenStorage();
    await storage.save(accessToken: 'expired', refreshToken: 'r1');
    server = FakeServer('fresh');
    expiredCalls = 0;
    final retryDio = Dio()..httpClientAdapter = server;
    dio = Dio()..httpClientAdapter = server;
    dio.interceptors.add(
      AuthInterceptor(storage: storage, authApi: api, retryDio: retryDio, onSessionExpired: () => expiredCalls++),
    );
  });

  test('refreshes an expired access token once and retries the request', () async {
    when(() => api.refresh('r1')).thenAnswer(
      (_) async => TokenResponse(
        accessToken: 'fresh',
        accessTokenExpiresAt: DateTime.utc(2026),
        refreshToken: 'r2',
        refreshTokenExpiresAt: DateTime.utc(2026),
        user: testUser(),
      ),
    );

    final response = await dio.get<Map<String, dynamic>>('http://api/api/me');

    expect(response.statusCode, 200);
    expect(server.seenTokens, ['Bearer expired', 'Bearer fresh']);
    expect(storage.refresh, 'r2');
    expect(expiredCalls, 0);
  });

  test('when refreshing fails the session ends and tokens are cleared', () async {
    when(() => api.refresh('r1')).thenThrow(const ApiException(code: 'UNAUTHENTICATED', statusCode: 401));

    await expectLater(dio.get<void>('http://api/api/me'), throwsA(isA<DioException>()));

    expect(expiredCalls, 1);
    expect(storage.accessToken, isNull);
    expect(storage.refresh, isNull);
  });
}
