import 'dart:convert';

import 'models/report_model.dart';

List<int> buildFinancialReportCsv({
  required String period,
  required DateTime generatedAt,
  required FinancialSummary summary,
  required List<HallComparison> comparisons,
}) {
  final rows = <List<Object?>>[
    ['تقرير قاعتي المالي'],
    ['الفترة', period],
    ['تاريخ التصدير', generatedAt.toIso8601String()],
    [],
    ['ملخص الحسابات', 'القيمة بالجنيه المصري'],
    ['إجمالي الإيرادات التعاقدية', summary.totalRevenue],
    ['المبالغ المحصلة فعلياً', summary.totalCollected],
    ['المبالغ المستحقة المتبقية', summary.totalDue],
    ['المصروفات التشغيلية', summary.totalExpenses],
    ['أجور ورواتب العمال', summary.totalWages],
    ['مشتريات المخزون', summary.totalStockPurchases],
    ['قيمة الهالك والتالف', summary.totalStockWaste],
    ['صافي الأرباح المحققة', summary.netProfit],
    [],
    ['مقارنة إيرادات القاعات', 'الإيرادات بالجنيه المصري'],
    ...comparisons.map(
      (comparison) => [
        comparison.hallName,
        comparison.revenue,
      ],
    ),
  ];

  final csv = rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\r\n');
  return [0xEF, 0xBB, 0xBF, ...utf8.encode('$csv\r\n')];
}

String _escapeCsvCell(Object? value) {
  final text = value?.toString() ?? '';
  return '"${text.replaceAll('"', '""')}"';
}
