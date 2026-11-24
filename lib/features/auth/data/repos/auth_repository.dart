import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/api_response.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<AppUser> getCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<bool> hasValidToken();
}

class RemoteAuthRepository implements AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  RemoteAuthRepository(this._dio, this._tokenStorage);

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final apiRes = ApiResponse<AuthSession>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthSession.fromJson(json as Map<String, dynamic>),
      );

      final session = apiRes.requireData;
      await _tokenStorage.saveAuthData(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt,
        userId: session.user.id,
        username: session.user.username,
        fullName: session.user.fullName,
        role: session.user.role,
        tenantId: session.user.tenantId,
      );

      return session;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Clear local credentials even if server request fails
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  @override
  Future<AppUser> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final apiRes = ApiResponse<AppUser>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AppUser.fromJson(json as Map<String, dynamic>),
      );
      return apiRes.requireData;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] != true) {
          final err = data['error'] as Map<String, dynamic>?;
          throw ApiException(
            code: err?['code']?.toString() ?? 'password_update_failed',
            message: err?['message']?.toString() ?? 'تعذر تغيير كلمة المرور.',
          );
        }
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> hasValidToken() => _tokenStorage.hasValidToken();
}

class MockAuthRepository implements AuthRepository {
  AppUser _mockUser = const AppUser(
    id: 'mock-user-1',
    username: 'ahmed',
    fullName: 'أحمد السعيد',
    role: 'tenant_admin',
    tenantId: 'mock-tenant-1',
    isPrimary: true,
    permissions: UserPermissions(
      canManageBookings: true,
      canViewReports: true,
      canManageExpenses: true,
      canManageInventory: true,
      canManageWorkers: true,
      canManageSubAccounts: true,
    ),
  );

  bool _isLoggedIn = true;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoggedIn = true;
    _mockUser = AppUser(
      id: 'mock-user-1',
      username: username,
      fullName: username == 'hall_owner' ? 'أحمد السعيد' : username,
      role: 'tenant_admin',
      tenantId: 'mock-tenant-1',
      isPrimary: true,
      permissions: const UserPermissions(
        canManageBookings: true,
        canViewReports: true,
        canManageExpenses: true,
        canManageInventory: true,
        canManageWorkers: true,
        canManageSubAccounts: true,
      ),
    );
    return AuthSession(
      accessToken: 'mock_jwt_token',
      refreshToken: 'mock_refresh_token',
      expiresAt:
          DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/
              1000,
      tokenType: 'bearer',
      user: _mockUser,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoggedIn = false;
  }

  @override
  Future<AppUser> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!_isLoggedIn) {
      throw const ApiException(
          code: 'unauthorized', message: 'يلزم تسجيل الدخول.');
    }
    return _mockUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> hasValidToken() async => _isLoggedIn;
}
