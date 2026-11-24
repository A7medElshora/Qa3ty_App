import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/networking/auth_interceptor.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';
import 'package:qa3ty_app/features/auth/data/repos/auth_repository.dart';
import 'package:qa3ty_app/features/auth/presentation/cubits/auth_cubit.dart';

void main() {
  test('subscription_expired API errors invoke the global callback', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
      ..httpClientAdapter = _ExpiredSubscriptionAdapter();
    String? receivedMessage;
    var sessionExpired = false;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: _MemoryTokenStorage(),
        dio: dio,
        onSubscriptionExpired: (message) => receivedMessage = message,
        onSessionExpired: () => sessionExpired = true,
      ),
    );

    await expectLater(dio.get('/halls'), throwsA(isA<DioException>()));
    expect(receivedMessage, 'انتهى الاشتراك');
    expect(sessionExpired, isFalse);
  });

  test('auth state exposes the subscription-expired route state', () async {
    final cubit = AuthCubit(MockAuthRepository());
    cubit.onSubscriptionExpired('انتهى الاشتراك');

    expect(cubit.state, isA<SubscriptionExpiredState>());
    expect(
      (cubit.state as SubscriptionExpiredState).message,
      'انتهى الاشتراك',
    );
    await cubit.close();
  });
}

class _ExpiredSubscriptionAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'success': false,
        'error': {
          'code': 'subscription_expired',
          'message': 'انتهى الاشتراك',
        },
      }),
      401,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clearAll() async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<int?> getExpiresAt() async => null;

  @override
  Future<String?> getFullName() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<String?> getRole() async => null;

  @override
  Future<String?> getTenantId() async => null;

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<String?> getUsername() async => null;

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
    String? userId,
    String? username,
    String? fullName,
    String? role,
    String? tenantId,
  }) async {}
}
