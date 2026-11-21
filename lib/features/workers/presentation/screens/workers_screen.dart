import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_sheet.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import '../../data/models/worker_model.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  List<Worker> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    setState(() => _isLoading = true);
    final list = await ServicesLocator.workersRepo.getWorkers();
    setState(() {
      _workers = list;
      _isLoading = false;
    });
  }

  int get _totalBalances => _workers.fold(0, (sum, w) => sum + w.currentBalance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'إدارة شؤون العمال والموظفين',
                subtitle: 'المستحقات المتبقية: ${AppFormatters.formatMoney(_totalBalances)}',
                actions: [
                  CircleIconButton.primary(
                    icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.white),
                    onTap: _showAddWorkerSheet,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchWorkers,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                        itemCount: _workers.length,
                        itemBuilder: (context, i) {
                          final worker = _workers[i];
                          return _buildWorkerCard(worker);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    final isDaily = worker.wageType == WageType.daily;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text('${worker.role} · ${worker.phone}', style: AppTextStyles.muted),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isDaily ? 'أجر يومي: ${AppFormatters.formatMoney(worker.wageRate)}' : 'راتب شهري: ${AppFormatters.formatMoney(worker.wageRate)}',
                  style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.line, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أيام الحضور: ${worker.daysWorked.toArabicDigits()} يوم', style: AppTextStyles.body),
              Text(
                'المستحق: ${AppFormatters.formatMoney(worker.currentBalance)}',
                style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.amberText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  text: 'صرف دفعة',
                  height: 36,
                  onPressed: () => _showPayoutDialog(worker),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSecondaryButton(
                  text: 'مكافأة / خصم',
                  height: 36,
                  onPressed: () => _showBonusDeductionDialog(worker),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddWorkerSheet() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'مشرف صالة');
    final phoneCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    WageType wageType = WageType.daily;

    AppBottomSheet.show(
      context: context,
      title: 'إضافة عامل / موظف جديد',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            AppTextField(label: 'اسم العامل', controller: nameCtrl),
            const SizedBox(height: 10),
            AppTextField(label: 'المسمى الوظيفي / الدور', controller: roleCtrl),
            const SizedBox(height: 10),
            AppTextField(label: 'رقم الهاتف', controller: phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('يومي'),
                  selected: wageType == WageType.daily,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: wageType == WageType.daily ? Colors.white : AppColors.ink),
                  onSelected: (val) => setSheetState(() => wageType = WageType.daily),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('شهري'),
                  selected: wageType == WageType.monthly,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: wageType == WageType.monthly ? Colors.white : AppColors.ink),
                  onSelected: (val) => setSheetState(() => wageType = WageType.monthly),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppTextField(label: 'معدل الأجر (ج.م)', controller: rateCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'حفظ العامل',
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && rateCtrl.text.isNotEmpty) {
                  final newWorker = Worker(
                    id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    role: roleCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    wageType: wageType,
                    wageRate: int.tryParse(rateCtrl.text.trim()) ?? 0,
                    daysWorked: 1,
                    currentBalance: int.tryParse(rateCtrl.text.trim()) ?? 0,
                  );
                  await ServicesLocator.workersRepo.addWorker(newWorker);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  _fetchWorkers();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutDialog(Worker worker) {
    final amountCtrl = TextEditingController(text: worker.currentBalance.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('صرف مستحقات: ${worker.name}', style: AppTextStyles.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'المبلغ المسدد (ج.م)', controller: amountCtrl, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amt > 0) {
                await ServicesLocator.workersRepo.recordTransaction(
                  WorkerTransaction(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    workerId: worker.id,
                    type: WorkerTransactionType.payment,
                    amount: amt,
                    date: DateTime.now(),
                  ),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                _fetchWorkers();
              }
            },
            child: const Text('تأكيد الصرف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBonusDeductionDialog(Worker worker) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    WorkerTransactionType type = WorkerTransactionType.bonus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('مكافأة أو خصم: ${worker.name}', style: AppTextStyles.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('مكافأة (+)'),
                    selected: type == WorkerTransactionType.bonus,
                    selectedColor: AppColors.green,
                    labelStyle: TextStyle(color: type == WorkerTransactionType.bonus ? Colors.white : AppColors.ink),
                    onSelected: (val) => setDlgState(() => type = WorkerTransactionType.bonus),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('خصم (-)'),
                    selected: type == WorkerTransactionType.deduction,
                    selectedColor: AppColors.red,
                    labelStyle: TextStyle(color: type == WorkerTransactionType.deduction ? Colors.white : AppColors.ink),
                    onSelected: (val) => setDlgState(() => type = WorkerTransactionType.deduction),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(label: 'المبلغ (ج.م)', controller: amountCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AppTextField(label: 'السبب / الملاحظة', controller: noteCtrl),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt > 0) {
                  await ServicesLocator.workersRepo.recordTransaction(
                    WorkerTransaction(
                      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                      workerId: worker.id,
                      type: type,
                      amount: amt,
                      date: DateTime.now(),
                      note: noteCtrl.text.trim(),
                    ),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  _fetchWorkers();
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
