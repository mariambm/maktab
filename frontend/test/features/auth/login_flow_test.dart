import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/app.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/auth_repository.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:maktab/core/organisation/organisation_name.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.restore()).thenAnswer((_) async => null);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          organisationNameProvider.overrideWith((ref) async => 'Jamiyat Tabligh UL Islam'),
        ],
        child: const MaktabApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the login screen when signed out', (tester) async {
    await pumpApp(tester);
    expect(find.text('Welcome to Maktab'), findsOneWidget);
    expect(find.text('Jamiyat Tabligh UL Islam'), findsOneWidget);
  });

  testWidgets('validates the form before calling the server', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => repository.signIn(any(), any()));

    await tester.enterText(find.byKey(const Key('login.email')), 'not-an-email');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets("shows the server's message when sign-in fails", (tester) async {
    when(() => repository.signIn(any(), any())).thenThrow(
      const ApiException(code: 'UNAUTHENTICATED', statusCode: 401, message: 'Invalid email or password'),
    );
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login.email')), 'aisha@test.local');
    await tester.enterText(find.byKey(const Key('login.password')), 'wrong');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('a teacher lands on the dashboard with teacher navigation and no payments', (tester) async {
    when(() => repository.signIn(any(), any())).thenAnswer((_) async => testUser());
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login.email')), 'aisha@test.local');
    await tester.enterText(find.byKey(const Key('login.password')), 'Correct-Horse-42');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Assalamu alaikum, Aisha'), findsOneWidget);
    final nav = find.byType(NavigationBar);
    expect(find.descendant(of: nav, matching: find.text('Lessons')), findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('Payments')), findsNothing);

    await tester.tap(find.descendant(of: nav, matching: find.text('More')));
    await tester.pumpAndSettle();
    expect(find.text('Payments'), findsNothing);
    expect(find.text('Parents & Guardians'), findsNothing);
    expect(find.text('Curriculum'), findsOneWidget);
  });

  testWidgets('an account with a temporary password must change it first', (tester) async {
    when(() => repository.signIn(any(), any())).thenAnswer((_) async => testUser(mustChangePassword: true));
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login.email')), 'aisha@test.local');
    await tester.enterText(find.byKey(const Key('login.password')), 'Temp-password-1');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Please choose a new password before you continue.'), findsOneWidget);
  });
}
