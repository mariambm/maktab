import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import 'uniform_models.dart';

class UniformRepository {
  UniformRepository(this._dio);

  final Dio _dio;

  Future<LessonUniform> forLesson(String lessonId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/lessons/$lessonId/uniform');
    return LessonUniform.fromJson(response.data!);
  });

  /// Saves the lesson's uniform records; a student left out no longer has one.
  Future<LessonUniform> save(String lessonId, Iterable<UniformEntry> entries) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/lessons/$lessonId/uniform',
      data: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    return LessonUniform.fromJson(response.data!);
  });

  Future<List<StudentUniform>> forStudent(String studentId) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/uniform', queryParameters: {'studentId': studentId});
    return response.data!.map((e) => StudentUniform.fromJson(e as Map<String, dynamic>)).toList();
  });
}

final uniformRepositoryProvider = Provider<UniformRepository>((ref) => UniformRepository(ref.watch(apiDioProvider)));

final lessonUniformProvider = FutureProvider.autoDispose.family<LessonUniform, String>(
  (ref, lessonId) => ref.watch(uniformRepositoryProvider).forLesson(lessonId),
);

final studentUniformProvider = FutureProvider.autoDispose.family<List<StudentUniform>, String>(
  (ref, studentId) => ref.watch(uniformRepositoryProvider).forStudent(studentId),
);
