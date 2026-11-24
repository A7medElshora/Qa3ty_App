import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/config/env.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException(code: $code, message: $message, statusCode: $statusCode)';

  factory ApiException.fromDioError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data['error'] is Map<String, dynamic>) {
        final err = data['error'] as Map<String, dynamic>;
        return ApiException(
          code: err['code']?.toString() ?? 'unknown_error',
          message: err['message']?.toString() ?? 'حدث خطأ غير متوقع.',
          statusCode: error.response?.statusCode,
        );
      }
    }

    // Network / Timeout exceptions
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        final baseUrl = AppConfig.current.baseUrl;
        final devMessage = 'تعذّر الوصول للسيرفر على $baseUrl';
        const prodMessage = 'لا يوجد اتصال بالإنترنت أو تعذّر الوصول للخادم.';
        return ApiException(
          code: 'network_error',
          message: AppConfig.current.isDevelopment ? devMessage : prodMessage,
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          code: 'request_cancelled',
          message: 'تم إلغاء الطلب.',
        );
      default:
        final status = error.response?.statusCode;
        if (status == 404) {
          return const ApiException(
            code: 'not_found',
            message: 'العنصر غير موجود.',
            statusCode: 404,
          );
        }
        return ApiException(
          code: 'server_error',
          message: 'حدث خطأ في الخادم (${status ?? "بدون استجابة"}). يرجى المحاولة لاحقاً.',
          statusCode: status,
        );
    }
  }
}

// Domain Failure representation
abstract class Failure {
  final String code;
  final String message;
  const Failure({required this.code, required this.message});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure({super.code = 'server_error', required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.code = 'network_error', required super.message});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.code = 'unauthorized', required super.message});
}

class AccountSuspendedFailure extends Failure {
  const AccountSuspendedFailure({super.code = 'account_suspended', required super.message});
}

class SubscriptionExpiredFailure extends Failure {
  const SubscriptionExpiredFailure({super.code = 'subscription_expired', required super.message});
}

class BookingConflictFailure extends Failure {
  const BookingConflictFailure({super.code = 'booking_conflict', required super.message});
}

class PaymentExceedsBalanceFailure extends Failure {
  const PaymentExceedsBalanceFailure({super.code = 'payment_exceeds_balance', required super.message});
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure({super.code = 'insufficient_stock', required super.message});
}

class CustomerHasBookingsFailure extends Failure {
  const CustomerHasBookingsFailure({super.code = 'customer_has_bookings', required super.message});
}

class ValidationErrorFailure extends Failure {
  const ValidationErrorFailure({super.code = 'validation_error', required super.message});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.code = 'not_found', required super.message});
}

class FailureMapper {
  static Failure fromException(Object exception) {
    if (exception is ApiException) {
      switch (exception.code) {
        case 'unauthorized':
        case 'invalid_token':
        case 'invalid_credentials':
          return UnauthorizedFailure(message: exception.message);
        case 'account_suspended':
          return AccountSuspendedFailure(message: exception.message);
        case 'subscription_expired':
          return SubscriptionExpiredFailure(message: exception.message);
        case 'booking_conflict':
          return BookingConflictFailure(message: exception.message);
        case 'payment_exceeds_balance':
          return PaymentExceedsBalanceFailure(message: exception.message);
        case 'insufficient_stock':
          return InsufficientStockFailure(message: exception.message);
        case 'customer_has_bookings':
          return CustomerHasBookingsFailure(message: exception.message);
        case 'validation_error':
          return ValidationErrorFailure(message: exception.message);
        case 'not_found':
          return NotFoundFailure(message: exception.message);
        case 'network_error':
          return NetworkFailure(message: exception.message);
        default:
          return ServerFailure(code: exception.code, message: exception.message);
      }
    } else if (exception is DioException) {
      return fromException(ApiException.fromDioError(exception));
    }
    return ServerFailure(message: exception.toString());
  }
}
