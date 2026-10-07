import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/auth_repository.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
  });

  tearDown(() => container.dispose());

  test('restores the previous session on start-up', () async {
    when(() => repository.restore()).thenAnswer((_) async => testUser());

    expect(await container.read(sessionControllerProvider.future), isNotNull);
  });

  test('starts signed out when restoring fails, for example when offline', () async {
    when(() => repository.restore()).thenThrow(const ApiException(code: ApiException.networkError));

    expect(await container.read(sessionControllerProvider.future), isNull);
  });

  test('signs in and out', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);
    when(() => repository.signIn(any(), any())).thenAnswer((_) async => testUser());
    when(() => repository.signOut()).thenAnswer((_) async {});
    await container.read(sessionControllerProvider.future);

    await container.read(sessionControllerProvider.notifier).signIn('aisha@test.local', 'secret');
    expect(container.read(sessionControllerProvider).value?.firstName, 'Aisha');

    await container.read(sessionControllerProvider.notifier).signOut();
    expect(container.read(sessionControllerProvider).value, isNull);
  });

  test('a failed sign-in throws and leaves the user signed out', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);
    when(() => repository.signIn(any(), any())).thenThrow(
      const ApiException(code: 'UNAUTHENTICATED', statusCode: 401, message: 'Invalid email or password'),
    );
    await container.read(sessionControllerProvider.future);

    await expectLater(
      container.read(sessionControllerProvider.notifier).signIn('a@b.c', 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(sessionControllerProvider).value, isNull);
  });
}
