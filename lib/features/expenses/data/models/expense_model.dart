class Expense {
  final String id;
  final String title;
  final String category; // كهرباء, مياه, صيانة, بنزين, مواصلات, نظافة, مستلزمات, أخرى
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
