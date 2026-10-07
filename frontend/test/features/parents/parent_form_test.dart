import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/features/parents/presentation/parent_form_screen.dart';

import '../../helpers.dart';

void main() {
  testWidgets('a new parent needs a valid phone number; email is optional', (tester) async {
    final api = FakeApi(
      (request) => (
        201,
        {'id': 'p1', 'firstName': 'Fatima', 'lastName': 'Amrani', 'phone': '+31 6 1234 5678', 'children': <Object>[]},
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiDioProvider.overrideWithValue(api.dio)],
        child: localized(const ParentFormScreen(suggestedLastName: 'Amrani')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amrani'), findsOneWidget, reason: 'the family name is pre-filled');
    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Fatima');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone'), 'call me');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(api.requests, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Phone'), '+31 6 1234 5678');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.requests.single.data, {
      'firstName': 'Fatima',
      'lastName': 'Amrani',
      'phone': '+31 6 1234 5678',
      'email': null,
    });
  });
}
