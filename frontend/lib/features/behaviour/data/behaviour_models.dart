import 'package:json_annotation/json_annotation.dart';

part 'behaviour_models.g.dart';

/// The behaviours a teacher can note, as the mosque defined them and the API sends them.
abstract final class Behaviours {
  static const good = [
    'GOOD_QURAN_RECITATION',
    'LEARNED_ISLAMIC_STUDIES',
    'LEARNED_NAMAZ_AND_DUAS',
    'LEARNED_NAAT_OR_SPEECH',
    'LISTENED_TO_TEACHER',
    'BEEN_HELPFUL',
    'ORGANISED',
    'RESPECTFUL',
    'GOOD_GROUP_WORK',
    'USING_TIME_EFFECTIVELY',
  ];

  static const needsAttention = [
    'OFF_TASK',
    'NOT_LISTENING',
    'DISTRACTING',
    'TALKING',
    'DISORGANISED',
    'LACK_OF_EFFORT',
    'WASTING_TIME',
    'SHOUTING',
    'WALKING_OR_RUNNING_AROUND',
  ];

  static const all = [...good, ...needsAttention];

  static bool isGood(String behaviour) => good.contains(behaviour);
}

/// What was observed about one student in one lesson.
@JsonSerializable(createToJson: false)
class BehaviourObservation {
  const BehaviourObservation({required this.studentId, required this.behaviours, this.note});

  factory BehaviourObservation.fromJson(Map<String, dynamic> json) => _$BehaviourObservationFromJson(json);

  final String studentId;
  final List<String> behaviours;
  final String? note;

  bool get isEmpty => behaviours.isEmpty && (note == null || note!.trim().isEmpty);

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'behaviours': Behaviours.all.where(behaviours.contains).toList(),
    'note': ?(note == null || note!.trim().isEmpty ? null : note!.trim()),
  };
}

@JsonSerializable(createToJson: false)
class LessonBehaviour {
  const LessonBehaviour({required this.lessonId, required this.observations});

  factory LessonBehaviour.fromJson(Map<String, dynamic> json) => _$LessonBehaviourFromJson(json);

  final String lessonId;
  final List<BehaviourObservation> observations;
}

/// One lesson's observations in a student's history.
@JsonSerializable(createToJson: false)
class StudentBehaviour {
  const StudentBehaviour({
    required this.lessonId,
    required this.lessonDate,
    required this.classGroupId,
    this.className,
    required this.behaviours,
    this.note,
  });

  factory StudentBehaviour.fromJson(Map<String, dynamic> json) => _$StudentBehaviourFromJson(json);

  final String lessonId;
  final DateTime lessonDate;
  final String classGroupId;
  final String? className;
  final List<String> behaviours;
  final String? note;
}
