import 'package:json_annotation/json_annotation.dart';

part 'progress_models.g.dart';

/// One step of the mosque's progress scale, such as 3.5 = Almost Good.
@JsonSerializable(createToJson: false)
class ProgressScaleLevel {
  const ProgressScaleLevel({required this.score, required this.label});

  factory ProgressScaleLevel.fromJson(Map<String, dynamic> json) => _$ProgressScaleLevelFromJson(json);

  final double score;
  final String label;
}

/// A score given in a lesson.
@JsonSerializable(createToJson: false)
class LessonScore {
  const LessonScore({required this.studentId, required this.subject, required this.score, this.note});

  factory LessonScore.fromJson(Map<String, dynamic> json) => _$LessonScoreFromJson(json);

  final String studentId;
  final String subject;
  final double score;
  final String? note;
}

@JsonSerializable(createToJson: false)
class LessonProgress {
  const LessonProgress({required this.lessonId, required this.scores});

  factory LessonProgress.fromJson(Map<String, dynamic> json) => _$LessonProgressFromJson(json);

  final String lessonId;
  final List<LessonScore> scores;

  /// The scores of one subject, by student.
  Map<String, double> scoresFor(String subject) => {
    for (final score in scores.where((s) => s.subject == subject)) score.studentId: score.score,
  };
}

/// One score in a student's history.
@JsonSerializable(createToJson: false)
class StudentScore {
  const StudentScore({
    required this.lessonId,
    required this.lessonDate,
    required this.classGroupId,
    this.className,
    required this.subject,
    required this.score,
    this.label,
    this.note,
  });

  factory StudentScore.fromJson(Map<String, dynamic> json) => _$StudentScoreFromJson(json);

  final String lessonId;
  final DateTime lessonDate;
  final String classGroupId;
  final String? className;
  final String subject;
  final double score;
  final String? label;
  final String? note;
}

/// "4" rather than "4.0", and "3.5" as it is.
String formatScore(double score) => score == score.roundToDouble() ? score.toInt().toString() : score.toString();
