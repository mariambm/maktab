// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentSummary _$StudentSummaryFromJson(Map<String, dynamic> json) => StudentSummary(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  status: json['status'] as String,
  currentClass: json['currentClass'] == null ? null : ClassRef.fromJson(json['currentClass'] as Map<String, dynamic>),
);

StudentParent _$StudentParentFromJson(Map<String, dynamic> json) => StudentParent(
  parentId: json['parentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  relationship: json['relationship'] as String,
  primaryContact: json['primaryContact'] as bool,
);

StudentDetail _$StudentDetailFromJson(Map<String, dynamic> json) => StudentDetail(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  gender: json['gender'] as String?,
  status: json['status'] as String,
  joinedOn: DateTime.parse(json['joinedOn'] as String),
  leftOn: json['leftOn'] == null ? null : DateTime.parse(json['leftOn'] as String),
  notes: json['notes'] as String?,
  currentClass: json['currentClass'] == null ? null : ClassRef.fromJson(json['currentClass'] as Map<String, dynamic>),
  parents: (json['parents'] as List<dynamic>).map((e) => StudentParent.fromJson(e as Map<String, dynamic>)).toList(),
);

Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) => Enrollment(
  id: json['id'] as String,
  classGroup: ClassRef.fromJson(json['classGroup'] as Map<String, dynamic>),
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
);
