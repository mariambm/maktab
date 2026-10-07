// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behaviour_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BehaviourObservation _$BehaviourObservationFromJson(Map<String, dynamic> json) => BehaviourObservation(
  studentId: json['studentId'] as String,
  behaviours: (json['behaviours'] as List<dynamic>).map((e) => e as String).toList(),
  note: json['note'] as String?,
);

LessonBehaviour _$LessonBehaviourFromJson(Map<String, dynamic> json) => LessonBehaviour(
  lessonId: json['lessonId'] as String,
  observations: (json['observations'] as List<dynamic>)
      .map((e) => BehaviourObservation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

StudentBehaviour _$StudentBehaviourFromJson(Map<String, dynamic> json) => StudentBehaviour(
  lessonId: json['lessonId'] as String,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String?,
  behaviours: (json['behaviours'] as List<dynamic>).map((e) => e as String).toList(),
  note: json['note'] as String?,
);
