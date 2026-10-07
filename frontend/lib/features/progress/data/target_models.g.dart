// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentTarget _$StudentTargetFromJson(Map<String, dynamic> json) => StudentTarget(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  period: CurriculumPeriodSummary.fromJson(json['period'] as Map<String, dynamic>),
  subject: json['subject'] as String?,
  description: json['description'] as String,
  targetPercentage: (json['targetPercentage'] as num?)?.toInt(),
  currentPercentage: (json['currentPercentage'] as num?)?.toInt(),
  progressScore: (json['progressScore'] as num?)?.toDouble(),
  progressLabel: json['progressLabel'] as String?,
  teacherNote: json['teacherNote'] as String?,
);

LatestScore _$LatestScoreFromJson(Map<String, dynamic> json) => LatestScore(
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  subject: json['subject'] as String,
  score: (json['score'] as num).toDouble(),
  label: json['label'] as String?,
);

ClassProgressStudent _$ClassProgressStudentFromJson(Map<String, dynamic> json) => ClassProgressStudent(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  latestScore: json['latestScore'] == null ? null : LatestScore.fromJson(json['latestScore'] as Map<String, dynamic>),
  targets: (json['targets'] as List<dynamic>).map((e) => StudentTarget.fromJson(e as Map<String, dynamic>)).toList(),
);

ClassProgress _$ClassProgressFromJson(Map<String, dynamic> json) => ClassProgress(
  classId: json['classId'] as String,
  className: json['className'] as String,
  period: json['period'] == null ? null : CurriculumPeriodSummary.fromJson(json['period'] as Map<String, dynamic>),
  students: (json['students'] as List<dynamic>)
      .map((e) => ClassProgressStudent.fromJson(e as Map<String, dynamic>))
      .toList(),
);
