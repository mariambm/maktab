import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import 'behaviour_models.dart';

class BehaviourRepository {
  BehaviourRepository(this._dio);

  final Dio _dio;

  Future<LessonBehaviour> forLesson(String lessonId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/lessons/$lessonId/behaviour');
    return LessonBehaviour.fromJson(response.data!);
  });

  /// Saves the lesson's observations; only students with something noted are sent.
  Future<LessonBehaviour> save(String lessonId, Iterable<BehaviourObservation> observations) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/lessons/$lessonId/behaviour',
      data: {
        'entries': [for (final observation in observations.where((o) => !o.isEmpty)) observation.toJson()],
      },
    );
    return LessonBehaviour.fromJson(response.data!);
  });

  Future<List<StudentBehaviour>> forStudent(String studentId) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/behaviour', queryParameters: {'studentId': studentId});
    return response.data!.map((e) => StudentBehaviour.fromJson(e as Map<String, dynamic>)).toList();
  });
}

final behaviourRepositoryProvider = Provider<BehaviourRepository>(
  (ref) => BehaviourRepository(ref.watch(apiDioProvider)),
);

final lessonBehaviourProvider = FutureProvider.autoDispose.family<LessonBehaviour, String>(
  (ref, lessonId) => ref.watch(behaviourRepositoryProvider).forLesson(lessonId),
);

final studentBehaviourProvider = FutureProvider.autoDispose.family<List<StudentBehaviour>, String>(
  (ref, studentId) => ref.watch(behaviourRepositoryProvider).forStudent(studentId),
);
