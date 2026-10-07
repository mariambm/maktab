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
    this.grantedPermissions = const [],
    this.effectivePermissions = const [],
    this.mustChangePassword = false,
    this.lastLoginAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool active;
  final List<String> roles;

  /// Permissions given to this person on top of their roles, for example `PAYMENT_READ` for one teacher.
  @JsonKey(defaultValue: <String>[])
  final List<String> grantedPermissions;

  @JsonKey(defaultValue: <String>[])
  final List<String> effectivePermissions;

  @JsonKey(defaultValue: false)
  final bool mustChangePassword;

  final DateTime? lastLoginAt;

  String get displayName => '$firstName $lastName';

  /// What the roles alone already give, so the extra-permissions picker only offers what would add something.
  Set<String> get permissionsFromRoles => effectivePermissions.toSet().difference(grantedPermissions.toSet());
}

/// Returned once after creating an account or resetting its password. The temporary password is shown to the admin
/// a single time and is never stored by the app.
class CreatedUser {
  const CreatedUser({required this.user, required this.temporaryPassword});

  factory CreatedUser.fromJson(Map<String, dynamic> json) => CreatedUser(
    user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
    temporaryPassword: json['temporaryPassword'] as String,
  );

  final UserSummary user;
  final String temporaryPassword;

  @override
  String toString() => 'CreatedUser(${user.id})';
}

/// Name and email as entered in the user form.
class UserDraft {
  const UserDraft({required this.firstName, required this.lastName, required this.email});

  final String firstName;
  final String lastName;
  final String email;

  Map<String, Object?> toJson() => {'firstName': firstName.trim(), 'lastName': lastName.trim(), 'email': email.trim()};
}
