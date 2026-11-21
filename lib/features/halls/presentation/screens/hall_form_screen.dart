import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../../data/models/hall_model.dart';

class HallFormScreen extends StatefulWidget {
  final String? editHallId;

  const HallFormScreen({super.key, this.editHallId});

  @override
  State<HallFormScreen> createState() => _HallFormScreenState();
}

class _HallFormScreenState extends State<HallFormScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _hoursController = TextEditingController(text: '٨:٠٠ م – ٢:٠٠ ص');
  int _slotsCount = 1;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editHallId != null) {
      _loadHallData();
    }
  }

  Future<void> _loadHallData() async {
    final hall = await ServicesLocator.hallsRepo.getHallById(widget.editHallId!);
    if (hall != null) {
      _nameController.text = hall.name;
      _locationController.text = hall.location;
      _capacityController.text = hall.capacity.toString();
      _hoursController.text = hall.workingHours;
      _slotsCount = hall.dailySlotsCount;
      _isActive = hall.isActive;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editHallId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 10),
              child: AppHeader(
                title: isEditing ? 'تعديل بيانات القاعة' : 'إضافة قاعة جديدة',
                subtitle: isEditing ? _nameController.text : 'أدخل تفاصيل ومواصفات القاعة',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: 'البيانات الأساسية',
                      child: Column(
                        children: [
                          AppTextField(
                            label: 'اسم القاعة',
                            hint: 'مثال: قاعة اللؤلؤة الملكية',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'الموقع الجغرافي / العنوان',
                            hint: 'مثال: طنطا، شارع الجيش',
                            controller: _locationController,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'السعة الاستيعابية (عدد المقاعد)',
                            hint: 'مثال: ٥٠٠',
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    SectionCard(
                      title: 'مواعيد العمل والفترات',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'ساعات العمل الرسمية',
                            hint: '٨:٠٠ م – ٢:٠٠ ص',
                            controller: _hoursController,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'عدد الفترات اليومية المتاحة للحجز',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [1, 2, 3].map((count) {
                              final isSelected = _slotsCount == count;
                              return Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ChoiceChip(
                                  label: Text('${count.toArabicDigits()} فترة'),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.white : AppColors.ink,
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (val) {
                                    if (val) setState(() => _slotsCount = count);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('حالة القاعة نشطة ومتاحة للحجز', style: AppTextStyles.body),
                            value: _isActive,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    AppPrimaryButton(
                      text: isEditing ? 'حفظ التعديلات' : 'إضافة القاعة',
                      isLoading: _isLoading,
                      onPressed: _saveHall,
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 10),
                      AppSecondaryButton(
                        text: 'حذف القاعة',
                        textColor: AppColors.red,
                        borderColor: AppColors.red,
                        onPressed: _deleteHall,
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHall() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

    if (name.isEmpty || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء كافة الحقول الأساسية وسعة صحيحة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final hallId = widget.editHallId ?? 'hall_${DateTime.now().millisecondsSinceEpoch}';
    final hall = Hall(
      id: hallId,
      name: name,
      location: location,
      capacity: capacity,
      workingHours: _hoursController.text.trim(),
      dailySlotsCount: _slotsCount,
      isActive: _isActive,
      weekBookingsCount: 0,
      weekRemainingAmount: 0,
      currentWeekSchedule: List.generate(7, (i) {
        return HallDaySchedule(
          dayNumber: 21 + i,
          dayName: AppFormatters.arabicWeekdays[i],
          status: DayStatus.available,
          isToday: i == 0,
        );
      }),
    );

    if (widget.editHallId != null) {
      await ServicesLocator.hallsRepo.updateHall(hall);
    } else {
      await ServicesLocator.hallsRepo.addHall(hall);
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editHallId != null ? 'تم تحديث القاعة بنجاح' : 'تمت إضافة القاعة بنجاح')),
      );
    }
  }

  Future<void> _deleteHall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(color: AppColors.red)),
        content: const Text('هل أنت متأكد من حذف هذه القاعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ServicesLocator.hallsRepo.deleteHall(widget.editHallId!);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف القاعة')),
        );
      }
    }
  }
}
