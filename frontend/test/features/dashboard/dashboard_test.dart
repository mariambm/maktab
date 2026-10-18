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
import 'package:maktab/features/reports/data/report_models.dart';
import 'package:maktab/features/reports/data/reports_repository.dart';
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

DashboardFigures figures({bool withPayments = false}) => DashboardFigures.fromJson({
  'attendance': {
    'from': '2026-09-21',
    'to': '2026-10-18',
    'attendancePercentage': 76,
    'late': 4,
    'absent': 9,
    'studentsBelowThreshold': 3,
    'thresholdPercentage': 80,
  },
  'progress': {'targets': 10, 'targetsBehind': 2},
  'payments': withPayments
      ? {
          'month': '2026-10',
          'currency': 'GBP',
          'totals': {
            'students': 30,
            'paid': 15,
            'partiallyPaid': 3,
            'outstanding': 12,
            'expectedTotal': 750.0,
            'paidTotal': 420.0,
            'outstandingTotal': 330.0,
          },
        }
      : null,
});

Widget app(AuthUser user, List<LessonSummary> lessons, {bool withPayments = false}) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(() => SignedInSession(user)),
    classesProvider.overrideWith((ref) async => []),
    studentsProvider.overrideWith(
      (ref, filter) async => const PageResult(items: [], page: 0, size: 20, totalItems: 30),
    ),
    lessonsOnDateProvider.overrideWith((ref, date) async => lessons),
    dashboardFiguresProvider.overrideWith((ref) async => figures(withPayments: withPayments)),
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
  });

  testWidgets('the last four weeks are summed up, with fees only for users who may see them', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(testUser(), []));
    await tester.pumpAndSettle();

    expect(find.text('Last four weeks'), findsOneWidget);
    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Below 80%'), findsOneWidget);
    expect(find.text('Behind target'), findsOneWidget);
    expect(find.textContaining('Outstanding'), findsNothing);
    expect(find.text('View reports'), findsOneWidget);
  });

  testWidgets('a day without lessons says so', (tester) async {
    await tester.pumpWidget(app(testUser(), []));
    await tester.pumpAndSettle();

    expect(find.text('No lessons today.'), findsOneWidget);
  });
}
