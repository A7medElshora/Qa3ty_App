import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';

enum WageType {
  daily, // يومي
  monthly, // شهري
}

enum WorkerTransactionType {
  payment, // دفعة مسددة
  bonus, // مكافأة
  deduction, // خصم
}

class WorkerTransaction {
  final String id;
  final String workerId;
  final WorkerTransactionType type;
  final int amount;
  final DateTime date;
  final String? note;

  const WorkerTransaction({
    required this.id,
    required this.workerId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  });
}

class Worker {
  final String id;
  final String name;
  final String role; // مشرف، أمن، نظافة، فني إضاءة
  final String phone;
  final WageType wageType;
  final int wageRate; // يومية أو راتب شهري
  final int daysWorked;
  final int currentBalance; // مستحقات متبقية
  final int totalPaid;

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.wageType,
    required this.wageRate,
    this.daysWorked = 0,
    this.currentBalance = 0,
    this.totalPaid = 0,
  });

  Worker copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    WageType? wageType,
    int? wageRate,
    int? daysWorked,
    int? currentBalance,
    int? totalPaid,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      wageType: wageType ?? this.wageType,
      wageRate: wageRate ?? this.wageRate,
      daysWorked: daysWorked ?? this.daysWorked,
      currentBalance: currentBalance ?? this.currentBalance,
      totalPaid: totalPaid ?? this.totalPaid,
    );
  }
}

abstract class WorkersRepository {
  Future<List<Worker>> getWorkers();
  Future<List<WorkerTransaction>> getTransactions(String workerId);
  Future<void> addWorker(Worker worker);
  Future<void> updateWorker(Worker worker);
  Future<void> recordTransaction(WorkerTransaction transaction);
}

class RemoteWorkersRepository implements WorkersRepository {
  final Dio _dio;

  RemoteWorkersRepository([Dio? dio]) : _dio = dio ?? DioFactory.getDio();

