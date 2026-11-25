import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';

typedef SessionExpiredCallback = void Function();
typedef SubscriptionExpiredCallback = void Function(String message);

enum _TokenRefreshResult {
  refreshed,
  failed,
  unavailable,
  subscriptionExpired,
}

typedef RefreshDioFactory = Dio Function(BaseOptions options);

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final SessionExpiredCallback? onSessionExpired;
  final SubscriptionExpiredCallback? onSubscriptionExpired;
  final RefreshDioFactory _refreshDioFactory;

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    this.onSessionExpired,
    this.onSubscriptionExpired,
    RefreshDioFactory? refreshDioFactory,
  }) : _refreshDioFactory = refreshDioFactory ?? _createRefreshDio;

  static Dio _createRefreshDio(BaseOptions options) => Dio(options);

  Completer<_TokenRefreshResult>? _refreshCompleter;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final expiredMessage = _subscriptionExpiredMessage(response.data);
    if (expiredMessage != null) {
      onSubscriptionExpired?.call(expiredMessage);
    }
    handler.next(response);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    // Don't attach token on login or refresh endpoints
    if (!path.contains('/auth/login') && !path.contains('/auth/refresh')) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final path = err.requestOptions.path;
    final expiredMessage = _subscriptionExpiredMessage(response?.data);
    if (expiredMessage != null) {
      onSubscriptionExpired?.call(expiredMessage);
      return handler.next(err);
    }

    final isLoginOrRefreshEndpoint =
        path.contains('/auth/login') || path.contains('/auth/refresh');
    if (response?.statusCode == 401 && !isLoginOrRefreshEndpoint) {
      // Prevent multiple concurrent refreshes using a Completer lock
      final completer = _refreshCompleter ?? Completer<_TokenRefreshResult>();
      if (_refreshCompleter == null) {
        _refreshCompleter = completer;
        _doRefreshToken().then((result) {
          if (!completer.isCompleted) completer.complete(result);
          if (identical(_refreshCompleter, completer)) {
            _refreshCompleter = null;
          }
        }).catchError((_) {
          if (!completer.isCompleted) {
            completer.complete(_TokenRefreshResult.failed);
          }
          if (identical(_refreshCompleter, completer)) {
            _refreshCompleter = null;
          }
        });
      }

      final refreshResult = await completer.future;
      if (refreshResult == _TokenRefreshResult.refreshed) {
        final newToken = await tokenStorage.getAccessToken();
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        try {
          // Retry the request once with new token
          final retryResponse = await dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          if (e is DioException) {
            return handler.next(e);
          }
          return handler.next(err);
        }
      } else if (refreshResult == _TokenRefreshResult.failed) {
        // Refresh failed: clear storage and notify AuthCubit
        await tokenStorage.clearAll();
        onSessionExpired?.call();
      } else if (refreshResult == _TokenRefreshResult.unavailable) {
        return handler.next(
          DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.connectionError,
            error: err,
            message: 'Could not verify the saved session with the server.',
          ),
        );
      }
    }

    return handler.next(err);
  }

  Future<_TokenRefreshResult> _doRefreshToken() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return _TokenRefreshResult.failed;
      }

      // Create a fresh lightweight Dio instance to avoid interceptor recursion
      final refreshDio = _refreshDioFactory(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final expiredMessage = _subscriptionExpiredMessage(response.data);
      if (expiredMessage != null) {
        onSubscriptionExpired?.call(expiredMessage);
        return _TokenRefreshResult.subscriptionExpired;
      }

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final payload = data['data'] as Map<String, dynamic>;
          final access = payload['access_token']?.toString();
          final refresh = payload['refresh_token']?.toString();
          final expires = (payload['expires_at'] as num?)?.toInt() ?? 0;
          final userMap = payload['user'] as Map<String, dynamic>?;

          if (access != null && refresh != null) {
            await tokenStorage.saveAuthData(
              accessToken: access,
              refreshToken: refresh,
              expiresAt: expires,
              userId: userMap?['id']?.toString(),
              username: userMap?['username']?.toString(),
              fullName: userMap?['full_name']?.toString(),
              role: userMap?['role']?.toString(),
            );
            return _TokenRefreshResult.refreshed;
          }
        }
      }
    } on DioException catch (error) {
      final expiredMessage = _subscriptionExpiredMessage(error.response?.data);
      if (expiredMessage != null) {
        onSubscriptionExpired?.call(expiredMessage);
        return _TokenRefreshResult.subscriptionExpired;
      }
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return _TokenRefreshResult.failed;
      }
      return _TokenRefreshResult.unavailable;
    } catch (error, stackTrace) {
      debugPrint('Unexpected token refresh failure: $error\n$stackTrace');
      return _TokenRefreshResult.unavailable;
    }
    return _TokenRefreshResult.failed;
  }

  String? _subscriptionExpiredMessage(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) return null;
    final error = responseData['error'];
    if (error is! Map<String, dynamic> ||
        error['code']?.toString() != 'subscription_expired') {
      return null;
    }
    return error['message']?.toString() ??
        'انتهى اشتراك المنشأة، يرجى التواصل مع المطور للتجديد.';
  }
}
