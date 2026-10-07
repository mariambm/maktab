import 'package:json_annotation/json_annotation.dart';

part 'user_summary.g.dart';

@JsonSerializable(createToJson: false)
class UserSummary {
  const UserSummary({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.active,
    required this.roles,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool active;
  final List<String> roles;

  String get displayName => '$firstName $lastName';
}
