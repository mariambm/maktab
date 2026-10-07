import 'package:json_annotation/json_annotation.dart';

import '../../curriculum/data/curriculum_models.dart';

part 'lesson_models.g.dart';

/// Attendance statuses as sent by the API.
abstract final class AttendanceStatuses {
  static const present = 'PRESENT';
  static const late = 'LATE';
  static const absent = 'ABSENT';

  static const all = [present, late, absent];
}

/// Reasons for an absence, as sent by the API.
abstract final class AbsenceReasons {
  static const authorised = 'AUTHORISED';
  static const unauthorised = 'UNAUTHORISED';
  static const sick = 'SICK';
  static const holiday = 'HOLIDAY';
  static const notReading = 'NOT_READING';

  static const all = [authorised, unauthorised, sick, holiday, notReading];
}

/// Lesson statuses as sent by the API.
abstract final class LessonStatuses {
  static const planned = 'PLANNED';
  static const completed = 'COMPLETED';
  static const cancelled = 'CANCELLED';
}

/// A lesson on the day list. [id] is null for a scheduled slot nobody has opened yet.
@JsonSerializable(createToJson: false)
class LessonSummary {
  const LessonSummary({
    this.id,
    required this.classGroupId,
    required this.className,
    this.room,
    required this.lessonDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.classScheduleId,
    required this.studentCount,
    required this.attendanceRecorded,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> json) => _$LessonSummaryFromJson(json);

  final String? id;
  final String classGroupId;
  final String className;
  final String? room;
  final DateTime lessonDate;

  /// `HH:mm:ss` as sent by the API.
  final String startTime;
  final String endTime;
  final String status;
  final String? classScheduleId;
  final int studentCount;
  final int attendanceRecorded;

  bool get isOpened => id != null;

  /// True once every student in the class has a row in the register.
  bool get attendanceComplete => studentCount > 0 && attendanceRecorded >= studentCount;
}

/// A student on the register, with their attendance when it has been recorded.
@JsonSerializable(createToJson: false)
class LessonStudent {
  const LessonStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.status,
    this.minutesLate,
    this.absenceReason,
    this.note,
  });

  factory LessonStudent.fromJson(Map<String, dynamic> json) => _$LessonStudentFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String? status;
  final int? minutesLate;
  final String? absenceReason;
  final String? note;

  String get displayName => '$firstName $lastName';
}

/// Everything the lesson screen needs: the lesson, its register and the curriculum topics of that week.
@JsonSerializable(createToJson: false)
class LessonDetail {
  const LessonDetail({
    required this.id,
    required this.classGroupId,
    required this.className,
    this.room,
    required this.lessonDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.contentNotes,
    this.teacherUserId,
    this.curriculumPeriod,
    this.curriculumWeekNumber,
    required this.availableTopics,
    required this.coveredTopicIds,
    required this.students,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) => _$LessonDetailFromJson(json);

  final String id;
  final String classGroupId;
  final String className;
  final String? room;
  final DateTime lessonDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? contentNotes;
  final String? teacherUserId;
  final CurriculumPeriodSummary? curriculumPeriod;
  final int? curriculumWeekNumber;
  final List<LessonTopic> availableTopics;
  final List<String> coveredTopicIds;
  final List<LessonStudent> students;

  int get recordedCount => students.where((s) => s.status != null).length;
}

/// One student's attendance as the register sends it.
class AttendanceEntry {
  const AttendanceEntry({
    required this.studentId,
    required this.status,
    this.minutesLate,
    this.absenceReason,
    this.note,
  });

  final String studentId;
  final String status;
  final int? minutesLate;
  final String? absenceReason;
  final String? note;

  /// Changing the status drops the fields that do not belong to it, exactly as the server does.
  AttendanceEntry copyWith({String? status, int? minutesLate, String? absenceReason, String? note}) {
    final next = status ?? this.status;
    return AttendanceEntry(
      studentId: studentId,
      status: next,
      minutesLate: next == AttendanceStatuses.late ? (minutesLate ?? this.minutesLate) : null,
      absenceReason: next == AttendanceStatuses.absent ? (absenceReason ?? this.absenceReason) : null,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'status': status,
    'minutesLate': ?minutesLate,
    'absenceReason': ?absenceReason,
    'note': ?(note == null || note!.trim().isEmpty ? null : note!.trim()),
  };
}

/// What opening a lesson sends: a scheduled slot, or a class with its own times.
class OpenLessonDraft {
  const OpenLessonDraft({
    required this.classGroupId,
    required this.lessonDate,
    this.classScheduleId,
    this.startTime,
    this.endTime,
  });

  final String classGroupId;
  final DateTime lessonDate;
  final String? classScheduleId;
  final String? startTime;
  final String? endTime;

  Map<String, dynamic> toJson() => {
    'classGroupId': classGroupId,
    'lessonDate': _isoDate(lessonDate),
    'classScheduleId': ?classScheduleId,
    'startTime': ?startTime,
    'endTime': ?endTime,
  };
}

/// What the teacher records about the lesson itself.
class LessonUpdateDraft {
  const LessonUpdateDraft({required this.status, this.contentNotes, required this.coveredTopicIds});

  final String status;
  final String? contentNotes;
  final Set<String> coveredTopicIds;

  Map<String, dynamic> toJson() => {
    'status': status,
    'contentNotes': contentNotes == null || contentNotes!.trim().isEmpty ? null : contentNotes!.trim(),
    'coveredTopicIds': coveredTopicIds.toList(),
  };
}

/// One attendance row in a student's history.
@JsonSerializable(createToJson: false)
class StudentAttendance {
  const StudentAttendance({
    required this.lessonId,
    required this.lessonDate,
    required this.classGroupId,
    required this.className,
    required this.status,
    this.minutesLate,
    this.absenceReason,
    this.note,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) => _$StudentAttendanceFromJson(json);

  final String lessonId;
  final DateTime lessonDate;
  final String classGroupId;
  final String className;
  final String status;
  final int? minutesLate;
  final String? absenceReason;
  final String? note;
}

/// Attendance figures, calculated by the server on every request and never stored.
@JsonSerializable(createToJson: false)
class AttendanceStatistics {
  const AttendanceStatistics({
    required this.lessons,
    required this.present,
    required this.late,
    required this.absent,
    this.attendancePercentage,
    required this.threshold,
    required this.belowThreshold,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) => _$AttendanceStatisticsFromJson(json);

  final int lessons;
  final int present;
  final int late;
  final int absent;
  final int? attendancePercentage;
  final int threshold;
  final bool belowThreshold;
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The API's `yyyy-MM-dd` spelling of a date, used in query parameters and request bodies.
String isoDate(DateTime date) => _isoDate(date);
