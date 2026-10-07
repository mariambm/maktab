// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonSummary _$LessonSummaryFromJson(Map<String, dynamic> json) => LessonSummary(
  id: json['id'] as String?,
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String,
  room: json['room'] as String?,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  status: json['status'] as String,
  classScheduleId: json['classScheduleId'] as String?,
  studentCount: (json['studentCount'] as num).toInt(),
  attendanceRecorded: (json['attendanceRecorded'] as num).toInt(),
);

LessonStudent _$LessonStudentFromJson(Map<String, dynamic> json) => LessonStudent(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  status: json['status'] as String?,
  minutesLate: (json['minutesLate'] as num?)?.toInt(),
  absenceReason: json['absenceReason'] as String?,
  note: json['note'] as String?,
);

LessonDetail _$LessonDetailFromJson(Map<String, dynamic> json) => LessonDetail(
  id: json['id'] as String,
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String,
  room: json['room'] as String?,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  status: json['status'] as String,
  contentNotes: json['contentNotes'] as String?,
  teacherUserId: json['teacherUserId'] as String?,
  curriculumPeriod: json['curriculumPeriod'] == null
      ? null
      : CurriculumPeriodSummary.fromJson(json['curriculumPeriod'] as Map<String, dynamic>),
  curriculumWeekNumber: (json['curriculumWeekNumber'] as num?)?.toInt(),
  availableTopics: (json['availableTopics'] as List<dynamic>)
      .map((e) => LessonTopic.fromJson(e as Map<String, dynamic>))
      .toList(),
  coveredTopicIds: (json['coveredTopicIds'] as List<dynamic>).map((e) => e as String).toList(),
  students: (json['students'] as List<dynamic>).map((e) => LessonStudent.fromJson(e as Map<String, dynamic>)).toList(),
);

StudentAttendance _$StudentAttendanceFromJson(Map<String, dynamic> json) => StudentAttendance(
  lessonId: json['lessonId'] as String,
  lessonDate: DateTime.parse(json['lessonDate'] as String),
  classGroupId: json['classGroupId'] as String,
  className: json['className'] as String,
  status: json['status'] as String,
  minutesLate: (json['minutesLate'] as num?)?.toInt(),
  absenceReason: json['absenceReason'] as String?,
  note: json['note'] as String?,
);

AttendanceStatistics _$AttendanceStatisticsFromJson(Map<String, dynamic> json) => AttendanceStatistics(
  lessons: (json['lessons'] as num).toInt(),
  present: (json['present'] as num).toInt(),
  late: (json['late'] as num).toInt(),
  absent: (json['absent'] as num).toInt(),
  attendancePercentage: (json['attendancePercentage'] as num?)?.toInt(),
  threshold: (json['threshold'] as num).toInt(),
  belowThreshold: json['belowThreshold'] as bool,
);
