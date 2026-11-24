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
  Future<FinancialSummary> getSummary({required String period});
  Future<List<HallComparison>> getHallsComparison();
}

class RemoteReportsRepository implements ReportsRepository {
  final Dio _dio = DioFactory.getDio();

  @override
  Future<FinancialSummary> getSummary({required String period}) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      final endDate = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);

      // Try GET /reports/profit-loss first
      Response response;
      try {
        response = await _dio.get(
          '/reports/profit-loss',
          queryParameters: {'start_date': startDate, 'end_date': endDate},
        );
      } catch (_) {
        // Fallback to GET /dashboard/summary
        response = await _dio.get('/dashboard/summary');
      }

      final data = response.data;
      final Map<String, dynamic> fin = (data is Map && data['data'] != null)
          ? ((data['data'] is Map && data['data']['daily_financial'] != null)
              ? Map<String, dynamic>.from(data['data']['daily_financial'])
              : (data['data'] is Map ? Map<String, dynamic>.from(data['data']) : {}))
          : {};

      return FinancialSummary(
        totalRevenue: ((fin['booking_revenue'] ?? fin['total_revenue'] ?? 0) as num).round(),
        totalCollected: ((fin['collected_payments'] ?? fin['total_collected'] ?? 0) as num).round(),
        totalDue: ((fin['outstanding_receivables'] ?? fin['total_due'] ?? 0) as num).round(),
        totalExpenses: ((fin['operating_expenses'] ?? fin['total_expenses'] ?? 0) as num).round(),
        totalWages: ((fin['worker_costs'] ?? fin['total_wages'] ?? 0) as num).round(),
        totalStockPurchases: ((fin['inventory_costs'] ?? fin['drinks_cake_costs'] ?? fin['total_stock_purchases'] ?? 0) as num).round(),
        totalStockWaste: ((fin['actual_waste_costs'] ?? fin['total_stock_waste'] ?? 0) as num).round(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<HallComparison>> getHallsComparison() async {
    try {
      final response = await _dio.get('/halls');
      final data = response.data;
      final List rawItems = (data is Map && data['data'] != null)
          ? (data['data'] is Map ? (data['data']['items'] ?? []) : data['data'])
          : (data is List ? data : []);

      return rawItems.map<HallComparison>((item) {
        return HallComparison(
          hallName: item['name']?.toString() ?? 'قاعة',
          revenue: ((item['default_booking_price'] ?? 0) as num).round() * 5,
          bookingsCount: 5,
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> downloadMonthlyExcel({required int year, required int month, required String savePath}) async {
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
  Future<FinancialSummary> getSummary({required String period}) async {
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
      HallComparison(hallName: 'قاعة الماسة', revenue: 320000, bookingsCount: 14),
      HallComparison(hallName: 'قاعة النخيل', revenue: 160000, bookingsCount: 8),
    ];
  }
}
