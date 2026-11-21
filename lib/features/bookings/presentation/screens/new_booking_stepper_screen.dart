import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/key_value_row.dart';
import '../../data/models/booking_model.dart';
import '../../../halls/data/models/hall_model.dart';

class NewBookingStepperScreen extends StatefulWidget {
  final String? initialHallId;
  final int? initialDay;

  const NewBookingStepperScreen({
    super.key,
    this.initialHallId,
    this.initialDay,
  });

  @override
  State<NewBookingStepperScreen> createState() => _NewBookingStepperScreenState();
}

class _NewBookingStepperScreenState extends State<NewBookingStepperScreen> {
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Step 1: Hall
  String _selectedHallId = 'masia';
  String _selectedHallName = 'قاعة الماسة';
  List<Hall> _halls = [];

  // Step 2: Date & Slot
  DateTime _selectedDate = DateTime(2026, 12, 15);
  String _selectedTimeSlot = '٨:٠٠ م – ١:٠٠ ص';

  // Step 3: Customer
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedEventType = 'حفل زفاف';
  final _seatsController = TextEditingController(text: '٤٥٠');

  // Step 4: Price & Deposit
  final _priceController = TextEditingController(text: '40000');
  final _depositController = TextEditingController(text: '15000');
  final String _paymentMethod = 'نقداً';

  // Step 5: Services
  final Map<String, bool> _selectedServices = {
    'زفة استعراضية': true,
    'دي جي وإضاءة': true,
    'دبكة لبنانية': false,
    'عروض ليزر شو': false,
    'مؤثرات الدخان الثقيل': false,
  };
  final Map<String, int> _servicePrices = {
    'زفة استعراضية': 3000,
    'دي جي وإضاءة': 5000,
    'دبكة لبنانية': 4000,
    'عروض ليزر شو': 2500,
    'مؤثرات الدخان الثقيل': 1500,
  };

