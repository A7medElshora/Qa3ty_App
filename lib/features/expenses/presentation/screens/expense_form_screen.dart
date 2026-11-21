import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import '../../data/models/expense_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'كهرباء';
  String _selectedHall = 'قاعة الماسة';
  String? _receiptImagePath;
  bool _isLoading = false;

  final List<String> _categories = [
    'كهرباء',
    'مياه',
    'صيانة',
    'نظافة',
    'بنزين',
    'مواصلات',
    'مستلزمات',
    'أخرى',
  ];

  final List<String> _halls = [
    'قاعة الماسة',
    'قاعة النخيل',
    'عام لجميع القاعات',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'تسجيل مصروف جديد',
                subtitle: 'أدخل تفاصيل المصروف وإرفاق صورة الفاتورة',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'بند المصروف',
                            hint: 'مثال: فاتورة كهرباء شهر نوفمبر',
                            controller: _titleController,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'المبلغ (ج.م)',
                            hint: 'مثال: ١٤٥٠٠',
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          const Text('التصنيف', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.white : AppColors.ink,
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedCategory = cat);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text('القاعة المعنية', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          DropdownButton<String>(
                            value: _selectedHall,
                            isExpanded: true,
                            items: _halls.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedHall = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'ملاحظات إضافية',
                            hint: 'سداد فوري لشركة الكهرباء...',
                            controller: _noteController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          // Image picker button
                          AppSecondaryButton(
                            text: _receiptImagePath != null ? 'تم إرفاق صورة الإيصال' : 'إرفاق صورة الفاتورة / الإيصال',
                            onPressed: _pickReceiptImage,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      text: 'حفظ المصروف',
                      isLoading: _isLoading,
                      onPressed: _saveExpense,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _receiptImagePath = picked.path);
    }
  }

  Future<void> _saveExpense() async {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المصروف ومبلغ صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _selectedCategory,
      hallId: _selectedHall == 'قاعة الماسة' ? 'masia' : (_selectedHall == 'قاعة النخيل' ? 'nakheel' : 'all'),
      hallName: _selectedHall,
      amount: amount,
      date: DateTime.now(),
      receiptImagePath: _receiptImagePath,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await ServicesLocator.expensesRepo.addExpense(expense);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل المصروف بنجاح')),
      );
    }
  }
}
