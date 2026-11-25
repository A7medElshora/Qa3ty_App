import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/workers/data/models/worker_model.dart';
import 'package:qa3ty_app/features/workers/presentation/screens/workers_screen.dart';

void main() {
  testWidgets('tapping an employee shows bonus and deduction history',
      (tester) async {
    final repository = _WorkerRepository();
    final locator = ServicesLocator.locator;
    await locator.reset();
    locator.registerSingleton<WorkersRepository>(repository);
    addTearDown(locator.reset);

    await tester.pumpWidget(
      const MaterialApp(home: WorkersScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('موظف الاختبار'));
    await tester.pumpAndSettle();

    expect(find.text('مكافأة'), findsOneWidget);
    expect(find.text('خصم'), findsOneWidget);
    expect(find.textContaining('أداء ممتاز'), findsOneWidget);
    expect(find.textContaining('غياب'), findsOneWidget);
  });
}

class _WorkerRepository extends MockWorkersRepository {
  static const _worker = Worker(
    id: 'worker-1',
    name: 'موظف الاختبار',
    role: 'مشرف',
    phone: '01000000000',
    wageType: WageType.monthly,
    wageRate: 5000,
    daysWorked: 20,
  );

  @override
  Future<List<Worker>> getWorkers() async => const [_worker];

  @override
  Future<List<WorkerTransaction>> getTransactions(String workerId) async => [
        WorkerTransaction(
          id: 'bonus-1',
          workerId: workerId,
          type: WorkerTransactionType.bonus,
          amount: 500,
          date: DateTime(2026, 11, 20),
          note: 'أداء ممتاز',
        ),
        WorkerTransaction(
          id: 'deduction-1',
          workerId: workerId,
          type: WorkerTransactionType.deduction,
          amount: 200,
          date: DateTime(2026, 11, 19),
          note: 'غياب',
        ),
      ];
}
