import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  const TokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresAt = 'expires_at';
  static const _keyUserId = 'user_id';
  static const _keyUsername = 'username';
  static const _keyFullName = 'full_name';
  static const _keyRole = 'role';
  static const _keyTenantId = 'tenant_id';

  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
    String? userId,
    String? username,
    String? fullName,
    String? role,
    String? tenantId,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      _storage.write(key: _keyExpiresAt, value: expiresAt.toString()),
      if (userId != null) _storage.write(key: _keyUserId, value: userId),
      if (username != null) _storage.write(key: _keyUsername, value: username),
      if (fullName != null) _storage.write(key: _keyFullName, value: fullName),
      if (role != null) _storage.write(key: _keyRole, value: role),
      if (tenantId != null) _storage.write(key: _keyTenantId, value: tenantId),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<int?> getExpiresAt() async {
    final val = await _storage.read(key: _keyExpiresAt);
    return val != null ? int.tryParse(val) : null;
  }

  Future<String?> getUserId() => _storage.read(key: _keyUserId);
  Future<String?> getUsername() => _storage.read(key: _keyUsername);
  Future<String?> getFullName() => _storage.read(key: _keyFullName);
  Future<String?> getRole() => _storage.read(key: _keyRole);
  Future<String?> getTenantId() => _storage.read(key: _keyTenantId);

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
