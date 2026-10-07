import 'package:json_annotation/json_annotation.dart';

part 'parent_models.g.dart';

@JsonSerializable(createToJson: false)
class ParentChild {
  const ParentChild({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.relationship,
    required this.primaryContact,
  });

  factory ParentChild.fromJson(Map<String, dynamic> json) => _$ParentChildFromJson(json);

  final String studentId;
  final String firstName;
  final String lastName;
  final String status;
  final String relationship;
  final bool primaryContact;

  String get displayName => '$firstName $lastName';
}

@JsonSerializable(createToJson: false)
class ParentGuardian {
  const ParentGuardian({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.children,
  });

  factory ParentGuardian.fromJson(Map<String, dynamic> json) => _$ParentGuardianFromJson(json);

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final List<ParentChild> children;

  String get displayName => '$firstName $lastName';
}

class ParentDraft {
  const ParentDraft({required this.firstName, required this.lastName, required this.phone, this.email});

  final String firstName;
  final String lastName;
  final String phone;
  final String? email;

  Map<String, dynamic> toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'phone': phone.trim(),
    'email': email == null || email!.trim().isEmpty ? null : email!.trim(),
  };
}
