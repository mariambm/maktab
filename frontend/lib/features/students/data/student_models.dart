import 'package:json_annotation/json_annotation.dart';

import '../../classes/data/class_models.dart';

part 'student_models.g.dart';

abstract final class StudentStatus {
  static const active = 'ACTIVE';
  static const inactive = 'INACTIVE';
}

abstract final class Genders {
  static const female = 'FEMALE';
  static const male = 'MALE';
}

/// Relationship values as sent by the API.
const parentRelationships = ['MOTHER', 'FATHER', 'GUARDIAN', 'OTHER'];

@JsonSerializable(createToJson: false)
class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.status,
    this.currentClass,
  });

  factory StudentSummary.fromJson(Map<String, dynamic> json) => _$StudentSummaryFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String status;
  final ClassRef? currentClass;

  String get displayName => '$firstName $lastName';
  bool get isActive => status == StudentStatus.active;
}

@JsonSerializable(createToJson: false)
class StudentParent {
  const StudentParent({
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.relationship,
    required this.primaryContact,
  });

  factory StudentParent.fromJson(Map<String, dynamic> json) => _$StudentParentFromJson(json);

  final String parentId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String relationship;
  final bool primaryContact;

  String get displayName => '$firstName $lastName';
}

@JsonSerializable(createToJson: false)
class StudentDetail {
  const StudentDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    required this.status,
    required this.joinedOn,
    this.leftOn,
    this.notes,
    this.currentClass,
    required this.parents,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) => _$StudentDetailFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String status;
  final DateTime joinedOn;
  final DateTime? leftOn;
  final String? notes;
  final ClassRef? currentClass;
  final List<StudentParent> parents;

  String get displayName => '$firstName $lastName';
  bool get isActive => status == StudentStatus.active;
}

/// One period in a student's class history; [endDate] is exclusive and null for the current class.
@JsonSerializable(createToJson: false)
class Enrollment {
  const Enrollment({required this.id, required this.classGroup, required this.startDate, this.endDate});

  factory Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);

  final String id;
  final ClassRef classGroup;
  final DateTime startDate;
  final DateTime? endDate;

  bool get isCurrent => endDate == null;
}

/// A parent link as sent when creating a student or replacing their parents.
class ParentLink {
  const ParentLink({required this.parentId, required this.relationship, this.primaryContact = false});

  final String parentId;
  final String relationship;
  final bool primaryContact;

  Map<String, dynamic> toJson() => {
    'parentId': parentId,
    'relationship': relationship,
    'primaryContact': primaryContact,
  };
}

/// What the student form sends. [classId] and [parents] are only used when creating.
class StudentDraft {
  const StudentDraft({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    required this.joinedOn,
    this.notes,
    this.classId,
    this.parents = const [],
  });

  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final DateTime joinedOn;
  final String? notes;
  final String? classId;
  final List<ParentLink> parents;
}

/// Age in whole years on [today].
int ageOn(DateTime dateOfBirth, DateTime today) {
  var age = today.year - dateOfBirth.year;
  if (today.month < dateOfBirth.month || (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
    age--;
  }
  return age;
}
