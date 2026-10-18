import 'package:json_annotation/json_annotation.dart';

import '../../curriculum/data/curriculum_models.dart';
import '../../payments/data/payment_models.dart';
import '../../progress/data/target_models.dart';

part 'report_models.g.dart';

/// Attendance counts for a class, a student or everything together. Present and late count as attended.
@JsonSerializable(createToJson: false)
class AttendanceCounts {
  const AttendanceCounts({
    required this.lessons,
    required this.records,
    required this.present,
    required this.late,
    required this.absent,
    this.attendancePercentage,
  });

  factory AttendanceCounts.fromJson(Map<String, dynamic> json) => _$AttendanceCountsFromJson(json);

  final int lessons;
  final int records;
  final int present;
  final int late;
  final int absent;
  final int? attendancePercentage;
}

@JsonSerializable(createToJson: false)
class AttendanceClassRow {
  const AttendanceClassRow({required this.classId, this.className, required this.counts});

  factory AttendanceClassRow.fromJson(Map<String, dynamic> json) => _$AttendanceClassRowFromJson(json);

  final String classId;
  final String? className;
  final AttendanceCounts counts;
}

@JsonSerializable(createToJson: false)
class AttendanceStudentRow {
  const AttendanceStudentRow({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.classId,
    this.className,
    required this.counts,
  });

  factory AttendanceStudentRow.fromJson(Map<String, dynamic> json) => _$AttendanceStudentRowFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String? classId;
  final String? className;
  final AttendanceCounts counts;
}

@JsonSerializable(createToJson: false)
class AttendanceReport {
  const AttendanceReport({
    required this.from,
    required this.to,
    required this.thresholdPercentage,
    required this.totals,
    required this.absenceReasons,
    required this.classes,
    required this.belowThreshold,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) => _$AttendanceReportFromJson(json);

  final DateTime from;
  final DateTime to;
  final int thresholdPercentage;
  final AttendanceCounts totals;
  final Map<String, int> absenceReasons;
  final List<AttendanceClassRow> classes;
  final List<AttendanceStudentRow> belowThreshold;
}

@JsonSerializable(createToJson: false)
class ProgressClassRow {
  const ProgressClassRow({
    required this.classId,
    required this.className,
    this.period,
    required this.students,
    required this.scores,
    this.averageScore,
    required this.targets,
    required this.targetsBehind,
  });

  factory ProgressClassRow.fromJson(Map<String, dynamic> json) => _$ProgressClassRowFromJson(json);

  final String classId;
  final String className;
  final CurriculumPeriodSummary? period;
  final int students;
  final int scores;
  final double? averageScore;
  final int targets;
  final int targetsBehind;
}

/// A target whose current percentage is below the target percentage.
@JsonSerializable(createToJson: false)
class BehindTarget {
  const BehindTarget({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.classId,
    required this.className,
    required this.targetId,
    this.subject,
    required this.description,
    this.targetPercentage,
    this.currentPercentage,
  });

  factory BehindTarget.fromJson(Map<String, dynamic> json) => _$BehindTargetFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String classId;
  final String className;
  final String targetId;
  final String? subject;
  final String description;
  final int? targetPercentage;
  final int? currentPercentage;
}

@JsonSerializable(createToJson: false)
class PeriodProgress {
  const PeriodProgress({required this.period, required this.scores, this.averageScore});

  factory PeriodProgress.fromJson(Map<String, dynamic> json) => _$PeriodProgressFromJson(json);

  final CurriculumPeriodSummary period;
  final int scores;
  final double? averageScore;
}

@JsonSerializable(createToJson: false)
class ProgressReport {
  const ProgressReport({required this.classes, required this.behindTarget, required this.periods});

  factory ProgressReport.fromJson(Map<String, dynamic> json) => _$ProgressReportFromJson(json);

  final List<ProgressClassRow> classes;
  final List<BehindTarget> behindTarget;

  /// Only filled in when the report is for one class.
  final List<PeriodProgress> periods;
}

@JsonSerializable(createToJson: false)
class BehaviourCount {
  const BehaviourCount({required this.behaviour, required this.good, required this.count});

  factory BehaviourCount.fromJson(Map<String, dynamic> json) => _$BehaviourCountFromJson(json);

  final String behaviour;
  final bool good;
  final int count;
}

@JsonSerializable(createToJson: false)
class RecurringBehaviour {
  const RecurringBehaviour({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.className,
    required this.behaviour,
    required this.count,
    required this.lastSeen,
  });

  factory RecurringBehaviour.fromJson(Map<String, dynamic> json) => _$RecurringBehaviourFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String? className;
  final String behaviour;
  final int count;
  final DateTime lastSeen;
}

@JsonSerializable(createToJson: false)
class BehaviourReport {
  const BehaviourReport({
    required this.from,
    required this.to,
    required this.observations,
    required this.behaviours,
    required this.recurringAtLeast,
    required this.recurring,
  });

  factory BehaviourReport.fromJson(Map<String, dynamic> json) => _$BehaviourReportFromJson(json);

