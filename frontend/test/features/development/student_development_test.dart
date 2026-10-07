import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/behaviour/data/behaviour_models.dart';
import 'package:maktab/features/behaviour/presentation/behaviour_recorder.dart';
import 'package:maktab/features/behaviour/presentation/student_behaviour_card.dart';
import 'package:maktab/features/lessons/data/lesson_models.dart';
import 'package:maktab/features/progress/data/progress_models.dart';
import 'package:maktab/features/progress/data/progress_repository.dart';
import 'package:maktab/features/progress/presentation/progress_recorder.dart';
import 'package:maktab/features/uniform/presentation/uniform_recorder.dart';

import '../../helpers.dart';

const scale = [
  {'score': 2.0, 'label': 'Low'},
  {'score': 3.0, 'label': 'Medium'},
  {'score': 3.5, 'label': 'Almost Good'},
  {'score': 4.0, 'label': 'Good'},
  {'score': 4.5, 'label': 'Very Good'},
  {'score': 5.0, 'label': 'Excellent'},
];

Map<String, Object?> student(String id, String firstName, {String? status}) => {
  'studentId': id,
  'firstName': firstName,
  'lastName': 'Test',
  'status': status,
  'minutesLate': null,
  'absenceReason': null,
  'note': null,
};

LessonDetail lesson({List<Map<String, Object?>>? students}) => LessonDetail.fromJson({
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
  'students': students ?? [student('s1', 'Amina', status: 'PRESENT'), student('s2', 'Bilal', status: 'ABSENT')],
});

/// Answers the lesson's GETs with nothing recorded yet and echoes saves as empty.
FakeApi emptyLessonApi() => FakeApi((request) {
  final path = request.path;
  if (path == '/api/progress/scale') {
    return (200, scale);
  }
  if (path.endsWith('/progress')) {
    return (200, {'lessonId': 'l1', 'scores': <Object>[]});
  }
  if (path.endsWith('/behaviour')) {
    return (200, {'lessonId': 'l1', 'observations': <Object>[]});
  }
  return (200, {'lessonId': 'l1', 'records': <Object>[]});
});

Widget app(FakeApi api, Widget child) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(testUser())),
  ],
  child: localized(Scaffold(body: SingleChildScrollView(child: child))),
);

