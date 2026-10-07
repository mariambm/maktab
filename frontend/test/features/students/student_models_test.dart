import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/features/students/data/student_models.dart';

void main() {
  test('parses a student with class and parents', () {
    final student = StudentDetail.fromJson({
      'id': 's1',
      'firstName': 'Amina',
      'lastName': 'Amrani',
      'dateOfBirth': '2017-03-14',
      'gender': 'FEMALE',
      'status': 'ACTIVE',
      'joinedOn': '2026-09-01',
      'leftOn': null,
      'notes': null,
      'currentClass': {'id': 'c1', 'name': 'Saturday Qaida B'},
      'parents': [
        {
          'parentId': 'p1',
          'firstName': 'Fatima',
          'lastName': 'Amrani',
          'phone': '+31 6 1234 5678',
          'email': null,
          'relationship': 'MOTHER',
          'primaryContact': true,
        },
      ],
    });

    expect(student.displayName, 'Amina Amrani');
    expect(student.isActive, isTrue);
    expect(student.currentClass?.name, 'Saturday Qaida B');
    expect(student.parents.single.primaryContact, isTrue);
    expect(student.dateOfBirth, DateTime(2017, 3, 14));
  });

  test('a student without a class has a null current class', () {
    final student = StudentSummary.fromJson({
      'id': 's1',
      'firstName': 'Adam',
      'lastName': 'Bakkali',
      'dateOfBirth': '2018-01-01',
      'status': 'INACTIVE',
      'currentClass': null,
    });
    expect(student.currentClass, isNull);
    expect(student.isActive, isFalse);
  });

  test('age counts whole years and respects the birthday', () {
    final birth = DateTime(2017, 3, 14);
    expect(ageOn(birth, DateTime(2026, 3, 13)), 8);
    expect(ageOn(birth, DateTime(2026, 3, 14)), 9);
  });

  test('the current enrolment is the one without an end date', () {
    final current = Enrollment.fromJson({
      'id': 'e1',
      'classGroup': {'id': 'c1', 'name': 'A'},
      'startDate': '2026-10-01',
      'endDate': null,
    });
    final old = Enrollment.fromJson({
      'id': 'e0',
      'classGroup': {'id': 'c0', 'name': 'B'},
      'startDate': '2026-09-01',
      'endDate': '2026-10-01',
    });
    expect(current.isCurrent, isTrue);
    expect(old.isCurrent, isFalse);
  });
}
