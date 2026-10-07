import 'package:json_annotation/json_annotation.dart';

part 'class_models.g.dart';

/// A class as referenced from other resources.
@JsonSerializable(createToJson: false)
class ClassRef {
  const ClassRef({required this.id, required this.name});

  factory ClassRef.fromJson(Map<String, dynamic> json) => _$ClassRefFromJson(json);

  final String id;
  final String name;
}

@JsonSerializable(createToJson: false)
class CurriculumLevel {
  const CurriculumLevel({required this.id, required this.name, required this.sortOrder});

  factory CurriculumLevel.fromJson(Map<String, dynamic> json) => _$CurriculumLevelFromJson(json);

  final String id;
  final String name;
  final int sortOrder;
}

@JsonSerializable(createToJson: false)
class TeacherRef {
  const TeacherRef({required this.id, required this.firstName, required this.lastName});

  factory TeacherRef.fromJson(Map<String, dynamic> json) => _$TeacherRefFromJson(json);

  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName';
}

/// ISO weekday names as sent by the API, Monday first.
const weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

@JsonSerializable()
class ScheduleSlot {
  const ScheduleSlot({required this.weekday, required this.startTime, required this.endTime});

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => _$ScheduleSlotFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleSlotToJson(this);

  /// `MONDAY` … `SUNDAY`.
  final String weekday;

  /// `HH:mm` or `HH:mm:ss`.
  final String startTime;
  final String endTime;

  int get weekdayIndex => weekdays.indexOf(weekday);

  /// `HH:mm`, without seconds.
  static String shortTime(String time) => time.length >= 5 ? time.substring(0, 5) : time;
}

@JsonSerializable(createToJson: false)
class ClassSummary {
  const ClassSummary({
    required this.id,
    required this.name,
    required this.curriculumLevel,
    this.room,
    required this.active,
    required this.studentCount,
    required this.teachers,
    required this.schedule,
  });

  factory ClassSummary.fromJson(Map<String, dynamic> json) => _$ClassSummaryFromJson(json);

  final String id;
  final String name;
  final CurriculumLevel curriculumLevel;
  final String? room;
  final bool active;
  final int studentCount;
  final List<TeacherRef> teachers;
  final List<ScheduleSlot> schedule;

  ClassRef get ref => ClassRef(id: id, name: name);
}

/// A student currently in a class.
@JsonSerializable(createToJson: false)
class ClassStudent {
  const ClassStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.enrolledSince,
  });

  factory ClassStudent.fromJson(Map<String, dynamic> json) => _$ClassStudentFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final DateTime enrolledSince;

  String get displayName => '$firstName $lastName';
}

/// What the class form sends.
class ClassDraft {
  const ClassDraft({required this.name, required this.curriculumLevelId, this.room, this.active = true});

  final String name;
  final String curriculumLevelId;
  final String? room;
  final bool active;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'curriculumLevelId': curriculumLevelId,
    'room': room == null || room!.trim().isEmpty ? null : room!.trim(),
    'active': active,
  };
}
