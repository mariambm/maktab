import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

/// Role names as sent by the API.
abstract final class Roles {
  static const admin = 'ADMIN';
  static const administrator = 'ADMINISTRATOR';
  static const teacher = 'TEACHER';
}

/// Permission names as sent by the API. The backend enforces them; the app only uses them to decide what to show.
abstract final class Permissions {
  static const userManage = 'USER_MANAGE';
  static const settingsManage = 'SETTINGS_MANAGE';
  static const auditRead = 'AUDIT_READ';
  static const studentRead = 'STUDENT_READ';
  static const studentWrite = 'STUDENT_WRITE';
  static const parentRead = 'PARENT_READ';
  static const parentWrite = 'PARENT_WRITE';
  static const classRead = 'CLASS_READ';
  static const classManage = 'CLASS_MANAGE';
  static const curriculumRead = 'CURRICULUM_READ';
  static const curriculumWrite = 'CURRICULUM_WRITE';
  static const lessonRecord = 'LESSON_RECORD';
  static const progressRecord = 'PROGRESS_RECORD';
  static const observationRecord = 'OBSERVATION_RECORD';
  static const paymentRead = 'PAYMENT_READ';
  static const reportRead = 'REPORT_READ';
}

@JsonSerializable(createToJson: false)
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.permissions,
    this.mustChangePassword = false,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final Set<String> permissions;
  final bool mustChangePassword;

  bool can(String permission) => permissions.contains(permission);

  bool hasRole(String role) => roles.contains(role);

  /// A teacher without an administrative role gets the teacher-first navigation.
  bool get isTeacherOnly => hasRole(Roles.teacher) && !hasRole(Roles.admin) && !hasRole(Roles.administrator);

  String get displayName => '$firstName $lastName';
}

@JsonSerializable(createToJson: false)
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final AuthUser user;
}
