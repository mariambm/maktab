import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/features/classes/data/class_models.dart';
import 'package:maktab/features/classes/presentation/class_labels.dart';
import 'package:maktab/l10n/generated/app_localizations_en.dart';

void main() {
  test('parses a class with level, teachers and schedule', () {
    final c = ClassSummary.fromJson({
      'id': 'c1',
      'name': 'Saturday Qaida B',
      'curriculumLevel': {'id': 'l1', 'name': 'Qaida', 'sortOrder': 2},
      'room': null,
      'active': true,
      'studentCount': 5,
      'teachers': [
        {'id': 't1', 'firstName': 'Omar', 'lastName': 'El Amrani'},
      ],
      'schedule': [
        {'weekday': 'SATURDAY', 'startTime': '10:00:00', 'endTime': '12:00:00'},
      ],
    });

    expect(c.curriculumLevel.name, 'Qaida');
    expect(c.teachers.single.displayName, 'Omar El Amrani');
    expect(c.schedule.single.weekdayIndex, 5);
    expect(scheduleText(c.schedule, AppLocalizationsEn()), 'Saturday 10:00–12:00');
  });

  test('the class draft trims the name and sends a blank room as null', () {
    const draft = ClassDraft(name: ' Quran C ', curriculumLevelId: 'l1', room: '  ');
    expect(draft.toJson(), {'name': 'Quran C', 'curriculumLevelId': 'l1', 'room': null, 'active': true});
  });
}
