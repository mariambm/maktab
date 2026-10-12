import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maktab/core/api/page_result.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/classes/data/classes_repository.dart';
import 'package:maktab/features/dashboard/presentation/dashboard_screen.dart';
import 'package:maktab/features/lessons/data/lesson_models.dart';
import 'package:maktab/features/lessons/data/lessons_repository.dart';
import 'package:maktab/features/students/data/students_repository.dart';

import '../../helpers.dart';

LessonSummary lesson(String className, String start, {String? id}) => LessonSummary(
  id: id,
  classGroupId: 'c-$className',
  className: className,
  room: 'Room 1',
  lessonDate: DateTime(2026, 10, 12),
  startTime: start,
  endTime: '18:00:00',
  status: 'SCHEDULED',
  studentCount: 8,
  attendanceRecorded: 0,
);

Widget app(AuthUser user, List<LessonSummary> lessons) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(() => SignedInSession(user)),
    classesProvider.overrideWith((ref) async => []),
    studentsProvider.overrideWith(
      (ref, filter) async => const PageResult(items: [], page: 0, size: 20, totalItems: 30),
    ),
    lessonsOnDateProvider.overrideWith((ref, date) async => lessons),
  ],
  child: localized(const DashboardScreen()),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('shows the figures and today\'s lessons, with a button to open or view each', (tester) async {
    await tester.pumpWidget(app(testUser(), [lesson('Beginners A', '16:30:00'), lesson('Hifz', '17:00:00', id: 'l1')]));
    await tester.pumpAndSettle();

    expect(find.text('Assalamu alaikum, Aisha'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Lessons today'), findsOneWidget);
    expect(find.text('16:30'), findsOneWidget);
    expect(find.text('Beginners A'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Open'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'View'), findsOneWidget);
    // A teacher does not get the admin hint.
    expect(find.text('An overview of attendance, progress and payments will appear here.'), findsNothing);
  });

  testWidgets('a day without lessons says so', (tester) async {
    await tester.pumpWidget(app(testUser(), []));
    await tester.pumpAndSettle();

    expect(find.text('No lessons today.'), findsOneWidget);
  });
}
