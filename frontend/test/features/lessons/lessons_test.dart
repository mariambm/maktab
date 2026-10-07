import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/lessons/data/lesson_models.dart';
import 'package:maktab/features/lessons/data/lessons_repository.dart';
import 'package:maktab/features/lessons/presentation/attendance_register.dart';

import '../../helpers.dart';

Map<String, Object?> student(String id, String firstName, {String? status, int? minutesLate, String? reason}) => {
  'studentId': id,
  'firstName': firstName,
  'lastName': 'Test',
  'status': status,
  'minutesLate': minutesLate,
  'absenceReason': reason,
  'note': null,
};

Map<String, Object?> lessonJson({List<Map<String, Object?>>? students}) => {
  'id': 'l1',
  'classGroupId': 'c1',
  'className': 'Saturday Beginners A',
  'room': 'Room 1',
  'lessonDate': '2026-10-07',
  'startTime': '10:00:00',
  'endTime': '12:00:00',
  'status': 'PLANNED',
  'contentNotes': null,
  'teacherUserId': 'u1',
  'curriculumPeriod': null,
  'curriculumWeekNumber': null,
  'availableTopics': <Map<String, Object?>>[],
  'coveredTopicIds': <String>[],
  'students': students ?? [student('s1', 'Amina'), student('s2', 'Bilal'), student('s3', 'Yusuf')],
};

Widget app(FakeApi api, Widget child) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(testUser())),
  ],
  child: localized(Scaffold(body: SingleChildScrollView(child: child))),
);

void main() {
  test('the register is saved in one request, with minutes only for late and a reason only for absent', () async {
    final api = FakeApi((request) => (200, lessonJson()));
    await LessonsRepository(api.dio).saveAttendance('l1', const [
      AttendanceEntry(studentId: 's1', status: AttendanceStatuses.present),
      AttendanceEntry(studentId: 's2', status: AttendanceStatuses.late, minutesLate: 10),
      AttendanceEntry(
        studentId: 's3',
        status: AttendanceStatuses.absent,
        absenceReason: AbsenceReasons.sick,
        note: '  Called in  ',
      ),
    ]);

    expect(api.requests.single.path, '/api/lessons/l1/attendance');
    expect(api.requests.single.data, {
      'entries': [
        {'studentId': 's1', 'status': 'PRESENT'},
        {'studentId': 's2', 'status': 'LATE', 'minutesLate': 10},
        {'studentId': 's3', 'status': 'ABSENT', 'absenceReason': 'SICK', 'note': 'Called in'},
      ],
    });
  });

  test('a scheduled slot that nobody opened yet has no id, and opening it sends the slot', () async {
    final slot = {
      'id': null,
      'classGroupId': 'c1',
      'className': 'Saturday Beginners A',
      'room': 'Room 1',
      'lessonDate': '2026-10-07',
      'startTime': '10:00:00',
      'endTime': '12:00:00',
      'status': 'PLANNED',
      'classScheduleId': 'sch1',
      'studentCount': 3,
      'attendanceRecorded': 0,
    };
    final api = FakeApi((request) => request.method == 'GET' ? (200, [slot]) : (200, lessonJson()));
    final repository = LessonsRepository(api.dio);

    final today = await repository.onDate(DateTime(2026, 10, 7));
    expect(today.single.isOpened, isFalse);
    expect(today.single.attendanceComplete, isFalse);
    expect(api.requests.single.queryParameters['date'], '2026-10-07');

    await repository.open(
      OpenLessonDraft(classGroupId: 'c1', lessonDate: DateTime(2026, 10, 7), classScheduleId: 'sch1'),
    );
    expect(api.requests.last.path, '/api/lessons');
    expect(api.requests.last.data, {'classGroupId': 'c1', 'lessonDate': '2026-10-07', 'classScheduleId': 'sch1'});
  });

  test('changing a status drops the fields that do not belong to it', () {
    const late = AttendanceEntry(studentId: 's1', status: AttendanceStatuses.late, minutesLate: 15);

    expect(late.copyWith(status: AttendanceStatuses.present).minutesLate, isNull);
    expect(late.copyWith(note: 'Overslept').minutesLate, 15, reason: 'a note does not clear the minutes');
    expect(late.copyWith(status: AttendanceStatuses.absent, absenceReason: AbsenceReasons.sick).toJson(), {
      'studentId': 's1',
      'status': 'ABSENT',
      'absenceReason': 'SICK',
    });
  });

  testWidgets('everyone starts present, so only the exceptions need a tap', (tester) async {
    final api = FakeApi((request) => (200, lessonJson()));
    final lesson = LessonDetail.fromJson(lessonJson());
    await tester.pumpWidget(app(api, AttendanceRegister(lesson: lesson)));
    await tester.pumpAndSettle();

    // Bilal, the second student, is late; the other two stay present.
    await tester.tap(find.text('Late').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save attendance'));
    await tester.pumpAndSettle();

    expect(api.requests.single.data, {
      'entries': [
        {'studentId': 's1', 'status': 'PRESENT'},
        {'studentId': 's2', 'status': 'LATE', 'minutesLate': 5},
        {'studentId': 's3', 'status': 'PRESENT'},
      ],
    });
    expect(find.text('Attendance saved'), findsOne);
  });

  testWidgets('an absence reason is never guessed, and the mosque\'s own reasons can be picked', (tester) async {
    final api = FakeApi((request) => (200, lessonJson()));
    final lesson = LessonDetail.fromJson(lessonJson(students: [student('s1', 'Amina'), student('s2', 'Bilal')]));
    await tester.pumpWidget(app(api, AttendanceRegister(lesson: lesson)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Absent').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Absent').last);
    await tester.pumpAndSettle();
    expect(find.text('Choose a reason'), findsNWidgets(2));

    await tester.tap(find.text('Choose a reason').last);
    await tester.pumpAndSettle();
    for (final label in ['Authorised absence', 'Non authorised absence', 'Sick', 'Holiday', 'Not reading']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Not reading').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save attendance'));
    await tester.pumpAndSettle();

    expect(api.requests.single.data, {
      'entries': [
        {'studentId': 's1', 'status': 'ABSENT'},
        {'studentId': 's2', 'status': 'ABSENT', 'absenceReason': 'NOT_READING'},
      ],
    });
  });

  testWidgets('what was already recorded is what the register shows', (tester) async {
    final api = FakeApi((request) => (200, lessonJson()));
    final lesson = LessonDetail.fromJson(
      lessonJson(
        students: [
          student('s1', 'Amina', status: 'ABSENT', reason: 'SICK'),
          student('s2', 'Bilal', status: 'LATE', minutesLate: 20),
        ],
      ),
    );
    await tester.pumpWidget(app(api, AttendanceRegister(lesson: lesson)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save attendance'));
    await tester.pumpAndSettle();

    expect(api.requests.single.data, {
      'entries': [
        {'studentId': 's1', 'status': 'ABSENT', 'absenceReason': 'SICK'},
        {'studentId': 's2', 'status': 'LATE', 'minutesLate': 20},
      ],
    });
  });

  testWidgets('a teacher without permission to record sees the register but cannot change it', (tester) async {
    final api = FakeApi((request) => (200, lessonJson()));
    final lesson = LessonDetail.fromJson(lessonJson(students: [student('s1', 'Amina', status: 'PRESENT')]));
    await tester.pumpWidget(app(api, AttendanceRegister(lesson: lesson, readOnly: true)));
    await tester.pumpAndSettle();

    expect(find.text('Present'), findsOne);
    expect(find.text('Save attendance'), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
  });
}
