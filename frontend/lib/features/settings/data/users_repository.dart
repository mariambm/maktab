import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/page_result.dart';
import 'user_summary.dart';

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<PageResult<UserSummary>> list({String search = '', int page = 0, int size = 100}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/users',
      queryParameters: {'page': page, 'size': size, if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    return PageResult.fromJson(response.data!, UserSummary.fromJson);
  });

  Future<UserSummary> get(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/users/$id');
    return UserSummary.fromJson(response.data!);
  });

  Future<CreatedUser> create(UserDraft draft, Set<String> roles) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/users',
      data: {...draft.toJson(), 'roles': roles.toList()},
    );
    return CreatedUser.fromJson(response.data!);
  });

  Future<UserSummary> update(String id, UserDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/users/$id', data: draft.toJson());
    return UserSummary.fromJson(response.data!);
  });

  Future<UserSummary> setActive(String id, {required bool active}) => apiCall(() async {
    final response = await _dio.patch<Map<String, dynamic>>('/api/users/$id/status', data: {'active': active});
    return UserSummary.fromJson(response.data!);
  });

  Future<UserSummary> replaceRoles(String id, Set<String> roles) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/users/$id/roles', data: {'roles': roles.toList()});
    return UserSummary.fromJson(response.data!);
  });

  Future<UserSummary> replacePermissions(String id, Set<String> permissions) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/users/$id/permissions',
      data: {'permissions': permissions.toList()},
    );
    return UserSummary.fromJson(response.data!);
  });

  Future<CreatedUser> resetPassword(String id) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/users/$id/password-reset');
    return CreatedUser.fromJson(response.data!);
  });
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) => UsersRepository(ref.watch(apiDioProvider)));

final usersProvider = FutureProvider.autoDispose.family<PageResult<UserSummary>, String>(
  (ref, search) => ref.watch(usersRepositoryProvider).list(search: search),
);

final userProvider = FutureProvider.autoDispose.family<UserSummary, String>(
  (ref, id) => ref.watch(usersRepositoryProvider).get(id),
);
