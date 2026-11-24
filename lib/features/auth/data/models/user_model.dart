class UserPermissions {
  final bool canManageBookings;
  final bool canViewReports;
  final bool canManageExpenses;
  final bool canManageInventory;
  final bool canManageWorkers;
  final bool canManageSubAccounts;

  const UserPermissions({
    this.canManageBookings = true,
    this.canViewReports = false,
    this.canManageExpenses = false,
    this.canManageInventory = false,
    this.canManageWorkers = false,
    this.canManageSubAccounts = false,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    bool readPermission(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return UserPermissions(
      canManageBookings: readPermission('can_manage_bookings', true),
      canViewReports: readPermission('can_view_reports', false),
      canManageExpenses: readPermission('can_manage_expenses', false),
      canManageInventory: readPermission('can_manage_inventory', false),
      canManageWorkers: readPermission('can_manage_workers', false),
      canManageSubAccounts: readPermission('can_manage_sub_accounts', false),
    );
  }

  Map<String, dynamic> toJson() => {
        'can_manage_bookings': canManageBookings,
        'can_view_reports': canViewReports,
        'can_manage_expenses': canManageExpenses,
        'can_manage_inventory': canManageInventory,
        'can_manage_workers': canManageWorkers,
      };
}

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? tenantId;
  final String? phone;
  final bool isPrimary;
  final UserPermissions permissions;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.tenantId,
    this.phone,
    this.isPrimary = false,
    this.permissions = const UserPermissions(),
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final permissionsJson = json['permissions'];
    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'tenant_admin',
      tenantId: json['tenant_id']?.toString(),
      phone: json['phone']?.toString(),
      isPrimary:
          json['is_primary'] is bool ? json['is_primary'] as bool : false,
      permissions: UserPermissions.fromJson(
        permissionsJson is Map<String, dynamic> ? permissionsJson : const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'role': role,
        if (tenantId != null) 'tenant_id': tenantId,
        if (phone != null) 'phone': phone,
        'is_primary': isPrimary,
        'permissions': permissions.toJson(),
      };
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final String tokenType;
  final AppUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.tokenType,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresAt: (json['expires_at'] as num?)?.toInt() ?? 0,
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
