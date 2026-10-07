import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/routing/destinations.dart';

import '../../helpers.dart';

void main() {
  List<String> ids(List<AppDestination> list) => list.map((d) => d.id).toList();

  test('teachers do not see payments or parents', () {
    final visible = ids(visibleDestinations(testUser()));
    expect(visible, isNot(contains('payments')));
    expect(visible, isNot(contains('parents')));
    expect(visible, containsAll(['dashboard', 'lessons', 'students', 'classes', 'progress', 'settings']));
  });

  test('a teacher explicitly granted PAYMENT_READ sees payments', () {
    final user = testUser(permissions: {...testUser().permissions, Permissions.paymentRead});
    expect(ids(visibleDestinations(user)), contains('payments'));
  });

  test("teachers get their daily tools in the bottom bar", () {
    expect(ids(primaryDestinations(testUser())), ['dashboard', 'lessons', 'students', 'progress']);
  });

  test('admins see every module, with the rest under More', () {
    expect(ids(visibleDestinations(adminUser())), ids(allDestinations));
    expect(ids(primaryDestinations(adminUser())), ['dashboard', 'students', 'classes', 'payments']);
    expect(ids(secondaryDestinations(adminUser())), containsAll(['parents', 'reports', 'settings']));
  });

  test('locations map to their destination, including sub-pages', () {
    expect(destinationForLocation('/settings/users')?.id, 'settings');
    expect(destinationForLocation('/students')?.id, 'students');
    expect(destinationForLocation('/login'), isNull);
  });
}
