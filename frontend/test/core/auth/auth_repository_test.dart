import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/auth/auth_api.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/auth_repository.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class MockAuthApi extends Mock implements AuthApi {}

TokenResponse tokens(String access, String refresh) => TokenResponse(
      accessToken: access,
      accessTokenExpiresAt: DateTime.utc(2026),
      refreshToken: refresh,
      refreshTokenExpiresAt: DateTime.utc(2026),
      user: testUser(),
    );

void main() {
  late MockAuthApi api;
  late InMemoryTokenStorage storage;
  late AuthRepository repository;

  setUp(() {
    api = MockAuthApi();
    storage = InMemoryTokenStorage();
    repository = AuthRepository(authApi: api, storage: storage, apiDio: Dio());
  });

  test('sign-in trims the email and stores both tokens', () async {
    when(() => api.login('aisha@test.local', 'pw')).thenAnswer((_) async => tokens('a1', 'r1'));

    final user = await repository.signIn('  aisha@test.local ', 'pw');

    expect(user.firstName, 'Aisha');
    expect(storage.accessToken, 'a1');
    expect(storage.refresh, 'r1');
  });

  test('restore without a stored token returns null without calling the API', () async {
    expect(await repository.restore(), isNull);
    verifyNever(() => api.refresh(any()));
  });

  test('restore with an expired token clears storage', () async {
    storage.refresh = 'old';
    when(() => api.refresh('old')).thenThrow(const ApiException(code: 'UNAUTHENTICATED', statusCode: 401));

    expect(await repository.restore(), isNull);
    expect(storage.refresh, isNull);
  });

  test('sign-out clears local tokens even if the server cannot be reached', () async {
    storage.refresh = 'r1';
    when(() => api.logout('r1')).thenThrow(const ApiException(code: ApiException.networkError));

    await repository.signOut();

    expect(storage.refresh, isNull);
  });
}
