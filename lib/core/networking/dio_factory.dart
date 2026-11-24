import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/networking/auth_interceptor.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';

class DioFactory {
  DioFactory._();

  static Dio? _dio;
  static SessionExpiredCallback? _onSessionExpired;
  static SubscriptionExpiredCallback? _onSubscriptionExpired;

  static void setSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  static void setSubscriptionExpiredCallback(
    SubscriptionExpiredCallback callback,
  ) {
    _onSubscriptionExpired = callback;
  }

  static Dio getDio({TokenStorage? tokenStorage}) {
    const Duration timeout = Duration(seconds: 15);

    if (_dio == null) {
      final storage = tokenStorage ?? const TokenStorage();

      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.current.baseUrl,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Auth Interceptor with queue & token refresh
      _dio!.interceptors.add(
        AuthInterceptor(
          tokenStorage: storage,
          dio: _dio!,
          onSessionExpired: () => _onSessionExpired?.call(),
          onSubscriptionExpired: (message) =>
              _onSubscriptionExpired?.call(message),
        ),
      );

      // LogInterceptor ONLY in development, masking sensitive data
      if (AppConfig.current.isDevelopment) {
        _dio!.interceptors.add(
          PrettyDioLogger(
            requestBody: false,
            requestHeader:
                false, // Don't log headers to prevent Authorization leak
            responseHeader: false,
            responseBody: true,
            compact: true,
          ),
        );
      }

      return _dio!;
    } else {
      // Keep baseUrl in sync if config changed
      _dio!.options.baseUrl = AppConfig.current.baseUrl;
      return _dio!;
    }
  }

  static void reset() {
    _dio = null;
  }
}
