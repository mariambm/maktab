// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curriculum_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonTopic _$LessonTopicFromJson(Map<String, dynamic> json) => LessonTopic(
  id: json['id'] as String,
  subject: json['subject'] as String?,
  title: json['title'] as String,
  learningObjective: json['learningObjective'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
);

CurriculumWeek _$CurriculumWeekFromJson(Map<String, dynamic> json) => CurriculumWeek(
  id: json['id'] as String,
  weekNumber: (json['weekNumber'] as num).toInt(),
  review: json['review'] as bool,
  topics: (json['topics'] as List<dynamic>).map((e) => LessonTopic.fromJson(e as Map<String, dynamic>)).toList(),
);

CurriculumPeriodSummary _$CurriculumPeriodSummaryFromJson(Map<String, dynamic> json) => CurriculumPeriodSummary(
  id: json['id'] as String,
  curriculumLevelId: json['curriculumLevelId'] as String,
  number: (json['number'] as num).toInt(),
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
);

CurriculumPeriod _$CurriculumPeriodFromJson(Map<String, dynamic> json) => CurriculumPeriod(
  id: json['id'] as String,
  curriculumLevelId: json['curriculumLevelId'] as String,
  curriculumLevelName: json['curriculumLevelName'] as String,
  number: (json['number'] as num).toInt(),
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  weeks: (json['weeks'] as List<dynamic>).map((e) => CurriculumWeek.fromJson(e as Map<String, dynamic>)).toList(),
);
