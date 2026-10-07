// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uniform_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UniformEntry _$UniformEntryFromJson(Map<String, dynamic> json) => UniformEntry(
  studentId: json['studentId'] as String,
  status: json['status'] as String,
  reason: json['reason'] as String?,
  note: json['note'] as String?,
);

LessonUniform _$LessonUniformFromJson(Map<String, dynamic> json) => LessonUniform(
  lessonId: json['lessonId'] as String,
  records: (json['records'] as List<dynamic>).map((e) => UniformEntry.fromJson(e as Map<String, dynamic>)).toList(),
);

StudentUniform _$StudentUniformFromJson(Map<String, dynamic> json) => StudentUniform(
  lessonId: json['lessonId'] as String,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String?,
  status: json['status'] as String,
  reason: json['reason'] as String?,
  note: json['note'] as String?,
);
