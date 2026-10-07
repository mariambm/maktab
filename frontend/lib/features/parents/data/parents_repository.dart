import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/page_result.dart';
import 'parent_models.dart';

class ParentsRepository {
  ParentsRepository(this._dio);

  final Dio _dio;

  Future<PageResult<ParentGuardian>> list({String search = '', int page = 0, int size = 50}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/parents',
      queryParameters: {'page': page, 'size': size, if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    return PageResult.fromJson(response.data!, ParentGuardian.fromJson);
  });

  Future<ParentGuardian> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/parents/$id');
    return ParentGuardian.fromJson(response.data!);
  });

  Future<ParentGuardian> create(ParentDraft draft) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/parents', data: draft.toJson());
    return ParentGuardian.fromJson(response.data!);
  });

  Future<ParentGuardian> update(String id, ParentDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/parents/$id', data: draft.toJson());
    return ParentGuardian.fromJson(response.data!);
  });
}

final parentsRepositoryProvider = Provider<ParentsRepository>((ref) => ParentsRepository(ref.watch(apiDioProvider)));

final parentsProvider = FutureProvider.autoDispose.family<PageResult<ParentGuardian>, String>(
  (ref, search) => ref.watch(parentsRepositoryProvider).list(search: search),
);

final parentProvider = FutureProvider.autoDispose.family<ParentGuardian, String>(
  (ref, id) => ref.watch(parentsRepositoryProvider).get(id),
);
