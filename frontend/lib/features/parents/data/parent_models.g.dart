// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParentChild _$ParentChildFromJson(Map<String, dynamic> json) => ParentChild(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  status: json['status'] as String,
  relationship: json['relationship'] as String,
  primaryContact: json['primaryContact'] as bool,
);

ParentGuardian _$ParentGuardianFromJson(Map<String, dynamic> json) => ParentGuardian(
  id: json['id'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  children: (json['children'] as List<dynamic>).map((e) => ParentChild.fromJson(e as Map<String, dynamic>)).toList(),
);
