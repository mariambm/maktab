import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/page_result.dart';
import 'student_models.dart';

/// Filters for the students list. A record, so Riverpod caches one result per distinct filter.
typedef StudentFilter = ({String search, String? classId, String? status});

class StudentsRepository {
  StudentsRepository(this._dio);

  final Dio _dio;

  Future<PageResult<StudentSummary>> list(StudentFilter filter, {int page = 0, int size = 50}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/students',
      queryParameters: {
        'page': page,
        'size': size,
        if (filter.search.trim().isNotEmpty) 'search': filter.search.trim(),
        'classId': ?filter.classId,
        'status': ?filter.status,
      },
    );
    return PageResult.fromJson(response.data!, StudentSummary.fromJson);
  });

  Future<StudentDetail> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/students/$id');
    return StudentDetail.fromJson(response.data!);
  });

  Future<StudentDetail> create(StudentDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/students',
      data: {..._details(draft), 'classId': draft.classId, 'parents': draft.parents.map((p) => p.toJson()).toList()},
    );
    return StudentDetail.fromJson(response.data!);
  });

  Future<StudentDetail> update(String id, StudentDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/students/$id', data: _details(draft));
    return StudentDetail.fromJson(response.data!);
  });

  Future<StudentDetail> setStatus(String id, String status) => apiCall(() async {
    final response = await _dio.patch<Map<String, dynamic>>('/api/students/$id/status', data: {'status': status});
    return StudentDetail.fromJson(response.data!);
  });

  Future<StudentDetail> replaceParents(String id, List<ParentLink> parents) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/students/$id/parents',
      data: {'parents': parents.map((p) => p.toJson()).toList()},
    );
    return StudentDetail.fromJson(response.data!);
  });

  Future<List<Enrollment>> enrollments(String id) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/students/$id/enrollments');
    return response.data!.map((e) => Enrollment.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<Enrollment> moveToClass(String id, String classId, DateTime startDate) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/students/$id/enrollments',
      data: {'classId': classId, 'startDate': apiDate(startDate)},
    );
    return Enrollment.fromJson(response.data!);
  });

  Future<void> removeFromClass(String id) => apiCall(() => _dio.delete<void>('/api/students/$id/enrollments/current'));

  static Map<String, dynamic> _details(StudentDraft draft) => {
    'firstName': draft.firstName.trim(),
    'lastName': draft.lastName.trim(),
    'dateOfBirth': apiDate(draft.dateOfBirth),
    'gender': draft.gender,
    'joinedOn': apiDate(draft.joinedOn),
    'notes': draft.notes == null || draft.notes!.trim().isEmpty ? null : draft.notes!.trim(),
  };
}

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) => StudentsRepository(ref.watch(apiDioProvider)));

final studentsProvider = FutureProvider.autoDispose.family<PageResult<StudentSummary>, StudentFilter>(
  (ref, filter) => ref.watch(studentsRepositoryProvider).list(filter),
);

final studentProvider = FutureProvider.autoDispose.family<StudentDetail, String>(
  (ref, id) => ref.watch(studentsRepositoryProvider).get(id),
);

final enrollmentsProvider = FutureProvider.autoDispose.family<List<Enrollment>, String>(
  (ref, id) => ref.watch(studentsRepositoryProvider).enrollments(id),
);
