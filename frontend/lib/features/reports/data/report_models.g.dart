// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceCounts _$AttendanceCountsFromJson(Map<String, dynamic> json) => AttendanceCounts(
  lessons: (json['lessons'] as num).toInt(),
  records: (json['records'] as num).toInt(),
  present: (json['present'] as num).toInt(),
  late: (json['late'] as num).toInt(),
  absent: (json['absent'] as num).toInt(),
  attendancePercentage: (json['attendancePercentage'] as num?)?.toInt(),
);

AttendanceClassRow _$AttendanceClassRowFromJson(Map<String, dynamic> json) => AttendanceClassRow(
  classId: json['classId'] as String,
  className: json['className'] as String?,
  counts: AttendanceCounts.fromJson(json['counts'] as Map<String, dynamic>),
);

AttendanceStudentRow _$AttendanceStudentRowFromJson(Map<String, dynamic> json) => AttendanceStudentRow(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  classId: json['classId'] as String?,
  className: json['className'] as String?,
  counts: AttendanceCounts.fromJson(json['counts'] as Map<String, dynamic>),
);

AttendanceReport _$AttendanceReportFromJson(Map<String, dynamic> json) => AttendanceReport(
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  thresholdPercentage: (json['thresholdPercentage'] as num).toInt(),
  totals: AttendanceCounts.fromJson(json['totals'] as Map<String, dynamic>),
  absenceReasons: Map<String, int>.from(json['absenceReasons'] as Map),
  classes: (json['classes'] as List<dynamic>)
      .map((e) => AttendanceClassRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  belowThreshold: (json['belowThreshold'] as List<dynamic>)
      .map((e) => AttendanceStudentRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

ProgressClassRow _$ProgressClassRowFromJson(Map<String, dynamic> json) => ProgressClassRow(
  classId: json['classId'] as String,
  className: json['className'] as String,
  period: json['period'] == null ? null : CurriculumPeriodSummary.fromJson(json['period'] as Map<String, dynamic>),
  students: (json['students'] as num).toInt(),
  scores: (json['scores'] as num).toInt(),
  averageScore: (json['averageScore'] as num?)?.toDouble(),
  targets: (json['targets'] as num).toInt(),
  targetsBehind: (json['targetsBehind'] as num).toInt(),
);

BehindTarget _$BehindTargetFromJson(Map<String, dynamic> json) => BehindTarget(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  classId: json['classId'] as String,
  className: json['className'] as String,
  targetId: json['targetId'] as String,
  subject: json['subject'] as String?,
  description: json['description'] as String,
  targetPercentage: (json['targetPercentage'] as num?)?.toInt(),
  currentPercentage: (json['currentPercentage'] as num?)?.toInt(),
);

PeriodProgress _$PeriodProgressFromJson(Map<String, dynamic> json) => PeriodProgress(
  period: CurriculumPeriodSummary.fromJson(json['period'] as Map<String, dynamic>),
  scores: (json['scores'] as num).toInt(),
  averageScore: (json['averageScore'] as num?)?.toDouble(),
);

ProgressReport _$ProgressReportFromJson(Map<String, dynamic> json) => ProgressReport(
  classes: (json['classes'] as List<dynamic>).map((e) => ProgressClassRow.fromJson(e as Map<String, dynamic>)).toList(),
  behindTarget: (json['behindTarget'] as List<dynamic>)
      .map((e) => BehindTarget.fromJson(e as Map<String, dynamic>))
      .toList(),
  periods: (json['periods'] as List<dynamic>).map((e) => PeriodProgress.fromJson(e as Map<String, dynamic>)).toList(),
);

BehaviourCount _$BehaviourCountFromJson(Map<String, dynamic> json) => BehaviourCount(
  behaviour: json['behaviour'] as String,
  good: json['good'] as bool,
  count: (json['count'] as num).toInt(),
);

RecurringBehaviour _$RecurringBehaviourFromJson(Map<String, dynamic> json) => RecurringBehaviour(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  className: json['className'] as String?,
  behaviour: json['behaviour'] as String,
  count: (json['count'] as num).toInt(),
  lastSeen: DateTime.parse(json['lastSeen'] as String),
);

BehaviourReport _$BehaviourReportFromJson(Map<String, dynamic> json) => BehaviourReport(
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  observations: (json['observations'] as num).toInt(),
  behaviours: (json['behaviours'] as List<dynamic>)
      .map((e) => BehaviourCount.fromJson(e as Map<String, dynamic>))
      .toList(),
  recurringAtLeast: (json['recurringAtLeast'] as num).toInt(),
  recurring: (json['recurring'] as List<dynamic>)
      .map((e) => RecurringBehaviour.fromJson(e as Map<String, dynamic>))
      .toList(),
);

OwingStudent _$OwingStudentFromJson(Map<String, dynamic> json) => OwingStudent(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  className: json['className'] as String?,
  months: (json['months'] as num).toInt(),
  outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
);

PaymentReport _$PaymentReportFromJson(Map<String, dynamic> json) => PaymentReport(
  currency: json['currency'] as String,
  months: (json['months'] as List<dynamic>).map((e) => PaymentPeriod.fromJson(e as Map<String, dynamic>)).toList(),
  totals: PaymentTotals.fromJson(json['totals'] as Map<String, dynamic>),
  studentsOwing: (json['studentsOwing'] as List<dynamic>)
      .map((e) => OwingStudent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

StudentAttendance _$StudentAttendanceFromJson(Map<String, dynamic> json) => StudentAttendance(
  lessons: (json['lessons'] as num).toInt(),
  present: (json['present'] as num).toInt(),
  late: (json['late'] as num).toInt(),
  absent: (json['absent'] as num).toInt(),
  attendancePercentage: (json['attendancePercentage'] as num?)?.toInt(),
  thresholdPercentage: (json['thresholdPercentage'] as num).toInt(),
  belowThreshold: json['belowThreshold'] as bool,
  absenceReasons: Map<String, int>.from(json['absenceReasons'] as Map),
);

SubjectProgress _$SubjectProgressFromJson(Map<String, dynamic> json) => SubjectProgress(
  subject: json['subject'] as String,
  scores: (json['scores'] as num).toInt(),
  averageScore: (json['averageScore'] as num?)?.toDouble(),
  latestScore: (json['latestScore'] as num?)?.toDouble(),
  latestLabel: json['latestLabel'] as String?,
  latestDate: json['latestDate'] == null ? null : DateTime.parse(json['latestDate'] as String),
);

UniformCounts _$UniformCountsFromJson(Map<String, dynamic> json) => UniformCounts(
  inOrder: (json['inOrder'] as num).toInt(),
  partiallyInOrder: (json['partiallyInOrder'] as num).toInt(),
  notInOrder: (json['notInOrder'] as num).toInt(),
);

StudentPayments _$StudentPaymentsFromJson(Map<String, dynamic> json) => StudentPayments(
  currency: json['currency'] as String,
  months: (json['months'] as num).toInt(),
  monthsOwing: (json['monthsOwing'] as num).toInt(),
  expectedTotal: (json['expectedTotal'] as num).toDouble(),
  paidTotal: (json['paidTotal'] as num).toDouble(),
  outstandingTotal: (json['outstandingTotal'] as num).toDouble(),
);

StudentReport _$StudentReportFromJson(Map<String, dynamic> json) => StudentReport(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  className: json['className'] as String?,
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  attendance: StudentAttendance.fromJson(json['attendance'] as Map<String, dynamic>),
  progress: (json['progress'] as List<dynamic>)
      .map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>))
      .toList(),
  targets: (json['targets'] as List<dynamic>).map((e) => StudentTarget.fromJson(e as Map<String, dynamic>)).toList(),
  behaviour: (json['behaviour'] as List<dynamic>)
      .map((e) => BehaviourCount.fromJson(e as Map<String, dynamic>))
      .toList(),
  uniform: UniformCounts.fromJson(json['uniform'] as Map<String, dynamic>),
  payments: json['payments'] == null ? null : StudentPayments.fromJson(json['payments'] as Map<String, dynamic>),
);

DashboardAttendance _$DashboardAttendanceFromJson(Map<String, dynamic> json) => DashboardAttendance(
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  attendancePercentage: (json['attendancePercentage'] as num?)?.toInt(),
  late: (json['late'] as num).toInt(),
  absent: (json['absent'] as num).toInt(),
  studentsBelowThreshold: (json['studentsBelowThreshold'] as num).toInt(),
  thresholdPercentage: (json['thresholdPercentage'] as num).toInt(),
);

DashboardProgress _$DashboardProgressFromJson(Map<String, dynamic> json) =>
    DashboardProgress(targets: (json['targets'] as num).toInt(), targetsBehind: (json['targetsBehind'] as num).toInt());

DashboardPayments _$DashboardPaymentsFromJson(Map<String, dynamic> json) => DashboardPayments(
  month: monthFromJson(json['month'] as String),
  currency: json['currency'] as String,
  totals: PaymentTotals.fromJson(json['totals'] as Map<String, dynamic>),
);

DashboardFigures _$DashboardFiguresFromJson(Map<String, dynamic> json) => DashboardFigures(
  attendance: DashboardAttendance.fromJson(json['attendance'] as Map<String, dynamic>),
  progress: DashboardProgress.fromJson(json['progress'] as Map<String, dynamic>),
  payments: json['payments'] == null ? null : DashboardPayments.fromJson(json['payments'] as Map<String, dynamic>),
);
