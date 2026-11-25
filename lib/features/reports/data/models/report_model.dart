import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';

class FinancialSummary {
  final int totalRevenue;
  final int totalCollected;
  final int totalDue;
  final int totalExpenses;
  final int totalWages;
  final int totalStockPurchases;
  final int totalStockWaste;

  const FinancialSummary({
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalDue,
    required this.totalExpenses,
    required this.totalWages,
    required this.totalStockPurchases,
    required this.totalStockWaste,
  });

  int get netProfit =>
      totalCollected - (totalExpenses + totalWages + totalStockPurchases);
}

class HallComparison {
  final String hallName;
  final int revenue;
  final int bookingsCount;

  const HallComparison({
    required this.hallName,
    required this.revenue,
    required this.bookingsCount,
  });
}

abstract class ReportsRepository {
  Future<FinancialSummary> getSummary({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<HallComparison>> getHallsComparison();
}

class RemoteReportsRepository implements ReportsRepository {
  final Dio _dio;

  RemoteReportsRepository([Dio? dio]) : _dio = dio ?? DioFactory.getDio();

  @override
  Future<FinancialSummary> getSummary({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = period == 'مخصص'
          ? (startDate ?? DateTime(now.year, now.month, 1))
          : period == 'سنة'
              ? DateTime(now.year, 1, 1)
              : DateTime(now.year, now.month, 1);
      final end = period == 'مخصص'
          ? (endDate ?? DateTime(now.year, now.month + 1, 0))
          : period == 'سنة'
              ? DateTime(now.year, 12, 31)
              : DateTime(now.year, now.month + 1, 0);
      final startDateString = start.toIso8601String().substring(0, 10);
      final endDateString = end.toIso8601String().substring(0, 10);

      // Try GET /reports/profit-loss first
      Response response;
      try {
        response = await _dio.get(
          '/reports/profit-loss',
          queryParameters: {
            'start_date': startDateString,
            'end_date': endDateString,
          },
        );
      } on DioException {
        if (period == 'مخصص') rethrow;
        // Fallback to GET /dashboard/summary
        response = await _dio.get('/dashboard/summary');
      }

      final data = response.data;
      final Map<String, dynamic> fin = (data is Map && data['data'] != null)
          ? ((data['data'] is Map && data['data']['daily_financial'] != null)
              ? Map<String, dynamic>.from(data['data']['daily_financial'])
              : (data['data'] is Map
                  ? Map<String, dynamic>.from(data['data'])
                  : {}))
          : {};

      return FinancialSummary(
        totalRevenue:
            ((fin['booking_revenue'] ?? fin['total_revenue'] ?? 0) as num)
                .round(),
        totalCollected:
            ((fin['collected_payments'] ?? fin['total_collected'] ?? 0) as num)
                .round(),
        totalDue:
            ((fin['outstanding_receivables'] ?? fin['total_due'] ?? 0) as num)
                .round(),
        totalExpenses:
            ((fin['operating_expenses'] ?? fin['total_expenses'] ?? 0) as num)
                .round(),
        totalWages:
            ((fin['worker_costs'] ?? fin['total_wages'] ?? 0) as num).round(),
        totalStockPurchases: ((fin['inventory_costs'] ??
                fin['drinks_cake_costs'] ??
                fin['total_stock_purchases'] ??
                0) as num)
            .round(),
        totalStockWaste: ((fin['actual_waste_costs'] ??
                fin['total_stock_waste'] ??
                0) as num)
            .round(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<HallComparison>> getHallsComparison() async {
    try {
      final hallsResponse = await _dio.get('/halls');
      final halls = _extractItems(hallsResponse.data);
      final bookings = await _getAllBookingItems();
      final revenueByHall = <String, int>{};
      final bookingsByHall = <String, int>{};

      for (final booking in bookings) {
        if (booking['status'] == 'cancelled') continue;
        final nestedHall = booking['halls'];
        final hallId = booking['hall_id']?.toString() ??
            (nestedHall is Map<String, dynamic>
                ? nestedHall['id']?.toString()
                : null);
        final totalPrice = booking['total_price'];
        if (hallId == null || totalPrice is! num) continue;
        revenueByHall.update(
          hallId,
          (revenue) => revenue + totalPrice.round(),
          ifAbsent: () => totalPrice.round(),
        );
        bookingsByHall.update(
          hallId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      return halls.map<HallComparison>((item) {
        final hallId = item['id']?.toString() ?? '';
        return HallComparison(
          hallName: item['name']?.toString() ?? 'قاعة',
          revenue: revenueByHall[hallId] ?? 0,
          bookingsCount: bookingsByHall[hallId] ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> _getAllBookingItems() async {
    const pageSize = 100;
    final bookings = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final response = await _dio.get(
        '/bookings',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );
      final data = response.data;
      final page = data is Map<String, dynamic> ? data['data'] : null;
      final items = _extractItems(data);
      bookings.addAll(items);

      final pagination =
          page is Map<String, dynamic> ? page['pagination'] : null;
      if (items.isEmpty ||
          pagination is! Map<String, dynamic> ||
          pagination['has_more'] != true) {
        break;
      }
      offset += items.length;
    }

    return bookings;
  }

  List<Map<String, dynamic>> _extractItems(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    }
    if (responseData is List) {
      return responseData.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> downloadMonthlyExcel(
      {required int year, required int month, required String savePath}) async {
    try {
      await _dio.download(
        '/reports/export/excel?year=$year&month=$month',
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class MockReportsRepository implements ReportsRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  @override
  Future<FinancialSummary> getSummary({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const FinancialSummary(
      totalRevenue: 480000,
      totalCollected: 310000,
      totalDue: 170000,
      totalExpenses: 27400,
      totalWages: 18500,
      totalStockPurchases: 12000,
      totalStockWaste: 2100,
    );
  }

  @override
  Future<List<HallComparison>> getHallsComparison() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return const [
      HallComparison(
          hallName: 'قاعة الماسة', revenue: 320000, bookingsCount: 14),
      HallComparison(
          hallName: 'قاعة النخيل', revenue: 160000, bookingsCount: 8),
    ];
  }
}
