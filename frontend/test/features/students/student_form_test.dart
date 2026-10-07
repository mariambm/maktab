import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/students/presentation/student_form_screen.dart';

import '../../helpers.dart';

void main() {
  Future<FakeApi> pump(WidgetTester tester, FakeApi api) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiDioProvider.overrideWithValue(api.dio),
          sessionControllerProvider.overrideWith(() => SignedInSession(adminUser())),
        ],
        child: localized(const StudentFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  FakeApi classesOnly([(int, Object?)? onCreate]) => FakeApi(
    (request) => switch (request.path) {
      '/api/classes' => (200, {'items': <Object>[], 'page': 0, 'size': 100, 'totalItems': 0}),
      '/api/students' => onCreate ?? (500, null),
      _ => (404, null),
    },
  );

  testWidgets('checks required fields before calling the server', (tester) async {
    final api = await pump(tester, classesOnly());

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Student'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add Student'));
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
    expect(find.text('Date of birth is required'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets("shows the server's field errors next to the fields", (tester) async {
    final api = await pump(
      tester,
      classesOnly((
        400,
        {
          'status': 400,
          'error': 'VALIDATION_ERROR',
          'message': 'Join date must be after the date of birth',
          'fieldErrors': {'joinedOn': 'Join date must be after the date of birth'},
        },
      )),
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Amina');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Amrani');
    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Student'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add Student'));
    await tester.pumpAndSettle();

    expect(api.requests.where((r) => r.method == 'POST'), hasLength(1));
    expect(find.text('Join date must be after the date of birth'), findsOneWidget);
  });
}
