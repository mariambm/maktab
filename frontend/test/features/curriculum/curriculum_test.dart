import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/api/api_providers.dart';
import 'package:maktab/core/auth/session_controller.dart';
import 'package:maktab/features/curriculum/data/curriculum_models.dart';
import 'package:maktab/features/curriculum/data/curriculum_repository.dart';
import 'package:maktab/features/curriculum/presentation/curriculum_period_screen.dart';

import '../../helpers.dart';

Map<String, Object?> periodJson() => {
  'id': 'p1',
  'curriculumLevelId': 'lv1',
  'curriculumLevelName': 'Qaida',
  'number': 2,
  'name': 'Qaida period 2',
  'startDate': '2026-09-21',
  'endDate': '2026-10-18',
  'weeks': [
    {
      'id': 'w1',
      'weekNumber': 1,
      'review': false,
      'topics': [
        {
          'id': 't1',
          'title': 'Letters alif to jim',
          'learningObjective': 'Recognise and sound each letter',
          'sortOrder': 0,
        },
      ],
    },
    {'id': 'w4', 'weekNumber': 4, 'review': true, 'topics': <Map<String, Object?>>[]},
  ],
};

Widget app(FakeApi api, Widget child) => ProviderScope(
  overrides: [
    apiDioProvider.overrideWithValue(api.dio),
    sessionControllerProvider.overrideWith(() => SignedInSession(adminUser())),
  ],
  child: localized(child),
);

void main() {
  test('a period sends four weeks with the review week last and no end date', () async {
    final api = FakeApi((request) => (201, periodJson()));
    await CurriculumRepository(api.dio).create(
      CurriculumPeriodDraft(
        curriculumLevelId: 'lv1',
        number: 2,
        name: ' Qaida period 2 ',
        startDate: DateTime(2026, 9, 21),
        weeks: [
          for (var week = 1; week <= curriculumWeeksPerPeriod; week++)
            CurriculumWeekDraft(
              weekNumber: week,
              review: week == curriculumReviewWeek,
              topics: [if (week == 1) const LessonTopicDraft(title: 'Letters alif to jim', learningObjective: '  ')],
            ),
        ],
      ),
    );

    final body = api.requests.single.data as Map<String, Object?>;
    expect(api.requests.single.path, '/api/curriculum/periods');
    expect(body['startDate'], '2026-09-21');
    expect(body['name'], 'Qaida period 2');
    expect(body.containsKey('endDate'), isFalse, reason: 'the end date follows from the start date');
    final weeks = body['weeks']! as List<Object?>;
    expect(weeks.length, 4);
    expect((weeks.first as Map)['topics'], [
      {'title': 'Letters alif to jim', 'learningObjective': null},
    ]);
    expect([for (final week in weeks) (week as Map)['review']], [false, false, false, true]);
  });

  testWidgets('a period shows its weeks with the review week marked', (tester) async {
    final api = FakeApi((request) => (200, periodJson()));
    await tester.pumpWidget(app(api, const CurriculumPeriodScreen(periodId: 'p1')));
    await tester.pumpAndSettle();

    expect(find.text('Week 1'), findsOne);
    expect(find.text('Letters alif to jim'), findsOne);
    expect(find.text('Recognise and sound each letter'), findsOne);
    expect(find.text('Review week'), findsOne);
    expect(find.text('No topics yet'), findsOne, reason: 'week 4 has no topics yet');
  });
}
