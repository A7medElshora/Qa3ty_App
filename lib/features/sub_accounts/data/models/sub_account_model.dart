import 'package:qa3ty_app/features/auth/data/models/user_model.dart';

class SubAccountModel {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final bool isActive;
  final bool isPrimary;
  final UserPermissions permissions;
  final String? createdAt;

  const SubAccountModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.phone,
    required this.isActive,
    required this.isPrimary,
    required this.permissions,
    this.createdAt,
  });

  factory SubAccountModel.fromJson(Map<String, dynamic> json) {
    final permissionJson = json['permissions'];
    return SubAccountModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      isPrimary:
          json['is_primary'] is bool ? json['is_primary'] as bool : false,
      permissions: UserPermissions.fromJson(
        permissionJson is Map<String, dynamic> ? permissionJson : const {},
      ),
      createdAt: json['created_at']?.toString(),
    );
  }

  SubAccountModel copyWith({
    String? fullName,
    String? phone,
    bool? isActive,
    UserPermissions? permissions,
  }) {
    return SubAccountModel(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt,
    );
  }
}