void main() {
  test('scores are shown without a needless decimal', () {
    expect(formatScore(4), '4');
    expect(formatScore(3.5), '3.5');
  });

  test('saving progress sends one subject with a score per student', () async {
    final api = FakeApi((request) => (200, {'lessonId': 'l1', 'scores': <Object>[]}));
    await ProgressRepository(api.dio).save('l1', 'QURAN_RECITATION', {'s1': 3.5, 's2': 5});

    expect(api.requests.single.method, 'PUT');
    expect(api.requests.single.path, '/api/lessons/l1/progress');
    expect(api.requests.single.data, {
      'subject': 'QURAN_RECITATION',
      'entries': [
        {'studentId': 's1', 'score': 3.5},
        {'studentId': 's2', 'score': 5.0},
      ],
    });
  });

  test('behaviour is sent in the mosque\'s order and empty observations are left out', () {
    const noted = BehaviourObservation(studentId: 's1', behaviours: ['TALKING', 'RESPECTFUL'], note: '  Calm  ');
    const nothing = BehaviourObservation(studentId: 's2', behaviours: [], note: ' ');

    expect(noted.toJson(), {
      'studentId': 's1',
      'behaviours': ['RESPECTFUL', 'TALKING'],
      'note': 'Calm',
    });
    expect(nothing.isEmpty, isTrue);
  });

  testWidgets('a teacher scores present students on the mosque\'s scale; absent students get no score', (tester) async {
    final api = emptyLessonApi();
    await tester.pumpWidget(app(api, ProgressRecorder(lesson: lesson())));
    await tester.pumpAndSettle();

    for (final score in ['2', '3', '3.5', '4', '4.5', '5']) {
      expect(find.widgetWithText(ChoiceChip, score), findsOne, reason: 'only Amina is present');
    }
    expect(find.text('Absent, no score'), findsOne);

    await tester.tap(find.widgetWithText(ChoiceChip, '4.5'));
    await tester.pumpAndSettle();
    expect(find.text('4.5 · Very Good'), findsOne);
    await tester.tap(find.text('Save progress'));
    await tester.pumpAndSettle();

    final save = api.requests.singleWhere((r) => r.method == 'PUT');
    expect(save.data, {
      'subject': 'QURAN_RECITATION',
      'entries': [
        {'studentId': 's1', 'score': 4.5},
      ],
    });
    expect(find.text('Progress saved'), findsOne);
  });

  testWidgets('several behaviours and a note can be noted for a student in one go', (tester) async {
    // A phone-sized screen, tall enough for the whole sheet.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final api = emptyLessonApi();
    await tester.pumpWidget(app(api, BehaviourRecorder(lesson: lesson())));
    await tester.pumpAndSettle();
    expect(find.text('Nothing noted'), findsOne);

    await tester.tap(find.text('Amina Test'));
    await tester.pumpAndSettle();
    for (final label in ['Good Quran recitation', 'Walking/running around', 'Learned Naat and/or speech']) {
      expect(find.text(label), findsOne);
    }
    await tester.tap(find.text('Listened to teacher'));
    await tester.tap(find.text('Talking'));
    await tester.enterText(find.byType(TextField), 'Settled after a reminder');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Listened to teacher · Talking · Settled after a reminder'), findsOne);

    await tester.tap(find.text('Save behaviour'));
    await tester.pumpAndSettle();
    expect(api.requests.singleWhere((r) => r.method == 'PUT').data, {
      'entries': [
        {
          'studentId': 's1',
          'behaviours': ['LISTENED_TO_TEACHER', 'TALKING'],
          'note': 'Settled after a reminder',
        },
      ],
    });
  });

  testWidgets('uniform is only recorded where the teacher tapped, with an optional reason', (tester) async {
    final api = emptyLessonApi();
    final students = [student('s1', 'Amina'), student('s2', 'Bilal'), student('s3', 'Yusuf', status: 'ABSENT')];
    await tester.pumpWidget(app(api, UniformRecorder(lesson: lesson(students: students))));
    await tester.pumpAndSettle();

    expect(find.text('Yusuf Test'), findsNothing, reason: 'absent students are not in the uniform list');
    await tester.tap(find.text('Not in order').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reason (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijab missing').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save uniform'));
    await tester.pumpAndSettle();

    expect(api.requests.singleWhere((r) => r.method == 'PUT').data, {
      'entries': [
        {'studentId': 's1', 'status': 'NOT_IN_ORDER', 'reason': 'HIJAB_MISSING'},
      ],
    });
  });

  testWidgets('"All in order" fills in the rest and keeps what was already noted', (tester) async {
    final api = emptyLessonApi();
    await tester.pumpWidget(
      app(api, UniformRecorder(lesson: lesson(students: [student('s1', 'Amina'), student('s2', 'Bilal')]))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Partly in order').first);
    await tester.tap(find.text('All in order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save uniform'));
    await tester.pumpAndSettle();

    expect(api.requests.singleWhere((r) => r.method == 'PUT').data, {
      'entries': [
        {'studentId': 's1', 'status': 'PARTIALLY_IN_ORDER'},
        {'studentId': 's2', 'status': 'IN_ORDER'},
      ],
    });
  });

  testWidgets('a student\'s behaviour history shows each observation with its date', (tester) async {
    final api = FakeApi(
      (request) => (
        200,
        [
          {
            'lessonId': 'l2',
            'lessonDate': '2026-10-07',
            'classGroupId': 'c1',
            'className': 'Saturday Beginners A',
            'behaviours': ['TALKING', 'BEEN_HELPFUL'],
            'note': null,
          },
        ],
      ),
    );
    await tester.pumpWidget(app(api, const StudentBehaviourCard(studentId: 's1')));
    await tester.pumpAndSettle();

    expect(api.requests.single.queryParameters, {'studentId': 's1'});
    expect(find.text('Been helpful · Talking'), findsOne);
    expect(find.textContaining('2026'), findsOne);
  });

  testWidgets('a teacher without permission sees the scores but cannot change them', (tester) async {
    final api = FakeApi((request) {
      if (request.path == '/api/progress/scale') {
        return (200, scale);
      }
      return (
        200,
        {
          'lessonId': 'l1',
          'scores': [
            {'studentId': 's1', 'subject': 'QURAN_RECITATION', 'score': 4.0, 'note': null},
          ],
        },
      );
    });
    await tester.pumpWidget(app(api, ProgressRecorder(lesson: lesson(), readOnly: true)));
    await tester.pumpAndSettle();

    expect(find.text('4 · Good'), findsOne);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Save progress'), findsNothing);
  });
}
