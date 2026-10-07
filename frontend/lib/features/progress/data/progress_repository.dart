import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import 'progress_models.dart';
import 'target_models.dart';

class ProgressRepository {
  ProgressRepository(this._dio);

  final Dio _dio;

  Future<List<ProgressScaleLevel>> scale() => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/progress/scale');
    return response.data!.map((e) => ProgressScaleLevel.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<LessonProgress> forLesson(String lessonId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/lessons/$lessonId/progress');
    return LessonProgress.fromJson(response.data!);
  });

  /// Saves the scores of one subject; a student left out of [scores] no longer has a score for it.
  Future<LessonProgress> save(String lessonId, String subject, Map<String, double> scores) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/lessons/$lessonId/progress',
      data: {
        'subject': subject,
        'entries': [
          for (final entry in scores.entries) {'studentId': entry.key, 'score': entry.value},
        ],
      },
    );
    return LessonProgress.fromJson(response.data!);
  });

  Future<List<StudentScore>> forStudent(String studentId) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/progress', queryParameters: {'studentId': studentId});
    return response.data!.map((e) => StudentScore.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<List<StudentTarget>> targets(String studentId) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/targets', queryParameters: {'studentId': studentId});
    return response.data!.map((e) => StudentTarget.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<StudentTarget> createTarget(TargetDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/targets', data: draft.toJson());
    return StudentTarget.fromJson(response.data!);
  });

  Future<StudentTarget> updateTarget(String id, TargetDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/targets/$id', data: draft.toJson());
    return StudentTarget.fromJson(response.data!);
  });

  Future<ClassProgress> classOverview(String classId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/progress/classes/$classId');
    return ClassProgress.fromJson(response.data!);
  });
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) => ProgressRepository(ref.watch(apiDioProvider)));

/// The scale changes rarely, so it is loaded once per session.
final progressScaleProvider = FutureProvider<List<ProgressScaleLevel>>(
  (ref) => ref.watch(progressRepositoryProvider).scale(),
);

final lessonProgressProvider = FutureProvider.autoDispose.family<LessonProgress, String>(
  (ref, lessonId) => ref.watch(progressRepositoryProvider).forLesson(lessonId),
);

final studentProgressProvider = FutureProvider.autoDispose.family<List<StudentScore>, String>(
  (ref, studentId) => ref.watch(progressRepositoryProvider).forStudent(studentId),
);

/// All of a student's targets, the latest period first.
final studentTargetsProvider = FutureProvider.autoDispose.family<List<StudentTarget>, String>(
  (ref, studentId) => ref.watch(progressRepositoryProvider).targets(studentId),
);

final classProgressProvider = FutureProvider.autoDispose.family<ClassProgress, String>(
  (ref, classId) => ref.watch(progressRepositoryProvider).classOverview(classId),
);
