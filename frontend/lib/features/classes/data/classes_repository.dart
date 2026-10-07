import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/page_result.dart';
import 'class_models.dart';

class ClassesRepository {
  ClassesRepository(this._dio);

  final Dio _dio;

  Future<PageResult<ClassSummary>> list({String? search, bool? active}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/classes',
      queryParameters: {'size': 100, if (search != null && search.isNotEmpty) 'search': search, 'active': ?active},
    );
    return PageResult.fromJson(response.data!, ClassSummary.fromJson);
  });

  Future<ClassSummary> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/classes/$id');
    return ClassSummary.fromJson(response.data!);
  });

  Future<List<ClassStudent>> students(String id) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/classes/$id/students');
    return response.data!.map((e) => ClassStudent.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<ClassSummary> create(ClassDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/classes', data: draft.toJson());
    return ClassSummary.fromJson(response.data!);
  });

  Future<ClassSummary> update(String id, ClassDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/classes/$id', data: draft.toJson());
    return ClassSummary.fromJson(response.data!);
  });

  Future<ClassSummary> replaceTeachers(String id, Set<String> teacherIds) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/classes/$id/teachers',
      data: {'teacherIds': teacherIds.toList()},
    );
    return ClassSummary.fromJson(response.data!);
  });

  Future<ClassSummary> replaceSchedule(String id, List<ScheduleSlot> slots) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/classes/$id/schedule',
      data: {'slots': slots.map((s) => s.toJson()).toList()},
    );
    return ClassSummary.fromJson(response.data!);
  });

  Future<List<CurriculumLevel>> levels() => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/curriculum-levels');
    return response.data!.map((e) => CurriculumLevel.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<CurriculumLevel> createLevel(String name) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/curriculum-levels', data: {'name': name.trim()});
    return CurriculumLevel.fromJson(response.data!);
  });

  Future<List<TeacherRef>> teachers() => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/teachers');
    return response.data!.map((e) => TeacherRef.fromJson(e as Map<String, dynamic>)).toList();
  });
}

final classesRepositoryProvider = Provider<ClassesRepository>((ref) => ClassesRepository(ref.watch(apiDioProvider)));

/// Every class the user can see (all for administrators, assigned ones for teachers), active first.
final classesProvider = FutureProvider.autoDispose<List<ClassSummary>>((ref) async {
  final page = await ref.watch(classesRepositoryProvider).list();
  return [...page.items]..sort((a, b) => a.active == b.active ? 0 : (a.active ? -1 : 1));
});

final classProvider = FutureProvider.autoDispose.family<ClassSummary, String>(
  (ref, id) => ref.watch(classesRepositoryProvider).get(id),
);

final classStudentsProvider = FutureProvider.autoDispose.family<List<ClassStudent>, String>(
  (ref, id) => ref.watch(classesRepositoryProvider).students(id),
);

final curriculumLevelsProvider = FutureProvider.autoDispose<List<CurriculumLevel>>(
  (ref) => ref.watch(classesRepositoryProvider).levels(),
);

final teacherOptionsProvider = FutureProvider.autoDispose<List<TeacherRef>>(
  (ref) => ref.watch(classesRepositoryProvider).teachers(),
);
