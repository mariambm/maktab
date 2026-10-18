import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_call.dart';
import '../../../core/api/api_providers.dart';
import '../../lessons/data/lesson_models.dart';
import 'report_models.dart';

/// The dates a report covers and, optionally, one class.
typedef ReportFilter = ({DateTime from, DateTime to, String? classId});

/// A student's report over a date range.
typedef StudentReportFilter = ({String studentId, DateTime from, DateTime to});

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _query(ReportFilter filter) => {
    'from': isoDate(filter.from),
    'to': isoDate(filter.to),
    'classId': ?filter.classId,
  };

  Future<DashboardFigures> dashboard() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports/dashboard');
    return DashboardFigures.fromJson(response.data!);
  });

  Future<AttendanceReport> attendance(ReportFilter filter) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports/attendance', queryParameters: _query(filter));
    return AttendanceReport.fromJson(response.data!);
  });

  Future<ProgressReport> progress(String? classId) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reports/progress',
      queryParameters: {'classId': ?classId},
    );
    return ProgressReport.fromJson(response.data!);
  });

  Future<BehaviourReport> behaviour(ReportFilter filter) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports/behaviour', queryParameters: _query(filter));
    return BehaviourReport.fromJson(response.data!);
  });

  Future<PaymentReport> payments() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/reports/payments');
    return PaymentReport.fromJson(response.data!);
  });

  Future<StudentReport> student(StudentReportFilter filter) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/reports/students/${filter.studentId}',
      queryParameters: {'from': isoDate(filter.from), 'to': isoDate(filter.to)},
    );
    return StudentReport.fromJson(response.data!);
  });
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) => ReportsRepository(ref.watch(apiDioProvider)));

final dashboardFiguresProvider = FutureProvider.autoDispose<DashboardFigures>(
  (ref) => ref.watch(reportsRepositoryProvider).dashboard(),
);

final attendanceReportProvider = FutureProvider.autoDispose.family<AttendanceReport, ReportFilter>(
  (ref, filter) => ref.watch(reportsRepositoryProvider).attendance(filter),
);

final progressReportProvider = FutureProvider.autoDispose.family<ProgressReport, String?>(
  (ref, classId) => ref.watch(reportsRepositoryProvider).progress(classId),
);

final behaviourReportProvider = FutureProvider.autoDispose.family<BehaviourReport, ReportFilter>(
  (ref, filter) => ref.watch(reportsRepositoryProvider).behaviour(filter),
);

final paymentReportProvider = FutureProvider.autoDispose<PaymentReport>(
  (ref) => ref.watch(reportsRepositoryProvider).payments(),
);

final studentReportProvider = FutureProvider.autoDispose.family<StudentReport, StudentReportFilter>(
  (ref, filter) => ref.watch(reportsRepositoryProvider).student(filter),
);