  // Step 6: Notes
  final _eventNotesController = TextEditingController();
  final _setupNotesController = TextEditingController();
  final _internalNotesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHalls();
    if (widget.initialHallId != null) {
      _selectedHallId = widget.initialHallId!;
    }
    if (widget.initialDay != null) {
      _selectedDate = DateTime(2026, 12, widget.initialDay!);
    }
  }

  Future<void> _loadHalls() async {
    final halls = await ServicesLocator.hallsRepo.getHalls();
    setState(() {
      _halls = halls;
      if (_halls.isNotEmpty && widget.initialHallId == null) {
        _selectedHallId = _halls.first.id;
        _selectedHallName = _halls.first.name;
      }
    });
  }

  int get _hallPrice => int.tryParse(_priceController.text.trim()) ?? 0;
  int get _depositAmount => int.tryParse(_depositController.text.trim()) ?? 0;

  int get _servicesTotal {
    int sum = 0;
    _selectedServices.forEach((service, isSelected) {
      if (isSelected) sum += _servicePrices[service] ?? 0;
    });
    return sum;
  }

  int get _totalAmount => _hallPrice + _servicesTotal;
  int get _remainingAmount {
    final rem = _totalAmount - _depositAmount;
    return rem < 0 ? 0 : rem;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _eventNotesController.dispose();
    _setupNotesController.dispose();
    _internalNotesController.dispose();
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
            Padding(
              padding: const EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'حجز جديد',
                subtitle: 'خطوة ${(_currentStep + 1).toArabicDigits()} من ${_totalSteps.toArabicDigits()}: ${_getStepTitle(_currentStep)}',
              ),
            ),

            // Stepper progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: AppColors.topBarShadow,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: AppSecondaryButton(
                        text: 'السابق',
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      text: _currentStep == _totalSteps - 1 ? 'تأكيد وحفظ الحجز' : 'التالي والمتابعة',
                      isLoading: _isLoading,
                      onPressed: _onNextPressed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'اختيار القاعة';
      case 1:
        return 'التاريخ والفترة';
      case 2:
        return 'بيانات العميل والمناسبة';
      case 3:
        return 'السعر والعربون';
      case 4:
        return 'الخدمات الإضافية';
      case 5:
        return 'الملاحظات والتعليمات';
      case 6:
        return 'مراجعة وتأكيد';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0HallSelection();
      case 1:
        return _buildStep1DateSelection();
      case 2:
        return _buildStep2CustomerInfo();
      case 3:
        return _buildStep3PriceAndDeposit();
      case 4:
        return _buildStep4ServicesSelection();
      case 5:
        return _buildStep5Notes();
      case 6:
        return _buildStep6Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0HallSelection() {
    return SectionCard(
      title: 'اختر القاعة المناسبة',
      child: Column(
        children: _halls.map((hall) {
          final isSelected = _selectedHallId == hall.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.line,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: ListTile(
              title: Text(hall.name, style: AppTextStyles.cardTitle),
              subtitle: Text('${hall.location} · سعة ${hall.capacity.toArabicDigits()} مقعد', style: AppTextStyles.muted),
              leading: Icon(LucideIcons.building2, color: isSelected ? AppColors.primary : AppColors.muted),
              trailing: isSelected ? const Icon(LucideIcons.checkCircle2, color: AppColors.primary) : null,
              onTap: () {
                setState(() {
                  _selectedHallId = hall.id;
                  _selectedHallName = hall.name;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1DateSelection() {
    return SectionCard(
      title: 'تحديد الموعد والفترة الزمنية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyValueRow(
            label: 'التاريخ المحدد',
            value: AppFormatters.formatFullDate(_selectedDate),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            text: 'تغيير التاريخ من التقويم',
            height: 40,
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2026, 1, 1),
                lastDate: DateTime(2028, 12, 31),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 20),
          const Text('الفترة الزمنية', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['٨:٠٠ م – ١:٠٠ ص', '١:٠٠ ظ – ٥:٠٠ م', '٧:٠٠ م – ١٢:٠٠ ص'].map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.ink,
                  fontFamily: AppTextStyles.fontFamily,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedTimeSlot = slot);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2CustomerInfo() {
    return SectionCard(
      title: 'بيانات العميل والمناسبة',
      child: Column(
        children: [
          AppTextField(
            label: 'اسم العميل بالكامل',
            hint: 'مثال: محمد عبد الله',
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'رقم الهاتف / الواتساب',
            hint: '٠١٠١٢٣٤٥٦٧٨',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'عدد المقاعد / المدعوين',
            hint: '٤٥٠',
            controller: _seatsController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('نوع المناسبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.muted)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['حفل زفاف', 'حفل خطوبة', 'كتب كتاب', 'حفل تخرج', 'عيد ميلاد'].map((type) {
              final isSelected = _selectedEventType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.ink,
                  fontFamily: AppTextStyles.fontFamily,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedEventType = type);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3PriceAndDeposit() {
    return SectionCard(
      title: 'الاتفاق المالي والعربون',
      child: Column(
        children: [
          AppTextField(
            label: 'سعر إيجار القاعة الأساسي (ج.م)',
            controller: _priceController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'مبلغ العربون المدفوع حالياً (ج.م)',
            controller: _depositController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amberBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                KeyValueRow(label: 'إجمالي العقد الأساسي', value: AppFormatters.formatMoney(_hallPrice)),
                KeyValueRow(label: 'الخدمات الإضافية المختارة', value: AppFormatters.formatMoney(_servicesTotal)),
                const Divider(color: AppColors.line, height: 16),
                KeyValueRow(
                  label: 'المبلغ الإجمالي المستحق',
                  value: AppFormatters.formatMoney(_totalAmount),
                  valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                ),
                KeyValueRow(
                  label: 'المبلغ المتبقي تلقائياً',
                  value: AppFormatters.formatMoney(_remainingAmount),
                  valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.amberText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4ServicesSelection() {
    return SectionCard(
      title: 'الخدمات الإضافية والتجهيزات',
      child: Column(
        children: _selectedServices.keys.map((service) {
          final isSelected = _selectedServices[service]!;
          final price = _servicePrices[service]!;

          return CheckboxListTile(
            activeColor: AppColors.primary,
            title: Text(service, style: AppTextStyles.body),
            subtitle: Text(AppFormatters.formatMoney(price), style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                _selectedServices[service] = val ?? false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep5Notes() {
    return SectionCard(
      title: 'الملاحظات والتعليمات',
      child: Column(
        children: [
          AppTextField(
            label: 'ملاحظات الفعالية والعروسين',
            hint: 'مثال: كوشة ورد طبيعي وتوزيعات...',
            controller: _eventNotesController,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'تعليمات التجهيز والصالة',
            hint: 'مثال: فتح القاعة من الساعة ٤ عصراً...',
            controller: _setupNotesController,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'ملاحظات سرية للإدارة والموظفين',
            hint: 'مثال: خصم خاص، عميل VIP...',
            controller: _internalNotesController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Review() {
    return Column(
      children: [
        SectionCard(
          title: 'ملخص الحجز للمراجعة النهائية',
          child: Column(
            children: [
              KeyValueRow(label: 'القاعة', value: _selectedHallName),
              KeyValueRow(label: 'التاريخ', value: AppFormatters.formatFullDate(_selectedDate)),
              KeyValueRow(label: 'الفترة', value: _selectedTimeSlot),
              KeyValueRow(label: 'اسم العميل', value: _nameController.text),
              KeyValueRow(label: 'رقم الهاتف', value: _phoneController.text),
              KeyValueRow(label: 'المناسبة', value: _selectedEventType),
              KeyValueRow(label: 'عدد المقاعد', value: '${_seatsController.text} مقعد'),
              const Divider(color: AppColors.line, height: 16),
              KeyValueRow(label: 'سعر القاعة', value: AppFormatters.formatMoney(_hallPrice)),
              KeyValueRow(label: 'الخدمات الإضافية', value: AppFormatters.formatMoney(_servicesTotal)),
              KeyValueRow(label: 'إجمالي العقد', value: AppFormatters.formatMoney(_totalAmount), valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              KeyValueRow(label: 'العربون المسدد', value: AppFormatters.formatMoney(_depositAmount), valueStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
              KeyValueRow(label: 'المتبقي', value: AppFormatters.formatMoney(_remainingAmount), valueStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.amberText)),
            ],
          ),
        ),
      ],
    );
  }

  void _onNextPressed() async {
    if (_currentStep == 2) {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال اسم العميل ورقم الهاتف')),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Final confirmation & save
      setState(() => _isLoading = true);
      final bookingId = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;

      final servicesList = _selectedServices.entries.map((e) {
        return ServiceItem(
          id: 'serv_${e.key}',
          name: e.key,
          price: _servicePrices[e.key] ?? 0,
          status: e.value ? BookingServiceStatus.booked : BookingServiceStatus.optional,
        );
      }).toList();

      final booking = Booking(
        id: bookingId,
        hallId: _selectedHallId,
        hallName: _selectedHallName,
        customerId: 'cust_${DateTime.now().millisecondsSinceEpoch}',
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        eventType: _selectedEventType,
        eventDate: _selectedDate,
        timeRange: _selectedTimeSlot,
        seatsCount: int.tryParse(_seatsController.text.trim()) ?? 400,
        hallPrice: _hallPrice,
        services: servicesList,
        payments: [
          if (_depositAmount > 0)
            LedgerEntry(
              id: 'dep_$bookingId',
              bookingId: bookingId.toString(),
              type: 'deposit',
              amount: _depositAmount,
              date: DateTime.now(),
              paymentMethod: _paymentMethod,
              receiverName: 'أحمد',
              note: 'عربون الحجز الأولي',
            ),
        ],
        eventNotes: _eventNotesController.text.trim().isEmpty ? null : _eventNotesController.text.trim(),
        setupNotes: _setupNotesController.text.trim().isEmpty ? null : _setupNotesController.text.trim(),
        internalNotes: _internalNotesController.text.trim().isEmpty ? null : _internalNotesController.text.trim(),
        activityLog: [
          'تم إنشاء الحجز رقم #$bookingId وتأكيده بنجاح',
          if (_depositAmount > 0) 'تم تحصيل عربون بقيمة $_depositAmount ج.م',
        ],
      );

      await ServicesLocator.bookingsRepo.addBooking(booking);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء الحجز رقم #${bookingId.toArabicDigits()} بنجاح')),
        );
      }
    }
  }
}
