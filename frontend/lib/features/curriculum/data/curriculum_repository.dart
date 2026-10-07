import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import 'curriculum_models.dart';

class CurriculumRepository {
  CurriculumRepository(this._dio);

  final Dio _dio;

  Future<List<CurriculumPeriodSummary>> list({String? levelId}) => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/curriculum/periods', queryParameters: {'levelId': ?levelId});
    return response.data!.map((e) => CurriculumPeriodSummary.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<CurriculumPeriod> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/curriculum/periods/$id');
    return CurriculumPeriod.fromJson(response.data!);
  });

  Future<CurriculumPeriod> create(CurriculumPeriodDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/curriculum/periods', data: draft.toJson());
    return CurriculumPeriod.fromJson(response.data!);
  });

  Future<CurriculumPeriod> update(String id, CurriculumPeriodDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/curriculum/periods/$id', data: draft.toJson());
    return CurriculumPeriod.fromJson(response.data!);
  });
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>(
  (ref) => CurriculumRepository(ref.watch(apiDioProvider)),
);

/// The periods of one level, or of every level when [levelId] is null, newest first.
final curriculumPeriodsProvider = FutureProvider.autoDispose.family<List<CurriculumPeriodSummary>, String?>(
  (ref, levelId) => ref.watch(curriculumRepositoryProvider).list(levelId: levelId),
);

final curriculumPeriodProvider = FutureProvider.autoDispose.family<CurriculumPeriod, String>(
  (ref, id) => ref.watch(curriculumRepositoryProvider).get(id),
);
