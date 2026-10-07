// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressScaleLevel _$ProgressScaleLevelFromJson(Map<String, dynamic> json) =>
    ProgressScaleLevel(score: (json['score'] as num).toDouble(), label: json['label'] as String);

LessonScore _$LessonScoreFromJson(Map<String, dynamic> json) => LessonScore(
  studentId: json['studentId'] as String,
  subject: json['subject'] as String,
  score: (json['score'] as num).toDouble(),
  note: json['note'] as String?,
);

LessonProgress _$LessonProgressFromJson(Map<String, dynamic> json) => LessonProgress(
  lessonId: json['lessonId'] as String,
  scores: (json['scores'] as List<dynamic>).map((e) => LessonScore.fromJson(e as Map<String, dynamic>)).toList(),
);

StudentScore _$StudentScoreFromJson(Map<String, dynamic> json) => StudentScore(
  lessonId: json['lessonId'] as String,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String?,
  subject: json['subject'] as String,
  score: (json['score'] as num).toDouble(),
  label: json['label'] as String?,
  note: json['note'] as String?,
);
