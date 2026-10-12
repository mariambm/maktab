import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/page_result.dart';
import 'payment_models.dart';

/// Filters for one month's payments.
typedef PaymentFilter = ({String periodId, String? status, String? classId, String search});

class PaymentsRepository {
  PaymentsRepository(this._dio);

  final Dio _dio;

  Future<List<PaymentPeriod>> periods() => apiCall(() async {
    final response = await _dio.get<List<dynamic>>('/api/payment-periods');
    return response.data!.map((e) => PaymentPeriod.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<PaymentPeriod> period(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/payment-periods/$id');
    return PaymentPeriod.fromJson(response.data!);
  });

  Future<PaymentPeriod> createPeriod(DateTime month, double monthlyFee) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/payment-periods',
      data: {'month': monthToJson(month), 'monthlyFee': monthlyFee},
    );
    return PaymentPeriod.fromJson(response.data!);
  });

  Future<PaymentPeriod> changeFee(String id, double monthlyFee) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/payment-periods/$id',
      data: {'monthlyFee': monthlyFee},
    );
    return PaymentPeriod.fromJson(response.data!);
  });

  Future<StudentsAdded> addNewStudents(String id) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/payment-periods/$id/payments');
    return StudentsAdded.fromJson(response.data!);
  });

  Future<PageResult<Payment>> list(PaymentFilter filter, {int size = 200}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/payments',
      queryParameters: {
        'periodId': filter.periodId,
        'status': ?filter.status,
        'classId': ?filter.classId,
        if (filter.search.trim().isNotEmpty) 'search': filter.search.trim(),
        'size': size,
      },
    );
    return PageResult.fromJson(response.data!, Payment.fromJson);
  });

  /// A student's months, the latest first.
  Future<PageResult<Payment>> forStudent(String studentId, {int size = 24}) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/payments',
      queryParameters: {'studentId': studentId, 'size': size},
    );
    return PageResult.fromJson(response.data!, Payment.fromJson);
  });

  Future<Payment> update(String id, PaymentDraft draft) => apiCall(() async {
    final response = await _dio.put<Map<String, dynamic>>('/api/payments/$id', data: draft.toJson());
    return Payment.fromJson(response.data!);
  });

  Future<void> remove(String id) => apiCall(() async {
    await _dio.delete<void>('/api/payments/$id');
  });
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) => PaymentsRepository(ref.watch(apiDioProvider)));

final paymentPeriodsProvider = FutureProvider.autoDispose<List<PaymentPeriod>>(
  (ref) => ref.watch(paymentsRepositoryProvider).periods(),
);

final paymentPeriodProvider = FutureProvider.autoDispose.family<PaymentPeriod, String>(
  (ref, id) => ref.watch(paymentsRepositoryProvider).period(id),
);

final paymentsProvider = FutureProvider.autoDispose.family<PageResult<Payment>, PaymentFilter>(
  (ref, filter) => ref.watch(paymentsRepositoryProvider).list(filter),
);

final studentPaymentsProvider = FutureProvider.autoDispose.family<PageResult<Payment>, String>(
  (ref, studentId) => ref.watch(paymentsRepositoryProvider).forStudent(studentId),
);
