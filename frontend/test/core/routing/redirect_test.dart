import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/routing/redirect.dart';

import '../../helpers.dart';

void main() {
  String? go(AsyncValue<AuthUser?> session, String location) => resolveRedirect(session: session, location: location);

  test('shows the splash screen while the session is restored', () {
    expect(go(const AsyncLoading(), '/dashboard'), Routes.splash);
    expect(go(const AsyncLoading(), Routes.splash), isNull);
  });

  test('sends signed-out users to the login screen', () {
    expect(go(const AsyncData(null), '/students'), Routes.login);
    expect(go(const AsyncData(null), Routes.login), isNull);
  });

  test('sends signed-in users from login to the dashboard', () {
    expect(go(AsyncData(testUser()), Routes.login), Routes.dashboard);
  });

  test('forces a password change before anything else', () {
    final user = testUser(mustChangePassword: true);
    expect(go(AsyncData(user), '/dashboard'), Routes.changePassword);
    expect(go(AsyncData(user), Routes.changePassword), isNull);
  });

  test('a teacher typing the payments or parents URL is sent back to the dashboard', () {
    expect(go(AsyncData(testUser()), '/payments'), Routes.dashboard);
    expect(go(AsyncData(testUser()), '/parents'), Routes.dashboard);
    expect(go(AsyncData(testUser()), Routes.users), Routes.dashboard);
    expect(go(AsyncData(testUser()), '/lessons'), isNull);
  });

  test('an admin can open every module', () {
    for (final path in ['/students', '/parents', '/payments', '/reports', Routes.users]) {
      expect(go(AsyncData(adminUser()), path), isNull, reason: path);
    }
  });

  test('a teacher can view students and classes but not open create or edit screens', () {
    final teacher = AsyncData(testUser());
    expect(go(teacher, '/students/s1'), isNull);
    expect(go(teacher, '/classes/c1'), isNull);
    expect(go(teacher, '/students/new'), Routes.dashboard);
    expect(go(teacher, '/students/s1/edit'), Routes.dashboard);
    expect(go(teacher, '/classes/new'), Routes.dashboard);
    expect(go(teacher, '/parents/new'), Routes.dashboard);
  });

  test('an admin can open create and edit screens', () {
    for (final path in ['/students/new', '/students/s1/edit', '/parents/new', '/classes/c1/edit']) {
      expect(go(AsyncData(adminUser()), path), isNull, reason: path);
    }
  });
}
