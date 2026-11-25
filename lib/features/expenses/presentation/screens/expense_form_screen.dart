import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import 'package:qa3ty_app/features/halls/data/models/hall_model.dart';
import '../../data/models/expense_model.dart';
import '../widgets/expense_receipt_preview.dart';

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
  String? _selectedHallId;
  List<Hall> _halls = [];
  bool _isLoadingHalls = true;
  String? _hallsError;
  String? _receiptImagePath;
  bool _isLoading = false;
  String? _saveError;

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

  @override
  void initState() {
    super.initState();
    _loadHalls();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadHalls() async {
    setState(() {
      _isLoadingHalls = true;
      _hallsError = null;
    });

    try {
      final halls = await ServicesLocator.hallsRepo.getHalls();
      if (!mounted) return;

      setState(() {
        _halls = halls;
        _selectedHallId = halls.any((hall) => hall.id == _selectedHallId)
            ? _selectedHallId
            : halls.isEmpty
                ? 'all'
                : halls.first.id;
        _isLoadingHalls = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hallsError = error.toString();
        _isLoadingHalls = false;
      });
    }
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
                          const Text('التصنيف',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
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
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.ink,
                                  fontFamily: AppTextStyles.fontFamily,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedCategory = cat);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isLoadingHalls || _hallsError != null
                                ? 'القاعة المعنية'
                                : 'القاعة المعنية (${_halls.length.toArabicDigits()})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          if (_isLoadingHalls)
                            AppSkeletonizer(
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.line),
                                ),
                              ),
                            )
                          else if (_hallsError != null)
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'تعذر تحميل القاعات',
                                    style: TextStyle(color: AppColors.red),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loadHalls,
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            )
                          else
                            DropdownButton<String>(
                              value: _selectedHallId,
                              isExpanded: true,
                              items: [
                                ..._halls.map(
                                  (hall) => DropdownMenuItem(
                                    value: hall.id,
                                    child: Text(hall.name),
                                  ),
                                ),
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('عام لجميع القاعات'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedHallId = value);
                                }
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
                            text: _receiptImagePath != null
                                ? 'تم إرفاق صورة الإيصال'
                                : 'إرفاق صورة الفاتورة / الإيصال',
                            onPressed: _pickReceiptImage,
                          ),
                          if (_receiptImagePath != null) ...[
                            const SizedBox(height: 12),
                            ExpenseReceiptPreview(path: _receiptImagePath!),
                          ],
                          if (_saveError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _saveError!,
                              style: const TextStyle(color: AppColors.red),
                            ),
                          ],
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
    if (picked != null && mounted) {
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

    if (_isLoadingHalls || _hallsError != null || _selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحميل القاعات قبل حفظ المصروف')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _saveError = null;
    });
    final selectedHalls = _halls.where((hall) => hall.id == _selectedHallId);
    final selectedHall = _selectedHallId == 'all' || selectedHalls.isEmpty
        ? null
        : selectedHalls.first;
    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _selectedCategory,
      hallId: selectedHall?.id ?? 'all',
      hallName: selectedHall?.name ?? 'عام لجميع القاعات',
      amount: amount,
      date: DateTime.now(),
      receiptImagePath: _receiptImagePath,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await ServicesLocator.expensesRepo.addExpense(expense);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل المصروف بنجاح')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _saveError = error.toString();
        });
      }
    }
  }
}