  List<Map<String, dynamic>> _extractItems(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['payments'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().toList();
        }
      } else if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    } else if (responseData is List) {
      return responseData.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<WorkerTransaction>> _getWorkerTransactions(
      String workerId) async {
    final response = await _dio.get('/workers/$workerId/payments');
    final items = _extractItems(response.data);
    return items.map((item) {
      final type = switch (item['payment_type']?.toString()) {
        'salary' => WorkerTransactionType.payment,
        'bonus' => WorkerTransactionType.bonus,
        'deduction' => WorkerTransactionType.deduction,
        final unknown => throw FormatException(
            'Unsupported worker payment type: $unknown',
          ),
      };
      final dateString =
          item['payment_date']?.toString() ?? item['created_at']?.toString();
      final date = DateTime.tryParse(dateString ?? '');
      if (date == null) {
        throw const FormatException(
            'Worker payment has an invalid payment date.');
      }

      return WorkerTransaction(
        id: item['id']?.toString() ?? '',
        workerId: item['worker_id']?.toString() ?? workerId,
        type: type,
        amount: (item['amount'] as num?)?.round() ??
            (throw const FormatException(
                'Worker payment is missing its amount.')),
        date: date,
        note: (item['notes'] ?? item['note'])?.toString(),
      );
    }).toList();
  }

  @override
  Future<List<WorkerTransaction>> getTransactions(String workerId) async {
    try {
      final transactions = await _getWorkerTransactions(workerId);
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  int _currentBalance({
    required Map<String, dynamic> item,
    required WageType wageType,
    required int wageRate,
    required int daysWorked,
    required List<WorkerTransaction> transactions,
  }) {
    final now = DateTime.now();
    final thisMonthTransactions = transactions.where((transaction) =>
        transaction.date.year == now.year &&
        transaction.date.month == now.month);
    final currentMonthTransactions = thisMonthTransactions.toList();
    final reportedBalance = item['current_balance'];
    if (reportedBalance is num && currentMonthTransactions.isEmpty) {
      return reportedBalance.round();
    }

    var balance =
        wageType == WageType.monthly ? wageRate : wageRate * daysWorked;
    for (final transaction in currentMonthTransactions) {
      switch (transaction.type) {
        case WorkerTransactionType.payment:
        case WorkerTransactionType.deduction:
          balance -= transaction.amount;
        case WorkerTransactionType.bonus:
          balance += transaction.amount;
      }
    }
    return balance > 0 ? balance : 0;
  }

  @override
  Future<List<Worker>> getWorkers() async {
    try {
      final response =
          await _dio.get('/workers', queryParameters: {'status': 'active'});
      final rawItems = _extractItems(response.data);
      return Future.wait(rawItems.map((item) async {
        final salaryType =
            item['salary_type']?.toString().toLowerCase() ?? 'monthly';
        final wageType =
            salaryType == 'daily' ? WageType.daily : WageType.monthly;
        final wageRate = (wageType == WageType.daily
                ? (item['daily_rate'] ?? 0)
                : (item['fixed_salary'] ?? 0) as num)
            .round();
        final workerId = item['id']?.toString() ?? '';
        final daysWorked = (item['days_worked'] as num?)?.toInt() ?? 0;
        final transactions = await _getWorkerTransactions(workerId);
        return Worker(
          id: workerId,
          name: item['full_name']?.toString() ?? '',
          role: item['job_title']?.toString() ?? '',
          phone: item['phone']?.toString() ?? '',
          wageType: wageType,
          wageRate: wageRate,
          daysWorked: daysWorked,
          currentBalance: _currentBalance(
            item: item,
            wageType: wageType,
            wageRate: wageRate,
            daysWorked: daysWorked,
            transactions: transactions,
          ),
          totalPaid: transactions
              .where((transaction) =>
                  transaction.type == WorkerTransactionType.payment)
              .fold(0, (total, transaction) => total + transaction.amount),
        );
      }));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> addWorker(Worker worker) async {
    try {
      await _dio.post(
        '/workers',
        data: {
          'full_name': worker.name,
          'phone': worker.phone,
          'job_title': worker.role,
          'salary_type': worker.wageType == WageType.daily ? 'daily' : 'fixed',
          if (worker.wageType == WageType.daily)
            'daily_rate': worker.wageRate.toDouble(),
          if (worker.wageType == WageType.monthly)
            'fixed_salary': worker.wageRate.toDouble(),
          'joining_date': DateTime.now().toIso8601String().substring(0, 10),
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateWorker(Worker worker) async {
    try {
      await _dio.put(
        '/workers/${worker.id}',
        data: {
          'full_name': worker.name,
          'phone': worker.phone,
          'job_title': worker.role,
          'salary_type': worker.wageType == WageType.daily ? 'daily' : 'fixed',
          if (worker.wageType == WageType.daily)
            'daily_rate': worker.wageRate.toDouble(),
          if (worker.wageType == WageType.monthly)
            'fixed_salary': worker.wageRate.toDouble(),
        },
      );
    } on DioException catch (_) {
      // Backend does not expose PUT /workers/:id yet per Section 8.12
    }
  }

  @override
  Future<void> recordTransaction(WorkerTransaction transaction) async {
    try {
      final pType = transaction.type == WorkerTransactionType.payment
          ? 'salary'
          : (transaction.type == WorkerTransactionType.bonus
              ? 'bonus'
              : 'deduction');
      await _dio.post(
        '/workers/${transaction.workerId}/payments',
        data: {
          'amount': transaction.amount.toDouble(),
          'payment_type': pType,
          'payment_date': transaction.date.toIso8601String().substring(0, 10),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            'notes': transaction.note,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

class MockWorkersRepository implements WorkersRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<Worker> _workers = [
    const Worker(
      id: 'w_1',
      name: 'محمود عبد السلام',
      role: 'مشرف صالة واستقبال',
      phone: '٠١١١٢٣٤٥٦٧٨',
      wageType: WageType.monthly,
      wageRate: 7500,
      daysWorked: 22,
      currentBalance: 3500,
    ),
    const Worker(
      id: 'w_2',
      name: 'إبراهيم حسن',
      role: 'فني إضاءة وصوت',
      phone: '٠١٠٩٨٧٦٥٤٣٢',
      wageType: WageType.daily,
      wageRate: 350,
      daysWorked: 14,
      currentBalance: 1400,
    ),
    const Worker(
      id: 'w_3',
      name: 'ياسر كمال',
      role: 'مسؤول أمن وبوابات',
      phone: '٠١٢٢٣٣٤٤٥٥٦',
      wageType: WageType.daily,
      wageRate: 250,
      daysWorked: 18,
      currentBalance: 750,
    ),
  ];

  final List<WorkerTransaction> _transactions = [];

  @override
  Future<List<Worker>> getWorkers() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_workers);
  }

  @override
  Future<List<WorkerTransaction>> getTransactions(String workerId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _transactions
        .where((transaction) => transaction.workerId == workerId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addWorker(Worker worker) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _workers.add(worker);
  }

  @override
  Future<void> updateWorker(Worker worker) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final idx = _workers.indexWhere((w) => w.id == worker.id);
    if (idx != -1) _workers[idx] = worker;
  }

  @override
  Future<void> recordTransaction(WorkerTransaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _transactions.insert(0, transaction);
    final idx = _workers.indexWhere((w) => w.id == transaction.workerId);
    if (idx != -1) {
      final worker = _workers[idx];
      int newBalance = worker.currentBalance;
      if (transaction.type == WorkerTransactionType.payment) {
        newBalance -= transaction.amount;
      } else if (transaction.type == WorkerTransactionType.bonus) {
        newBalance += transaction.amount;
      } else if (transaction.type == WorkerTransactionType.deduction) {
        newBalance -= transaction.amount;
      }
      _workers[idx] = worker.copyWith(
        currentBalance: newBalance,
        totalPaid: transaction.type == WorkerTransactionType.payment
            ? worker.totalPaid + transaction.amount
            : worker.totalPaid,
      );
    }
  }
}
