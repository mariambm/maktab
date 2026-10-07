import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/curriculum/data/curriculum_models.dart';
import 'package:maktab/features/progress/data/target_models.dart';
import 'package:maktab/features/progress/presentation/progress_screen.dart';
import 'package:maktab/features/progress/presentation/target_sheet.dart';

import '../../helpers.dart';

const scale = [
  {'score': 2.0, 'label': 'Low'},
  {'score': 3.0, 'label': 'Medium'},
  {'score': 3.5, 'label': 'Almost Good'},
  {'score': 4.0, 'label': 'Good'},
  {'score': 4.5, 'label': 'Very Good'},
  {'score': 5.0, 'label': 'Excellent'},
];

const periodJson = {
  'id': 'p2',
  'curriculumLevelId': 'lv1',
  'number': 2,
  'name': 'Period 2',
  'startDate': '2026-09-21',
  'endDate': '2026-10-18',
};

Map<String, Object?> targetJson({String id = 't1', int? current = 80}) => {
  'id': id,
  'studentId': 's1',
  'period': periodJson,
  'subject': 'QURAN_RECITATION',
  'description': 'Recite Surah Al-Fatiha from memory',
  'targetPercentage': 85,
  'currentPercentage': current,
  'progressScore': 4.0,
  'progressLabel': 'Good',
  'teacherNote': 'Needs more practice with madd',
};

Widget app(FakeApi api, Widget child) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(testUser())),
  ],
  child: localized(child),
);

void main() {
  test('a new target sends its student and period; an edit sends only what can change', () {
    const create = TargetDraft(
      studentId: 's1',
      curriculumPeriodId: 'p2',
      description: '  Recite Surah Al-Fatiha  ',
      targetPercentage: 85,
      teacherNote: ' ',
    );
    expect(create.toJson(), {
      'studentId': 's1',
      'curriculumPeriodId': 'p2',
      'description': 'Recite Surah Al-Fatiha',
      'targetPercentage': 85,
    });
    const edit = TargetDraft(description: 'Recite', currentPercentage: 60, progressScore: 3.5);
    expect(edit.toJson(), {'description': 'Recite', 'currentPercentage': 60, 'progressScore': 3.5});
  });

  testWidgets('a teacher sets a target for the period with percentages and a score', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final api = FakeApi((request) => request.path == '/api/progress/scale' ? (200, scale) : (201, targetJson()));
    final period = CurriculumPeriodSummary.fromJson(periodJson);
    await tester.pumpWidget(
      app(
        api,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTargetSheet(context, studentId: 's1', periods: [period], initialPeriodId: 'p2'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Describe the target'), findsOne);

    await tester.enterText(find.byKey(const Key('target.description')), 'Recite Surah Al-Fatiha from memory');
    await tester.enterText(find.byKey(const Key('target.target')), '85');
    await tester.enterText(find.byKey(const Key('target.current')), '120');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('0 to 100'), findsOne);

    await tester.enterText(find.byKey(const Key('target.current')), '80');
    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pumpAndSettle();
    expect(find.text('Good'), findsOne);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final post = api.requests.singleWhere((r) => r.method == 'POST');
    expect(post.path, '/api/targets');
    expect(post.data, {
      'studentId': 's1',
      'curriculumPeriodId': 'p2',
      'description': 'Recite Surah Al-Fatiha from memory',
      'targetPercentage': 85,
      'currentPercentage': 80,
      'progressScore': 4.0,
    });
    expect(find.text('Target saved'), findsOne);
  });

  testWidgets('the Progress screen shows the period, each student\'s latest score and their targets', (tester) async {
    final api = FakeApi((request) {
      if (request.path == '/api/classes') {
        return (
          200,
          {
            'items': [
              {
                'id': 'c1',
                'name': 'Saturday Beginners A',
                'curriculumLevel': {'id': 'lv1', 'name': 'Beginners', 'sortOrder': 1},
                'room': 'Room 1',
                'active': true,
                'studentCount': 2,
                'teachers': <Object>[],
                'schedule': <Object>[],
              },
            ],
            'page': 0,
            'size': 100,
            'totalItems': 1,
          },
        );
      }
      return (
        200,
        {
          'classId': 'c1',
          'className': 'Saturday Beginners A',
          'period': periodJson,
          'students': [
            {
              'studentId': 's1',
              'firstName': 'Amina',
              'lastName': 'Test',
              'latestScore': {
                'lessonDate': '2026-10-03',
                'subject': 'QURAN_RECITATION',
                'score': 4.5,
                'label': 'Very Good',
              },
              'targets': [targetJson()],
            },
            {'studentId': 's2', 'firstName': 'Bilal', 'lastName': 'Test', 'latestScore': null, 'targets': <Object>[]},
          ],
        },
      );
    });
    await tester.pumpWidget(app(api, const ProgressScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Period 2'), findsOne);
    expect(find.textContaining('Latest score: 4.5 Very Good · Quran Recitation'), findsOne);
    expect(find.text('Recite Surah Al-Fatiha from memory'), findsOne);
    expect(find.textContaining('Target 85% · now 80%'), findsOne);
    expect(find.text('No score yet this period'), findsOne);
    expect(find.byTooltip('Add target'), findsNWidgets(2));
  });
}
