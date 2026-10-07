import 'package:json_annotation/json_annotation.dart';

import '../../curriculum/data/curriculum_models.dart';

part 'target_models.g.dart';

/// What a student works towards in one four-week period, and where they stand now.
@JsonSerializable(createToJson: false)
class StudentTarget {
  const StudentTarget({
    required this.id,
    required this.studentId,
    required this.period,
    this.subject,
    required this.description,
    this.targetPercentage,
    this.currentPercentage,
    this.progressScore,
    this.progressLabel,
    this.teacherNote,
  });

  factory StudentTarget.fromJson(Map<String, dynamic> json) => _$StudentTargetFromJson(json);

  final String id;
  final String studentId;
  final CurriculumPeriodSummary period;
  final String? subject;
  final String description;
  final int? targetPercentage;
  final int? currentPercentage;
  final double? progressScore;
  final String? progressLabel;
  final String? teacherNote;
}

/// A target as the form sends it. The student and period only matter when it is created.
class TargetDraft {
  const TargetDraft({
    this.studentId,
    this.curriculumPeriodId,
    this.subject,
    required this.description,
    this.targetPercentage,
    this.currentPercentage,
    this.progressScore,
    this.teacherNote,
  });

  final String? studentId;
  final String? curriculumPeriodId;
  final String? subject;
  final String description;
  final int? targetPercentage;
  final int? currentPercentage;
  final double? progressScore;
  final String? teacherNote;

  Map<String, dynamic> toJson() => {
    'studentId': ?studentId,
    'curriculumPeriodId': ?curriculumPeriodId,
    'subject': ?subject,
    'description': description.trim(),
    'targetPercentage': ?targetPercentage,
    'currentPercentage': ?currentPercentage,
    'progressScore': ?progressScore,
    'teacherNote': ?(teacherNote == null || teacherNote!.trim().isEmpty ? null : teacherNote!.trim()),
  };
}

/// A student's most recent score, as the class overview shows it.
@JsonSerializable(createToJson: false)
class LatestScore {
  const LatestScore({required this.lessonDate, required this.subject, required this.score, this.label});

  factory LatestScore.fromJson(Map<String, dynamic> json) => _$LatestScoreFromJson(json);

  final DateTime lessonDate;
  final String subject;
  final double score;
  final String? label;
}

@JsonSerializable(createToJson: false)
class ClassProgressStudent {
  const ClassProgressStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.latestScore,
    required this.targets,
  });

  factory ClassProgressStudent.fromJson(Map<String, dynamic> json) => _$ClassProgressStudentFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final LatestScore? latestScore;
  final List<StudentTarget> targets;

  String get displayName => '$firstName $lastName';
}

/// A class at a glance for the period running now.
@JsonSerializable(createToJson: false)
class ClassProgress {
  const ClassProgress({required this.classId, required this.className, this.period, required this.students});

  factory ClassProgress.fromJson(Map<String, dynamic> json) => _$ClassProgressFromJson(json);

  final String classId;
  final String className;
  final CurriculumPeriodSummary? period;
  final List<ClassProgressStudent> students;
}
