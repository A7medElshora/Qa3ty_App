import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/models/expense_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String _selectedCategory = 'الكل';

  final List<String> _categories = [
    'الكل',
    'كهرباء',
    'مياه',
    'صيانة',
    'نظافة',
    'بنزين',
    'مواصلات',
    'مستلزمات',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final data = await ServicesLocator.expensesRepo.getExpenses();
    setState(() {
      _expenses = data;
      _isLoading = false;
    });
  }

  int get _totalExpensesAmount =>
      _filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  List<Expense> get _filteredExpenses {
    if (_selectedCategory == 'الكل') return _expenses;
    return _expenses.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'المصروفات والتكاليف',
                subtitle:
                    'إجمالي: ${AppFormatters.formatMoney(_totalExpensesAmount)}',
                actions: [
                  if (PermissionGuard.canManageExpenses)
                    CircleIconButton.primary(
                      icon: const Icon(LucideIcons.plus,
                          size: 20, color: AppColors.white),
                      onTap: () async {
                        await context.push('/expenses/form');
                        _fetchExpenses();
                      },
                    ),
                ],
              ),
            ),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: AppChip(
                      label: cat,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expenses list
            Expanded(
              child: _isLoading
                  ? const AppListSkeleton(itemCount: 4)
                  : _filteredExpenses.isEmpty
                      ? const EmptyState(
                          title: 'لا توجد مصروفات مسجلة',
                          subtitle: 'اضغط على زر الإضافة لتسجيل مصروف جديد.',
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchExpenses,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 80, top: 8),
                            itemCount: _filteredExpenses.length,
                            itemBuilder: (context, i) {
                              final exp = _filteredExpenses[i];
                              return _buildExpenseCard(context, exp);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(exp.title, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${exp.hallName} · ${AppFormatters.formatDayMonth(exp.date)}',
              style: AppTextStyles.muted,
            ),
            if (exp.note != null) ...[
              const SizedBox(height: 2),
              Text(exp.note!,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ],
        ),
        trailing: Text(
          AppFormatters.formatMoney(exp.amount),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}
