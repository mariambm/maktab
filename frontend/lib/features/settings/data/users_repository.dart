import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/errors/api_exception.dart';
import 'user_summary.dart';

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<UserSummary>> list({String? search}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/users',
        queryParameters: {'size': 100, if (search != null && search.isNotEmpty) 'search': search},
      );
      final items = response.data!['items'] as List<dynamic>;
      return items.map((e) => UserSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) => UsersRepository(ref.watch(apiDioProvider)));

final usersProvider = FutureProvider.autoDispose<List<UserSummary>>(
  (ref) => ref.watch(usersRepositoryProvider).list(),
);
