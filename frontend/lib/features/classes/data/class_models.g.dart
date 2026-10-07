// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassRef _$ClassRefFromJson(Map<String, dynamic> json) =>
    ClassRef(id: json['id'] as String, name: json['name'] as String);

CurriculumLevel _$CurriculumLevelFromJson(Map<String, dynamic> json) => CurriculumLevel(
  id: json['id'] as String,
  name: json['name'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

TeacherRef _$TeacherRefFromJson(Map<String, dynamic> json) =>
    TeacherRef(id: json['id'] as String, firstName: json['firstName'] as String, lastName: json['lastName'] as String);

ScheduleSlot _$ScheduleSlotFromJson(Map<String, dynamic> json) => ScheduleSlot(
  weekday: json['weekday'] as String,
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
);

Map<String, dynamic> _$ScheduleSlotToJson(ScheduleSlot instance) => <String, dynamic>{
  'weekday': instance.weekday,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};

ClassSummary _$ClassSummaryFromJson(Map<String, dynamic> json) => ClassSummary(
  id: json['id'] as String,
  name: json['name'] as String,
  curriculumLevel: CurriculumLevel.fromJson(json['curriculumLevel'] as Map<String, dynamic>),
  room: json['room'] as String?,
  active: json['active'] as bool,
  studentCount: (json['studentCount'] as num).toInt(),
  teachers: (json['teachers'] as List<dynamic>).map((e) => TeacherRef.fromJson(e as Map<String, dynamic>)).toList(),
  schedule: (json['schedule'] as List<dynamic>).map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>)).toList(),
);

ClassStudent _$ClassStudentFromJson(Map<String, dynamic> json) => ClassStudent(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  enrolledSince: DateTime.parse(json['enrolledSince'] as String),
);
