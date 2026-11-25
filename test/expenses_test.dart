import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/expenses/data/models/expense_model.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/widgets/expense_receipt_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeExpensesRepository repository;

  setUpAll(ServicesLocator.setup);
  setUp(() {
    repository = _FakeExpensesRepository(_expenses());
    ServicesLocator.locator.unregister<ExpensesRepository>();
    ServicesLocator.locator.registerSingleton<ExpensesRepository>(repository);
  });

  testWidgets('all, recent, and other category filters stay distinct',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('مصروف حديث'), findsOneWidget);
    expect(find.text('مصروف قديم آخر'), findsOneWidget);
    expect(find.text('مصروف قديم كهرباء'), findsOneWidget);

    await tester.tap(find.text('الأخيرة'));
    await tester.pumpAndSettle();
    expect(find.text('مصروف حديث'), findsOneWidget);
    expect(find.text('مصروف قديم آخر'), findsNothing);
    expect(find.text('مصروف قديم كهرباء'), findsNothing);

    await tester.ensureVisible(find.text('أخرى'));
    await tester.tap(find.text('أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('مصروف حديث'), findsNothing);
    expect(find.text('مصروف قديم آخر'), findsOneWidget);
    expect(find.text('مصروف قديم كهرباء'), findsNothing);

    await tester.ensureVisible(find.text('الكل'));
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('مصروف حديث'), findsOneWidget);
    expect(find.text('مصروف قديم آخر'), findsOneWidget);
    expect(find.text('مصروف قديم كهرباء'), findsOneWidget);
  });

  testWidgets('expense details open and an attached receipt can be previewed',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('مصروف حديث'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل خاصة بالمصروف'), findsOneWidget);
    expect(find.text('القاعة: قاعة الاختبار'), findsOneWidget);
    expect(find.byType(ExpenseReceiptPreview), findsOneWidget);

    await tester.tap(find.byType(ExpenseReceiptPreview));
    await tester.pumpAndSettle();
    expect(find.text('معاينة الإيصال'), findsOneWidget);
  });

  test('remote expenses map nested category and receipt URL fields', () async {
    final repository = RemoteExpensesRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = _ExpenseResponseAdapter(),
    );

    final expenses = await repository.getExpenses();

    expect(expenses.single.category, 'مياه');
    expect(expenses.single.receiptImagePath, 'https://cdn.example/receipt.jpg');
  });

  test('expense receipt is uploaded as a multipart file', () async {
    final directory = await Directory.systemTemp.createTemp('qa3ty-receipt-');
    final file = File('${directory.path}${Platform.pathSeparator}receipt.png');
    await file.writeAsBytes([1, 2, 3]);
    final adapter = _ExpenseUploadAdapter();
    final repository = RemoteExpensesRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    try {
      await repository.addExpense(
        Expense(
          id: 'expense-1',
          title: 'فاتورة مياه',
          category: 'مياه',
          hallId: 'all',
          hallName: 'عام لجميع القاعات',
          amount: 250,
          date: DateTime(2026, 11, 24),
          receiptImagePath: file.path,
        ),
      );

      expect(adapter.contentType, contains('multipart/form-data'));
      expect(adapter.body, contains('name="receipt"'));
      expect(adapter.body, contains('receipt.png'));
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

Widget _testApp() {
  return const MaterialApp(
    home: ExpensesScreen(),
  );
}

List<Expense> _expenses() {
  final now = DateTime.now();
  return [
    Expense(
      id: 'recent',
      title: 'مصروف حديث',
      category: 'كهرباء',
      hallId: 'hall',
      hallName: 'قاعة الاختبار',
      amount: 100,
      date: now.subtract(const Duration(days: 2)),
      receiptImagePath: r'C:\receipt-that-is-not-on-disk.png',
      note: 'تفاصيل خاصة بالمصروف',
    ),
    Expense(
      id: 'other',
      title: 'مصروف قديم آخر',
      category: 'أخرى',
      hallId: 'hall',
      hallName: 'قاعة الاختبار',
      amount: 200,
      date: now.subtract(const Duration(days: 45)),
    ),
    Expense(
      id: 'electricity',
      title: 'مصروف قديم كهرباء',
      category: 'كهرباء',
      hallId: 'hall',
      hallName: 'قاعة الاختبار',
      amount: 300,
      date: now.subtract(const Duration(days: 45)),
    ),
  ];
}

class _FakeExpensesRepository implements ExpensesRepository {
  final List<Expense> expenses;

  _FakeExpensesRepository(this.expenses);

  @override
  Future<List<Expense>> getExpenses() async => expenses;

  @override
  Future<void> addExpense(Expense expense) async {}

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense(String id) async {}
}

class _ExpenseResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.uri.path == '/expense-categories'
        ? '{"success":true,"data":[]}'
        : '''
          {"success":true,"data":{"items":[{
            "id":"expense-1",
            "description":"فاتورة مياه",
            "amount":250,
            "expense_date":"2026-11-24",
            "expense_categories":{"name":"مياه"},
            "receipt_path":null,
            "receipt_url":"https://cdn.example/receipt.jpg"
          }]}}
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

class _ExpenseUploadAdapter implements HttpClientAdapter {
  String? contentType;
  String body = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path == '/expense-categories') {
      return ResponseBody.fromString(
        '{"success":true,"data":[{"id":"water-id","name":"مياه"}]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    contentType = options.headers[Headers.contentTypeHeader]?.toString();
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      body = String.fromCharCodes(bytes);
    }
    return ResponseBody.fromString(
      '{"success":true}',
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
