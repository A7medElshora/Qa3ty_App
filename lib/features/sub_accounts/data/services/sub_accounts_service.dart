import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/networking/api_constants.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/features/auth/data/models/user_model.dart';
import 'package:qa3ty_app/features/sub_accounts/data/models/sub_account_model.dart';

class SubAccountsService {
  final Dio _dio;
  static final List<SubAccountModel> _mockAccounts = [];
  static final Map<String, String> _mockPasswords = {};
  static int _nextMockId = 1;

  const SubAccountsService(this._dio);

  Future<List<SubAccountModel>> getSubAccounts() async {
    if (AppConfig.current.useMockData) {
      return List.unmodifiable(_mockAccounts);
    }
    try {
      final response = await _dio.get(ApiConstants.subAccounts);
      final data = _dataFrom(response.data);
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('قائمة الحسابات الفرعية غير صالحة.');
      }
      return items
          .map((item) => SubAccountModel.fromJson(_objectFrom(item)))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<SubAccountModel> createSubAccount({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    required UserPermissions permissions,
  }) async {
    if (AppConfig.current.useMockData) {
      final account = SubAccountModel(
        id: 'mock-sub-account-${_nextMockId++}',
        username: username,
        fullName: fullName,
        phone: phone,
        isActive: true,
        isPrimary: false,
        permissions: permissions,
        createdAt: DateTime.now().toIso8601String(),
      );
      _mockAccounts.add(account);
      _mockPasswords[account.id] = password;
      return account;
    }
    try {
      final response = await _dio.post(
        ApiConstants.subAccounts,
        data: {
          'username': username,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'permissions': permissions.toJson(),
        },
      );
      return SubAccountModel.fromJson(_objectFrom(_dataFrom(response.data)));
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<SubAccountModel> updateSubAccount({
    required String id,
    String? fullName,
    String? phone,
    bool? isActive,
    UserPermissions? permissions,
  }) async {
    if (AppConfig.current.useMockData) {
      final index = _mockAccounts.indexWhere((account) => account.id == id);
      if (index < 0) {
        throw const ApiException(
          code: 'not_found',
          message: 'الحساب غير موجود.',
          statusCode: 404,
        );
      }
      final account = _mockAccounts[index].copyWith(
        fullName: fullName,
        phone: phone,
        isActive: isActive,
        permissions: permissions,
      );
      _mockAccounts[index] = account;
      return account;
    }
    try {
      final response = await _dio.patch(
        ApiConstants.subAccountDetails.replaceFirst('{id}', id),
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
          if (isActive != null) 'is_active': isActive,
          if (permissions != null) 'permissions': permissions.toJson(),
        },
      );
      return SubAccountModel.fromJson(_objectFrom(_dataFrom(response.data)));
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<void> resetPassword(String id, String newPassword) async {
    if (AppConfig.current.useMockData) {
      if (!_mockPasswords.containsKey(id)) {
        throw const ApiException(
          code: 'not_found',
          message: 'الحساب غير موجود.',
          statusCode: 404,
        );
      }
      _mockPasswords[id] = newPassword;
      return;
    }
    try {
      await _dio.post(
        ApiConstants.subAccountResetPassword.replaceFirst('{id}', id),
        data: {'new_password': newPassword},
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Future<void> deleteSubAccount(String id) async {
    if (AppConfig.current.useMockData) {
      final exists = _mockAccounts.any((account) => account.id == id);
      if (!exists) {
        throw const ApiException(
          code: 'not_found',
          message: 'الحساب غير موجود.',
          statusCode: 404,
        );
      }
      _mockAccounts.removeWhere((account) => account.id == id);
      _mockPasswords.remove(id);
      return;
    }
    try {
      await _dio.delete(
        ApiConstants.subAccountDetails.replaceFirst('{id}', id),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioError(error);
    }
  }

  Map<String, dynamic> _dataFrom(dynamic response) {
    final payload = _objectFrom(response);
    if (payload['success'] == false) {
      final error = payload['error'];
      final errorObject =
          error is Map<String, dynamic> ? error : const <String, dynamic>{};
      throw ApiException(
        code: errorObject['code']?.toString() ?? 'sub_account_request_failed',
        message: errorObject['message']?.toString() ??
            'تعذر إتمام طلب الحساب الفرعي.',
      );
    }
    return _objectFrom(payload['data']);
  }

  Map<String, dynamic> _objectFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('استجابة الحساب الفرعي غير صالحة.');
  }
}
