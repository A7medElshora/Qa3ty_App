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

  const Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.wageType,
    required this.wageRate,
    this.daysWorked = 0,
    this.currentBalance = 0,
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
    );
  }
}

abstract class WorkersRepository {
  Future<List<Worker>> getWorkers();
  Future<void> addWorker(Worker worker);
  Future<void> updateWorker(Worker worker);
  Future<void> recordTransaction(WorkerTransaction transaction);
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
      _workers[idx] = worker.copyWith(currentBalance: newBalance);
    }
  }
}
