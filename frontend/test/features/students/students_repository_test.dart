import 'package:flutter_test/flutter_test.dart';
import 'package:maktab/core/errors/api_exception.dart';
import 'package:maktab/features/students/data/student_models.dart';
import 'package:maktab/features/students/data/students_repository.dart';

import '../../helpers.dart';

Map<String, dynamic> studentJson({String id = 's1'}) => {
  'id': id,
  'firstName': 'Amina',
  'lastName': 'Amrani',
  'dateOfBirth': '2017-03-14',
  'gender': null,
  'status': 'ACTIVE',
  'joinedOn': '2026-09-01',
  'currentClass': null,
  'parents': <Object>[],
};

void main() {
  test('list sends only the filters that are set', () async {
    final api = FakeApi((_) => (200, {'items': <Object>[], 'page': 0, 'size': 50, 'totalItems': 0}));
    final repository = StudentsRepository(api.dio);

    await repository.list((search: '  amina ', classId: null, status: 'ACTIVE'));

    final query = api.requests.single.queryParameters;
    expect(api.requests.single.path, '/api/students');
    expect(query['search'], 'amina');
    expect(query['status'], 'ACTIVE');
    expect(query.containsKey('classId'), isFalse);
  });

  test('create sends dates as yyyy-MM-dd with class and parent links', () async {
    final api = FakeApi((_) => (201, studentJson()));
    final repository = StudentsRepository(api.dio);

    await repository.create(
      StudentDraft(
        firstName: ' Amina ',
        lastName: 'Amrani',
        dateOfBirth: DateTime(2017, 3, 4),
        joinedOn: DateTime(2026, 9, 1),
        notes: '  ',
        classId: 'c1',
        parents: const [ParentLink(parentId: 'p1', relationship: 'MOTHER', primaryContact: true)],
      ),
    );

    final body = api.requests.single.data as Map<String, dynamic>;
    expect(body['firstName'], 'Amina');
    expect(body['dateOfBirth'], '2017-03-04');
    expect(body['joinedOn'], '2026-09-01');
    expect(body['notes'], isNull);
    expect(body['classId'], 'c1');
    expect(body['parents'], [
      {'parentId': 'p1', 'relationship': 'MOTHER', 'primaryContact': true},
    ]);
  });

  test('moving class posts the new class and start date', () async {
    final api = FakeApi(
      (_) => (
        201,
        {
          'id': 'e1',
          'classGroup': {'id': 'c2', 'name': 'B'},
          'startDate': '2026-10-07',
          'endDate': null,
        },
      ),
    );
    final repository = StudentsRepository(api.dio);

    final enrollment = await repository.moveToClass('s1', 'c2', DateTime(2026, 10, 7));

    expect(api.requests.single.path, '/api/students/s1/enrollments');
    expect(api.requests.single.data, {'classId': 'c2', 'startDate': '2026-10-07'});
    expect(enrollment.classGroup.name, 'B');
  });

  test('a 404 for a student outside your classes becomes an ApiException', () async {
    final api = FakeApi((_) => (404, {'status': 404, 'error': 'NOT_FOUND', 'message': 'Student not found'}));
    final repository = StudentsRepository(api.dio);

    expect(() => repository.get('other'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_FOUND')));
  });
}
