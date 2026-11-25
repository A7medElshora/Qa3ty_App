import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/networking/auth_interceptor.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';
import 'package:qa3ty_app/features/auth/data/repos/auth_repository.dart';

void main() {
  test('login saves the returned session for later app launches', () async {
    final storage = _MemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
      ..httpClientAdapter = _LoginAdapter();
    final repository = RemoteAuthRepository(dio, storage);

    await repository.login(username: 'owner', password: 'secret');

    expect(await storage.getAccessToken(), 'access-token');
    expect(await storage.getRefreshToken(), 'refresh-token');
    expect(await storage.hasValidToken(), isTrue);
  });

  test('expired auth/me access token is refreshed and retried', () async {
    final storage = _MemoryTokenStorage()
      ..accessToken = 'expired-access'
      ..refreshToken = 'valid-refresh';
    final apiAdapter = _ProtectedApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
      ..httpClientAdapter = apiAdapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        dio: dio,
        refreshDioFactory: (options) =>
            Dio(options)..httpClientAdapter = _RefreshAdapter(),
      ),
    );

    final response = await dio.get('/auth/me');

    expect(response.statusCode, 200);
    expect(apiAdapter.authMeRequests, 2);
    expect(await storage.getAccessToken(), 'new-access');
    expect(await storage.getRefreshToken(), 'new-refresh');
  });

  test('temporary refresh failure does not clear a saved login session',
      () async {
    final storage = _MemoryTokenStorage()
      ..accessToken = 'expired-access'
      ..refreshToken = 'valid-refresh';
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example'))
      ..httpClientAdapter = _UnauthorizedApiAdapter();
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        dio: dio,
        refreshDioFactory: (options) =>
            Dio(options)..httpClientAdapter = _UnavailableRefreshAdapter(),
      ),
    );

    await expectLater(dio.get('/auth/me'), throwsA(isA<DioException>()));

    expect(await storage.getAccessToken(), 'expired-access');
    expect(await storage.getRefreshToken(), 'valid-refresh');
  });
}

class _MemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clearAll() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<int?> getExpiresAt() async => null;

  @override
  Future<String?> getFullName() async => null;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getRole() async => null;

  @override
  Future<String?> getTenantId() async => null;

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<String?> getUsername() async => null;

  @override
  Future<bool> hasValidToken() async =>
      accessToken != null && accessToken!.isNotEmpty;

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
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class _LoginAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'expires_at': 1795500000,
          'token_type': 'bearer',
          'user': {
            'id': 'user-id',
            'username': 'owner',
            'full_name': 'Hall Owner',
            'role': 'tenant_admin',
            'tenant_id': 'tenant-id',
          },
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ProtectedApiAdapter implements HttpClientAdapter {
  int authMeRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authMeRequests++;
    if (options.headers['Authorization'] == 'Bearer new-access') {
      return ResponseBody.fromString(
        '{"success":true,"data":{"id":"user-id"}}',
        200,
      );
    }
    return _unauthorized(options);
  }

  @override
  void close({bool force = false}) {}
}

class _UnauthorizedApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _unauthorized(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _unauthorized(RequestOptions options) => ResponseBody.fromString(
      '{"success":false,"error":{"code":"unauthorized","message":"Unauthorized"}}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _RefreshAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '''
      {"success":true,"data":{
        "access_token":"new-access",
        "refresh_token":"new-refresh",
        "expires_at":1795500000,
        "user":{"id":"user-id","username":"owner","full_name":"Hall Owner","role":"tenant_admin"}
      }}
      ''',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnavailableRefreshAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
