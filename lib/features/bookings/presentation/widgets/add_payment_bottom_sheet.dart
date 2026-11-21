import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_sheet.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';

class AddPaymentBottomSheet extends StatefulWidget {
  final int bookingId;
  final int remainingAmount;
  final VoidCallback onPaymentSuccess;

  const AddPaymentBottomSheet({
    super.key,
    required this.bookingId,
    required this.remainingAmount,
    required this.onPaymentSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required int bookingId,
    required int remainingAmount,
    required VoidCallback onPaymentSuccess,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'تسجيل دفعة جديدة',
      child: AddPaymentBottomSheet(
        bookingId: bookingId,
        remainingAmount: remainingAmount,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<AddPaymentBottomSheet> createState() => _AddPaymentBottomSheetState();
}

class _AddPaymentBottomSheetState extends State<AddPaymentBottomSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMethod = 'نقداً';
  final String _receiverName = 'أحمد';
  bool _isSubmitting = false;

  final List<String> _methods = [
    'نقداً',
    'تحويل إنستاباي',
    'تحويل بنكي',
    'محفظة إلكترونية',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Notice of remaining amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.amberBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المبلغ المتبقي الحالي:',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              Text(
                AppFormatters.formatMoney(widget.remainingAmount),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberText,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Amount field
        AppTextField(
          label: 'المبلغ المدفوع (ج.م)',
          controller: _amountController,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 12),

        // Payment method dropdown/selector
        const Text(
          'طريقة الدفع',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _methods.map((method) {
            final isSelected = _selectedMethod == method;
            return ChoiceChip(
              label: Text(
                method,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.line,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedMethod = method);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Notes
        AppTextField(
          label: 'ملاحظة على الدفعة (اختياري)',
          hint: 'مثال: تم إيداع المبلغ بحساب البنك الأهلي',
          controller: _noteController,
          maxLines: 2,
        ),

        const SizedBox(height: 18),

        // Confirm button
        AppPrimaryButton(
          text: 'تأكيد تسجيل الدفعة',
          isLoading: _isSubmitting,
          onPressed: _submitPayment,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _submitPayment() async {
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ServicesLocator.bookingsRepo.addPayment(
        bookingId: widget.bookingId,
        amount: amount,
        paymentMethod: _selectedMethod,
        receiverName: _receiverName,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      widget.onPaymentSuccess();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الدفعة بنجاح وتحصيل المبلغ')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }
}
