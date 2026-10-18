import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/auth_models.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/core/routing/redirect.dart';
import 'package:maktab/features/reports/data/reports_repository.dart';
import 'package:maktab/features/reports/presentation/report_widgets.dart';
import 'package:maktab/features/reports/presentation/reports_screen.dart';
import 'package:maktab/features/reports/presentation/student_report_screen.dart';

import '../../helpers.dart';

Map<String, Object?> counts({int present = 2, int late = 1, int absent = 1, int? percentage = 75}) => {
  'lessons': 2,
  'records': present + late + absent,
  'present': present,
  'late': late,
  'absent': absent,
  'attendancePercentage': percentage,
};

final attendanceJson = {
  'from': '2026-09-21',
  'to': '2026-10-18',
  'thresholdPercentage': 80,
  'totals': counts(),
  'absenceReasons': {'SICK': 1},
  'classes': [
    {'classId': 'c1', 'className': 'Saturday Beginners A', 'counts': counts()},
  ],
  'belowThreshold': [
    {
      'studentId': 's2',
      'firstName': 'Bilal',
      'lastName': 'Khan',
      'classId': 'c1',
      'className': 'Saturday Beginners A',
      'counts': counts(present: 0, percentage: 50),
    },
  ],
};

final paymentReportJson = {
  'currency': 'GBP',
  'months': [
    {
      'id': 'pp1',
      'month': '2026-10',
      'monthlyFee': 25.0,
      'currency': 'GBP',
      'totals': {
        'students': 2,
        'paid': 1,
        'partiallyPaid': 0,
        'outstanding': 1,
        'expectedTotal': 50.0,
        'paidTotal': 25.0,
        'outstandingTotal': 25.0,
      },
    },
  ],
  'totals': {
    'students': 2,
    'paid': 1,
    'partiallyPaid': 0,
    'outstanding': 1,
    'expectedTotal': 50.0,
    'paidTotal': 25.0,
    'outstandingTotal': 25.0,
  },
  'studentsOwing': [
    {
      'studentId': 's2',
      'firstName': 'Bilal',
      'lastName': 'Khan',
      'className': 'Saturday Beginners A',
      'months': 1,
      'outstandingAmount': 25.0,
    },
  ],
};

Map<String, Object?> studentReportJson({bool withPayments = false}) => {
  'studentId': 's1',
  'firstName': 'Amina',
  'lastName': 'Rahman',
  'className': 'Saturday Beginners A',
  'from': '2026-07-20',
  'to': '2026-10-18',
  'attendance': {
    'lessons': 4,
    'present': 2,
    'late': 0,
    'absent': 2,
    'attendancePercentage': 50,
    'thresholdPercentage': 80,
    'belowThreshold': true,
    'absenceReasons': {'SICK': 2},
  },
  'progress': [
    {
      'subject': 'QURAN_RECITATION',
      'scores': 3,
      'averageScore': 3.8,
      'latestScore': 4.0,
      'latestLabel': 'Good',
      'latestDate': '2026-10-17',
    },
  ],
  'targets': <Object>[],
  'behaviour': [
    {'behaviour': 'TALKING', 'good': false, 'count': 3},
  ],
  'uniform': {'inOrder': 2, 'partiallyInOrder': 0, 'notInOrder': 1},
  'payments': withPayments
      ? {
          'currency': 'GBP',
          'months': 3,
          'monthsOwing': 1,
          'expectedTotal': 75.0,
          'paidTotal': 50.0,
          'outstandingTotal': 25.0,
        }
      : null,
};

(int, Object?) respond(String path, {bool withPayments = false}) => switch (path) {
  '/api/classes' => (200, {'items': <Object>[], 'page': 0, 'size': 200, 'totalItems': 0}),
  '/api/reports/attendance' => (200, attendanceJson),
  '/api/reports/payments' => (200, paymentReportJson),
  '/api/reports/students/s1' => (200, studentReportJson(withPayments: withPayments)),
  _ => (404, {'status': 404, 'error': 'NOT_FOUND', 'message': 'Not found'}),
};

FakeApi fakeApi({bool withPayments = false}) => FakeApi((request) => respond(request.path, withPayments: withPayments));

Widget app(FakeApi api, Widget child, AuthUser user) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(user)),
  ],
  child: localized(child),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('a report asks the server for its dates and class', () async {
    final api = FakeApi((_) => (200, attendanceJson));

    final report = await ReportsRepository(api.dio)
        .attendance((from: DateTime(2026, 9, 21), to: DateTime(2026, 10, 18), classId: 'c1'));

    expect(api.requests.single.path, '/api/reports/attendance');
    expect(api.requests.single.queryParameters, {'from': '2026-09-21', 'to': '2026-10-18', 'classId': 'c1'});
    expect(report.belowThreshold.single.counts.attendancePercentage, 50);
  });

  test('the period choices count back from today, today included', () {
    final dates = ReportRange.fourWeeks.datesFrom(DateTime(2026, 10, 18, 21, 30));

    expect(dates.from, DateTime(2026, 9, 21));
    expect(dates.to, DateTime(2026, 10, 18));
  });

  testWidgets('a teacher sees attendance with the students below the threshold, and no payments tab', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(fakeApi(), const ReportsScreen(), testUser()));
    await tester.pumpAndSettle();

    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Behaviour'), findsOneWidget);
    expect(find.text('Payments'), findsNothing);
    expect(find.text('75%'), findsWidgets);
    expect(find.text('Below 80%'), findsOneWidget);
    expect(find.text('Bilal Khan'), findsOneWidget);
    expect(find.text('Saturday Beginners A · 1 of 2 attended'), findsOneWidget);
    // A low percentage is marked with an icon as well as colour.
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });

  testWidgets('with payment access the payments tab lists who still owes', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(fakeApi(), const ReportsScreen(), adminUser()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();

    expect(find.text('Still owing'), findsOneWidget);
    expect(find.text('Bilal Khan'), findsOneWidget);
    expect(find.text('Saturday Beginners A · 1 month'), findsOneWidget);
    expect(find.text('£25.00'), findsWidgets);
  });

  testWidgets('a student report shows fees only when the server sends them', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(fakeApi(), const StudentReportScreen(studentId: 's1'), testUser()));
    await tester.pumpAndSettle();

    expect(find.text('Report: Amina Rahman'), findsOneWidget);
    expect(find.text('Below 80%'), findsOneWidget);
    expect(find.text('3.8 of 5'), findsOneWidget);
    expect(find.text('Talking'), findsOneWidget);
    expect(find.text('Fees'), findsNothing);
  });

  testWidgets('with fees in the report they are shown with what is outstanding', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(fakeApi(withPayments: true), const StudentReportScreen(studentId: 's1'), adminUser()));
    await tester.pumpAndSettle();

    expect(find.text('Fees'), findsOneWidget);
    expect(find.text('£25.00'), findsOneWidget);
  });

  test('a student report needs report access', () {
    final noReports = testUser(permissions: const {Permissions.studentRead, Permissions.classRead});

    expect(resolveRedirect(session: AsyncData(noReports), location: '/students/s1/report'), Routes.dashboard);
    expect(resolveRedirect(session: AsyncData(testUser()), location: '/students/s1/report'), isNull);
  });
}
