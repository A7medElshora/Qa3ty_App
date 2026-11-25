import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/features/reports/data/models/report_model.dart';
import 'package:qa3ty_app/features/reports/data/report_export.dart';

void main() {
  test('financial report CSV contains editable figures and escaped hall names',
      () {
    final bytes = buildFinancialReportCsv(
      period: 'شهر',
      generatedAt: DateTime(2026, 11, 24),
      summary: const FinancialSummary(
        totalRevenue: 120000,
        totalCollected: 90000,
        totalDue: 30000,
        totalExpenses: 12000,
        totalWages: 5000,
        totalStockPurchases: 3000,
        totalStockWaste: 500,
      ),
      comparisons: const [
        HallComparison(
          hallName: 'قاعة "الماسة"',
          revenue: 80000,
          bookingsCount: 4,
        ),
      ],
    );
    final csv = utf8.decode(bytes);

    expect(bytes.take(3).toList(), equals([0xEF, 0xBB, 0xBF]));
    expect(csv, contains('"صافي الأرباح المحققة","70000"'));
    expect(csv, contains('"قاعة ""الماسة""","80000"'));
    expect(csv, contains('"الإيرادات بالجنيه المصري"'));
    expect(csv, contains('"تاريخ التصدير","2026-11-24T00:00:00.000"'));
  });

  test('hall comparison uses completed booking values, not default prices',
      () async {
    final repository = RemoteReportsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = _HallComparisonAdapter(),
    );

    final comparisons = await repository.getHallsComparison();

    expect(comparisons, hasLength(2));
    expect(comparisons[0].revenue, 80000);
    expect(comparisons[0].bookingsCount, 2);
    expect(comparisons[1].revenue, 0);
    expect(comparisons[1].bookingsCount, 0);
  });

  test('custom financial report sends the selected date range', () async {
    final adapter = _ReportRangeAdapter();
    final repository = RemoteReportsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    await repository.getSummary(
      period: 'مخصص',
      startDate: DateTime(2026, 10, 5),
      endDate: DateTime(2026, 11, 12),
    );

    expect(adapter.startDate, '2026-10-05');
    expect(adapter.endDate, '2026-11-12');
  });
}

class _HallComparisonAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.uri.path == '/halls'
        ? '''
          {"success":true,"data":{"items":[
            {"id":"hall-1","name":"القاعة الأولى","default_booking_price":90000},
            {"id":"hall-2","name":"القاعة الثانية","default_booking_price":50000}
          ]}}
        '''
        : '''
          {"success":true,"data":{"items":[
            {"hall_id":"hall-1","total_price":50000,"status":"confirmed"},
            {"hall_id":"hall-1","total_price":30000,"status":"confirmed"},
            {"hall_id":"hall-1","total_price":10000,"status":"cancelled"}
          ],"pagination":{"has_more":false}}}
        ''';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ReportRangeAdapter implements HttpClientAdapter {
  String? startDate;
  String? endDate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    startDate = options.queryParameters['start_date']?.toString();
    endDate = options.queryParameters['end_date']?.toString();
    return ResponseBody.fromString(
      '{"success":true,"data":{"booking_revenue":100,"collected_payments":50}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
