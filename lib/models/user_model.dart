import '../core/constants/app_constants.dart';

/// Represents a user of the WavesLive system
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String organisationId;
  final String organisationName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.organisationId,
    required this.organisationName,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get roleDisplayName => UserRole.displayName(role);

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      organisationId: organisationId,
      organisationName: organisationName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'organisationId': organisationId,
    'organisationName': organisationName,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    role: map['role'],
    organisationId: map['organisationId'],
    organisationName: map['organisationName'],
    phone: map['phone'],
    avatarUrl: map['avatarUrl'],
    isActive: map['isActive'] ?? true,
    createdAt: DateTime.parse(map['createdAt']),
    lastLoginAt: map['lastLoginAt'] != null
        ? DateTime.parse(map['lastLoginAt'])
        : null,
  );
}

/// Represents an organisation in the system
class OrganisationModel {
  final String id;
  final String name;
  final String type;
  final String description;
  final String contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final bool isActive;
  final List<String> memberRoles;

  const OrganisationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    this.isActive = true,
    required this.memberRoles,
  });
}
