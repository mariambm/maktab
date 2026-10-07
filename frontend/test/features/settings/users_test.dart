import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/settings/data/user_summary.dart';
import 'package:maktab/features/settings/data/users_repository.dart';
import 'package:maktab/features/settings/presentation/user_detail_screen.dart';
import 'package:maktab/features/settings/presentation/user_form_screen.dart';

import '../../helpers.dart';

Map<String, Object?> teacherJson({List<String> granted = const []}) => {
  'id': 't1',
  'email': 'yusuf@test.local',
  'firstName': 'Yusuf',
  'lastName': 'Bakker',
  'active': true,
  'roles': ['TEACHER'],
  'grantedPermissions': granted,
  'effectivePermissions': ['STUDENT_READ', 'CLASS_READ', ...granted],
  'mustChangePassword': true,
  'lastLoginAt': null,
};

Widget app(FakeApi api, Widget child) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(adminUser())),
  ],
  child: localized(child),
);

void main() {
  test('creating a user sends the roles and returns the one-time password', () async {
    final api = FakeApi((request) => (201, {'user': teacherJson(), 'temporaryPassword': 'Tmp-123-abc'}));
    final created = await UsersRepository(api.dio).create(
      const UserDraft(firstName: ' Yusuf ', lastName: 'Bakker', email: 'yusuf@test.local'),
      {'TEACHER'},
    );

    expect(api.requests.single.path, '/api/users');
    expect(api.requests.single.data, {
      'firstName': 'Yusuf',
      'lastName': 'Bakker',
      'email': 'yusuf@test.local',
      'roles': ['TEACHER'],
    });
    expect(created.temporaryPassword, 'Tmp-123-abc');
    expect(created.toString(), isNot(contains('Tmp-123-abc')), reason: 'the password never ends up in logs');
    expect(created.user.permissionsFromRoles, {'STUDENT_READ', 'CLASS_READ'});
  });

  testWidgets('adding a user needs a role and then shows the temporary password once', (tester) async {
    final api = FakeApi((request) => (201, {'user': teacherJson(), 'temporaryPassword': 'Tmp-123-abc'}));
    await tester.pumpWidget(app(api, const UserFormScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Yusuf');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Bakker');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'yusuf@test.local');
    await tester.tap(find.widgetWithText(FilterChip, 'Teacher'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose at least one role'), findsOneWidget);
    expect(api.requests, isEmpty);

    await tester.tap(find.widgetWithText(FilterChip, 'Teacher'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect((api.requests.single.data as Map)['roles'], ['TEACHER']);
    expect(find.text('Temporary password'), findsOneWidget);
    expect(find.text('Tmp-123-abc'), findsOneWidget);
  });

  testWidgets('extra permissions only add what the roles do not already give', (tester) async {
    final api = FakeApi(
      (request) => request.method == 'PUT'
          ? (200, teacherJson(granted: ['PAYMENT_READ']))
          : (200, teacherJson()),
    );
    await tester.pumpWidget(app(api, const UserDetailScreen(userId: 't1')));
    await tester.pumpAndSettle();

    expect(find.text('Must choose a new password'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Deactivate account'), findsOneWidget, reason: 'another person can be deactivated');

    await tester.tap(find.widgetWithText(TextButton, 'Edit').last);
    await tester.pumpAndSettle();
    final fromRole = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'View students'));
    expect(fromRole.value, isTrue);
    expect(fromRole.onChanged, isNull, reason: 'the role already gives it');

    await tester.scrollUntilVisible(find.text('View payments'), 100, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'View payments'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final put = api.requests.firstWhere((r) => r.method == 'PUT');
    expect(put.path, '/api/users/t1/permissions');
    expect(put.data, {
      'permissions': ['PAYMENT_READ'],
    });
  });

  testWidgets('admins cannot deactivate their own account', (tester) async {
    final me = adminUser();
    final api = FakeApi(
      (request) => (
        200,
        {...teacherJson(), 'id': me.id, 'roles': ['ADMIN']},
      ),
    );
    await tester.pumpWidget(app(api, UserDetailScreen(userId: me.id)));
    await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Deactivate account'), findsNothing);
    expect(find.text('Reset password'), findsOneWidget);
  });
}