  final DateTime from;
  final DateTime to;
  final int observations;
  final List<BehaviourCount> behaviours;
  final int recurringAtLeast;
  final List<RecurringBehaviour> recurring;
}

@JsonSerializable(createToJson: false)
class OwingStudent {
  const OwingStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.className,
    required this.months,
    required this.outstandingAmount,
  });

  factory OwingStudent.fromJson(Map<String, dynamic> json) => _$OwingStudentFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String? className;
  final int months;
  final double outstandingAmount;
}

@JsonSerializable(createToJson: false)
class PaymentReport {
  const PaymentReport({
    required this.currency,
    required this.months,
    required this.totals,
    required this.studentsOwing,
  });

  factory PaymentReport.fromJson(Map<String, dynamic> json) => _$PaymentReportFromJson(json);

  final String currency;
  final List<PaymentPeriod> months;
  final PaymentTotals totals;
  final List<OwingStudent> studentsOwing;
}

@JsonSerializable(createToJson: false)
class StudentAttendance {
  const StudentAttendance({
    required this.lessons,
    required this.present,
    required this.late,
    required this.absent,
    this.attendancePercentage,
    required this.thresholdPercentage,
    required this.belowThreshold,
    required this.absenceReasons,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) => _$StudentAttendanceFromJson(json);

  final int lessons;
  final int present;
  final int late;
  final int absent;
  final int? attendancePercentage;
  final int thresholdPercentage;
  final bool belowThreshold;
  final Map<String, int> absenceReasons;
}

@JsonSerializable(createToJson: false)
class SubjectProgress {
  const SubjectProgress({
    required this.subject,
    required this.scores,
    this.averageScore,
    this.latestScore,
    this.latestLabel,
    this.latestDate,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) => _$SubjectProgressFromJson(json);

  final String subject;
  final int scores;
  final double? averageScore;
  final double? latestScore;
  final String? latestLabel;
  final DateTime? latestDate;
}

@JsonSerializable(createToJson: false)
class UniformCounts {
  const UniformCounts({required this.inOrder, required this.partiallyInOrder, required this.notInOrder});

  factory UniformCounts.fromJson(Map<String, dynamic> json) => _$UniformCountsFromJson(json);

  final int inOrder;
  final int partiallyInOrder;
  final int notInOrder;

  int get total => inOrder + partiallyInOrder + notInOrder;
}

@JsonSerializable(createToJson: false)
class StudentPayments {
  const StudentPayments({
    required this.currency,
    required this.months,
    required this.monthsOwing,
    required this.expectedTotal,
    required this.paidTotal,
    required this.outstandingTotal,
  });

  factory StudentPayments.fromJson(Map<String, dynamic> json) => _$StudentPaymentsFromJson(json);

  final String currency;
  final int months;
  final int monthsOwing;
  final double expectedTotal;
  final double paidTotal;
  final double outstandingTotal;
}

@JsonSerializable(createToJson: false)
class StudentReport {
  const StudentReport({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.className,
    required this.from,
    required this.to,
    required this.attendance,
    required this.progress,
    required this.targets,
    required this.behaviour,
    required this.uniform,
    this.payments,
  });

  factory StudentReport.fromJson(Map<String, dynamic> json) => _$StudentReportFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String? className;
  final DateTime from;
  final DateTime to;
  final StudentAttendance attendance;
  final List<SubjectProgress> progress;
  final List<StudentTarget> targets;
  final List<BehaviourCount> behaviour;
  final UniformCounts uniform;

  /// Only sent to users who may see payments.
  final StudentPayments? payments;
}

@JsonSerializable(createToJson: false)
class DashboardAttendance {
  const DashboardAttendance({
    required this.from,
    required this.to,
    this.attendancePercentage,
    required this.late,
    required this.absent,
    required this.studentsBelowThreshold,
    required this.thresholdPercentage,
  });

  factory DashboardAttendance.fromJson(Map<String, dynamic> json) => _$DashboardAttendanceFromJson(json);

  final DateTime from;
  final DateTime to;
  final int? attendancePercentage;
  final int late;
  final int absent;
  final int studentsBelowThreshold;
  final int thresholdPercentage;
}

@JsonSerializable(createToJson: false)
class DashboardProgress {
  const DashboardProgress({required this.targets, required this.targetsBehind});

  factory DashboardProgress.fromJson(Map<String, dynamic> json) => _$DashboardProgressFromJson(json);

  final int targets;
  final int targetsBehind;
}

@JsonSerializable(createToJson: false)
class DashboardPayments {
  const DashboardPayments({required this.month, required this.currency, required this.totals});

  factory DashboardPayments.fromJson(Map<String, dynamic> json) => _$DashboardPaymentsFromJson(json);

  @JsonKey(fromJson: monthFromJson)
  final DateTime month;
  final String currency;
  final PaymentTotals totals;
}

/// The figures on the dashboard, over the classes the user may see.
@JsonSerializable(createToJson: false)
class DashboardFigures {
  const DashboardFigures({required this.attendance, required this.progress, this.payments});

  factory DashboardFigures.fromJson(Map<String, dynamic> json) => _$DashboardFiguresFromJson(json);

  final DashboardAttendance attendance;
  final DashboardProgress progress;
  final DashboardPayments? payments;
}
