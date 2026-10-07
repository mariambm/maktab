// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSummary _$UserSummaryFromJson(Map<String, dynamic> json) => UserSummary(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  active: json['active'] as bool,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
);
