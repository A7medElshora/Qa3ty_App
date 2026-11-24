import 'package:qa3ty_app/core/networking/api_exceptions.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiException? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final success = json['success'] == true;
    if (success) {
      return ApiResponse<T>(
        success: true,
        data: json['data'] != null ? fromJsonT(json['data']) : null,
      );
    } else {
      final errMap = json['error'] as Map<String, dynamic>?;
      final code = errMap?['code']?.toString() ?? 'unknown_error';
      final message = errMap?['message']?.toString() ?? 'حدث خطأ غير متوقع.';
      throw ApiException(code: code, message: message);
    }
  }

  T get requireData {
    if (!success || data == null) {
      throw error ?? const ApiException(code: 'no_data', message: 'البيانات غير متوفرة.');
    }
    return data!;
  }
}

class PaginationMeta {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  const PaginationMeta({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] == true,
    );
  }
}

class PagedResult<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PagedResult({
    required this.items,
    required this.pagination,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic itemJson) fromItemJson,
  ) {
    final itemsList = (json['items'] as List<dynamic>?) ?? [];
    final items = itemsList.map((e) => fromItemJson(e)).toList();
    final pagination = json['pagination'] != null
        ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
        : PaginationMeta(total: items.length, limit: items.length, offset: 0, hasMore: false);

    return PagedResult<T>(
      items: items,
      pagination: pagination,
    );
  }
}
