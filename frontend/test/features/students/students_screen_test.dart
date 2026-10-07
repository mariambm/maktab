import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/students/presentation/students_screen.dart';

import '../../helpers.dart';

Map<String, Object?> page(List<Object> items) => {'items': items, 'page': 0, 'size': 50, 'totalItems': items.length};

(int, Object?) Function(RequestOptions) server({List<Object> students = const [], bool failStudents = false}) =>
    (request) => switch (request.path) {
      '/api/students' when failStudents => (500, {'status': 500, 'error': 'INTERNAL_ERROR'}),
      '/api/students' => (200, page(students)),
      '/api/classes' => (200, page(const [])),
      _ => (404, null),
    };

final amina = {
  'id': 's1',
  'firstName': 'Amina',
  'lastName': 'Amrani',
  'dateOfBirth': '2017-03-14',
  'status': 'ACTIVE',
  'currentClass': {'id': 'c1', 'name': 'Saturday Qaida B'},
};

void main() {
  Future<FakeApi> pump(WidgetTester tester, AuthUser user, FakeApi api) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiDioProvider.overrideWithValue(api.dio),
          sessionControllerProvider.overrideWith(() => SignedInSession(user)),
        ],
        child: localized(const StudentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('lists students with their class, and administrators can add one', (tester) async {
    await pump(tester, adminUser(), FakeApi(server(students: [amina])));

    expect(find.text('Amina Amrani'), findsOneWidget);
    expect(find.textContaining('Saturday Qaida B'), findsOneWidget);
    expect(find.text('Add Student'), findsOneWidget);
  });

  testWidgets('teachers cannot add students and get a hint when they have none', (tester) async {
    await pump(tester, testUser(), FakeApi(server()));

    expect(find.text('Add Student'), findsNothing);
    expect(find.text('No students found'), findsOneWidget);
    expect(find.text('Students appear here once you are assigned to a class.'), findsOneWidget);
  });

  testWidgets('shows only active students by default and can switch to inactive', (tester) async {
    final api = await pump(tester, adminUser(), FakeApi(server(students: [amina])));
    expect(api.requests.where((r) => r.path == '/api/students').last.queryParameters['status'], 'ACTIVE');

    await tester.tap(find.text('Inactive'));
    await tester.pumpAndSettle();

    expect(api.requests.where((r) => r.path == '/api/students').last.queryParameters['status'], 'INACTIVE');
  });

  testWidgets('a failed load shows an error with a working retry', (tester) async {
    var fail = true;
    final api = FakeApi((request) => server(students: [amina], failStudents: fail)(request));
    await pump(tester, adminUser(), api);
    expect(find.text('Try again'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Amina Amrani'), findsOneWidget);
  });
}
