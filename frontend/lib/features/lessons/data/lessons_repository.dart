import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import 'lesson_models.dart';

class LessonsRepository {
  LessonsRepository(this._dio);

  final Dio _dio;

  Future<List<LessonSummary>> onDate(DateTime date) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/lessons/today', queryParameters: {'date': isoDate(date)});
    return response.data!.map((e) => LessonSummary.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<LessonDetail> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/lessons/$id');
    return LessonDetail.fromJson(response.data!);
  });

  /// Opens the lesson, or returns the one already opened for that class, date and time.
  Future<LessonDetail> open(OpenLessonDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/lessons', data: draft.toJson());
    return LessonDetail.fromJson(response.data!);
  });

  Future<LessonDetail> update(String id, LessonUpdateDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/lessons/$id', data: draft.toJson());
    return LessonDetail.fromJson(response.data!);
  });

  /// Saves the whole register in one request.
  Future<LessonDetail> saveAttendance(String id, List<AttendanceEntry> entries) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/lessons/$id/attendance',
      data: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    return LessonDetail.fromJson(response.data!);
  });

  Future<AttendanceStatistics> statisticsForStudent(String studentId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/attendance/statistics',
      queryParameters: {'studentId': studentId},
    );
    return AttendanceStatistics.fromJson(response.data!);
  });

  Future<List<StudentAttendance>> forStudent(String studentId) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/attendance', queryParameters: {'studentId': studentId});
    return response.data!.map((e) => StudentAttendance.fromJson(e as Map<String, dynamic>)).toList();
  });
}

final lessonsRepositoryProvider = Provider<LessonsRepository>((ref) => LessonsRepository(ref.watch(apiDioProvider)));

/// The lessons and scheduled slots of one day for the classes the user can see.
final lessonsOnDateProvider = FutureProvider.autoDispose.family<List<LessonSummary>, DateTime>(
  (ref, date) => ref.watch(lessonsRepositoryProvider).onDate(date),
);

final lessonProvider = FutureProvider.autoDispose.family<LessonDetail, String>(
  (ref, id) => ref.watch(lessonsRepositoryProvider).get(id),
);

final studentAttendanceStatisticsProvider = FutureProvider.autoDispose.family<AttendanceStatistics, String>(
  (ref, studentId) => ref.watch(lessonsRepositoryProvider).statisticsForStudent(studentId),
);
