import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';

class Expense {
  final String id;
  final String title;
  final String
      category; // كهرباء, مياه, صيانة, بنزين, مواصلات, نظافة, مستلزمات, أخرى
  final String hallId; // or 'all' for general expense
  final String hallName;
  final int amount;
  final DateTime date;
  final String? receiptImagePath;
  final String? note;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.hallId,
    required this.hallName,
    required this.amount,
    required this.date,
    this.receiptImagePath,
    this.note,
  });

  Expense copyWith({
    String? id,
    String? title,
    String? category,
    String? hallId,
    String? hallName,
    int? amount,
    DateTime? date,
    String? receiptImagePath,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      note: note ?? this.note,
    );
  }
}

abstract class ExpensesRepository {
  Future<List<Expense>> getExpenses();
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}

class RemoteExpensesRepository implements ExpensesRepository {
  final Dio _dio;

  RemoteExpensesRepository(this._dio);

  final List<Expense> _localExpenses = [];
  Map<String, String>? _categoryNameToId;

  Future<void> _ensureCategories() async {
    if (_categoryNameToId != null) return;
    try {
      final response = await _dio.get('/expense-categories');
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final list = response.data['data'] as List<dynamic>;
        _categoryNameToId = {};
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final name = item['name']?.toString() ?? '';
            final id = item['id']?.toString() ?? '';
            _categoryNameToId![name] = id;
          }
        }
      }
    } catch (_) {
      _categoryNameToId = {};
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      await _ensureCategories();
      final response = await _dio.get('/expenses');
      List<dynamic> items = [];
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is Map<String, dynamic> &&
            data['data']['items'] is List) {
          items = data['data']['items'] as List<dynamic>;
        } else if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        }
      }

      final fetched = items.whereType<Map<String, dynamic>>().map((json) {
        final dateStr = json['expense_date']?.toString();
        final date = dateStr != null
            ? (DateTime.tryParse(dateStr) ?? DateTime.now())
            : DateTime.now();
        final amount = (json['amount'] as num?)?.round() ?? 0;
        final categoryRelation = json['expense_categories'];
        final category = json['category_name']?.toString() ??
            (categoryRelation is Map
                ? categoryRelation['name']?.toString()
                : null) ??
            'أخرى';
        final receiptPath =
            json['receipt_url']?.toString() ?? json['receipt_path']?.toString();

        return Expense(
          id: json['id']?.toString() ?? '',
          title: json['description']?.toString() ?? 'مصروف',
          category: category,
          hallId: json['hall_id']?.toString() ?? 'all',
          hallName: json['hall_name']?.toString() ?? 'عام لجميع القاعات',
          amount: amount,
          date: date,
          receiptImagePath:
              receiptPath == null || receiptPath.isEmpty ? null : receiptPath,
          note: json['notes']?.toString(),
        );
      }).toList();

      return [...fetched, ..._localExpenses];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      await _ensureCategories();
      String? catId = _categoryNameToId?[expense.category];

      // If category not found, create it via POST /expense-categories
      if (catId == null &&
          expense.category.isNotEmpty &&
          expense.category != 'الكل') {
        try {
          final catRes = await _dio
              .post('/expense-categories', data: {'name': expense.category});
          if (catRes.data is Map<String, dynamic> &&
              catRes.data['data'] is Map<String, dynamic>) {
            catId = catRes.data['data']['id']?.toString();
            if (catId != null) _categoryNameToId![expense.category] = catId;
          }
        } catch (_) {}
      }

      final dateStr =
          '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';

      final fields = <String, dynamic>{
        if (catId != null) 'category_id': catId,
        'description': expense.title,
        'amount': expense.amount.toDouble(),
        'expense_date': dateStr,
        if (expense.hallId.isNotEmpty &&
            expense.hallId != 'all' &&
            expense.hallId.length > 10)
          'hall_id': expense.hallId,
        'notes': expense.note,
      };
      final path = expense.receiptImagePath;
      if (path == null || path.isEmpty) {
        await _dio.post('/expenses', data: fields);
      } else {
        fields['receipt'] = await MultipartFile.fromFile(path);
        await _dio.post(
          '/expenses',
          data: FormData.fromMap(fields),
          options: Options(contentType: Headers.multipartFormDataContentType),
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    // TODO(API): Update expense is not documented in API, maintained locally
    final idx = _localExpenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _localExpenses[idx] = expense;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    // TODO(API): Delete expense is not documented in API, maintained locally
    _localExpenses.removeWhere((e) => e.id == id);
  }
}

class MockExpensesRepository implements ExpensesRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<Expense> _expenses = [
    Expense(
      id: 'exp_1',
      title: 'فاتورة كهرباء شهر نوفمبر',
      category: 'كهرباء',
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      amount: 14500,
      date: DateTime(2026, 11, 15),
      note: 'سداد فوري لشركة الكهرباء',
    ),
    Expense(
      id: 'exp_2',
      title: 'صيانة تكييفات القاعة الكبرى',
      category: 'صيانة',
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      amount: 6800,
      date: DateTime(2026, 11, 10),
      note: 'تغيير فلاتر وشحن فريون',
    ),
    Expense(
      id: 'exp_3',
      title: 'أدوات نظافة ومعقمات شهرية',
      category: 'نظافة',
      hallId: 'all',
      hallName: 'عام لجميع القاعات',
      amount: 3200,
      date: DateTime(2026, 11, 8),
    ),
    Expense(
      id: 'exp_4',
      title: 'فاتورة مياه ربع سنوية',
      category: 'مياه',
      hallId: 'nakheel',
      hallName: 'قاعة النخيل',
      amount: 2900,
      date: DateTime(2026, 11, 5),
    ),
  ];

  @override
  Future<List<Expense>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_expenses);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _expenses.insert(0, expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _expenses.removeWhere((e) => e.id == id);
  }
}
