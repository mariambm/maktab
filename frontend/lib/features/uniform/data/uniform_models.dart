import 'package:json_annotation/json_annotation.dart';

part 'uniform_models.g.dart';

abstract final class UniformStatuses {
  static const inOrder = 'IN_ORDER';
  static const partiallyInOrder = 'PARTIALLY_IN_ORDER';
  static const notInOrder = 'NOT_IN_ORDER';

  static const all = [inOrder, partiallyInOrder, notInOrder];
}

abstract final class UniformReasons {
  static const hijabMissing = 'HIJAB_MISSING';
  static const shirt = 'SHIRT_NOT_ACCORDING_TO_UNIFORM';
  static const other = 'OTHER';

  static const all = [hijabMissing, shirt, other];
}

/// A student's uniform in one lesson.
@JsonSerializable(createToJson: false)
class UniformEntry {
  const UniformEntry({required this.studentId, required this.status, this.reason, this.note});

  factory UniformEntry.fromJson(Map<String, dynamic> json) => _$UniformEntryFromJson(json);

  final String studentId;
  final String status;
  final String? reason;
  final String? note;

  /// Uniform in order never keeps a reason, exactly as the server does.
  UniformEntry copyWith({String? status, String? reason}) {
    final next = status ?? this.status;
    return UniformEntry(
      studentId: studentId,
      status: next,
      reason: next == UniformStatuses.inOrder ? null : (reason ?? this.reason),
      note: note,
    );
  }

  Map<String, dynamic> toJson() => {'studentId': studentId, 'status': status, 'reason': ?reason, 'note': ?note};
}

@JsonSerializable(createToJson: false)
class LessonUniform {
  const LessonUniform({required this.lessonId, required this.records});

  factory LessonUniform.fromJson(Map<String, dynamic> json) => _$LessonUniformFromJson(json);

  final String lessonId;
  final List<UniformEntry> records;
}

@JsonSerializable(createToJson: false)
class StudentUniform {
  const StudentUniform({
    required this.lessonId,
    required this.lessonDate,
    required this.classGroupId,
    this.className,
    required this.status,
    this.reason,
    this.note,
  });

  factory StudentUniform.fromJson(Map<String, dynamic> json) => _$StudentUniformFromJson(json);

  final String lessonId;
  final DateTime lessonDate;
  final String classGroupId;
  final String? className;
  final String status;
  final String? reason;
  final String? note;
}
