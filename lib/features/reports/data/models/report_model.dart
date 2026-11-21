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
