import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/status_banner.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/key_value_row.dart';
import 'package:qa3ty_app/core/utils/widgets/app_progress_bar.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_sheet.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../cubits/booking_details_cubit.dart';
import '../widgets/add_payment_bottom_sheet.dart';
import '../../data/models/booking_model.dart';

class BookingDetailsScreen extends StatelessWidget {
  final int bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingDetailsCubit(ServicesLocator.bookingsRepo)
        ..loadBooking(bookingId),
      child: BookingDetailsView(bookingId: bookingId),
    );
  }
}

class BookingDetailsView extends StatelessWidget {
  final int bookingId;

  const BookingDetailsView({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
          builder: (context, state) {
            if (state is BookingDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BookingDetailsError) {
              return ErrorState(
                message: state.message,
                onRetry: () =>
                    context.read<BookingDetailsCubit>().loadBooking(bookingId),
              );
            }
            if (state is! BookingDetailsLoaded) {
              return const SizedBox.shrink();
            }

            final booking = state.booking;

            return Column(
              children: [
                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 52,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1) Header: Back button + Title/Booking Number right, ⋮ button left
                        _buildHeader(context, booking),

                        const SizedBox(height: 14),

                        // 2) StatusBanner
                        _buildStatusBanner(booking),

                        const SizedBox(height: 14),

                        // 3) Event Card (الفعالية)
                        _buildEventCard(booking),

                        const SizedBox(height: 14),

                        // 4) Customer Card (العميل)
                        _buildCustomerCard(context, booking),

                        const SizedBox(height: 14),

                        // 5) Financials Card (الماليات)
                        _buildFinancialsCard(context, booking),

                        const SizedBox(height: 14),

                        // 6) Services & Program Card (البرنامج والخدمات)
                        _buildServicesCard(context, booking),

                        const SizedBox(height: 14),

                        // 7) Notes Card (الملاحظات)
                        _buildNotesCard(booking),

                        const SizedBox(height: 14),

                        // 8) Activity Log Row (سجل النشاط)
                        _buildActivityLogRow(context, booking),
                      ],
                    ),
                  ),
                ),

                // 9) Fixed Bottom Buttons Bar
                _buildFixedBottomBar(context, booking),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Booking booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleIconButton.white(
                icon: const Icon(
                  LucideIcons.arrowRight,
                  size: 20,
                  color: AppColors.ink,
                ),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/calendar');
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تفاصيل الحجز',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'حجز رقم #${booking.id.toArabicDigits()}',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 3 Dots popup menu
        PopupMenuButton<String>(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(26, 26, 51, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.moreVertical,
              size: 20,
              color: AppColors.ink,
            ),
          ),
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (action) => _handleMenuAction(context, action, booking),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(LucideIcons.edit3, size: 18, color: AppColors.ink),
                  SizedBox(width: 10),
                  Text('تعديل الحجز', style: AppTextStyles.body),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reschedule',
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 18, color: AppColors.ink),
                  SizedBox(width: 10),
                  Text('تغيير الموعد', style: AppTextStyles.body),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(LucideIcons.share2, size: 18, color: AppColors.ink),
                  SizedBox(width: 10),
                  Text('مشاركة الإيصال', style: AppTextStyles.body),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 18, color: AppColors.red),
                  SizedBox(width: 10),
                  Text('إلغاء الحجز', style: TextStyle(color: AppColors.red, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBanner(Booking booking) {
    if (booking.remainingAmount == 0) {
      return StatusBanner.paid(
        title: 'مدفوع بالكامل',
        subtitle: 'تم سداد كافة المستحقات المالية بنجاح',
      );
    }

    return StatusBanner.deposit(
      title: 'عربون مدفوع · متبقي ${AppFormatters.formatMoney(booking.remainingAmount)}',
      subtitle: 'الفعالية بعد ٢٤ يوماً · موعد سداد المتبقي ٥ ديسمبر',
    );
  }

  Widget _buildEventCard(Booking booking) {
    return SectionCard(
      title: 'الفعالية',
      child: Column(
        children: [
          KeyValueRow(
            label: 'نوع الفعالية',
            value: booking.eventType,
            hasDivider: true,
          ),
          KeyValueRow(
            label: 'التاريخ',
            value: AppFormatters.formatFullDate(booking.eventDate),
            hasDivider: true,
          ),
          KeyValueRow(
            label: 'الوقت',
            value: booking.timeRange,
            hasDivider: true,
          ),
          KeyValueRow(
            label: 'القاعة',
            value: booking.hallName,
            hasDivider: true,
          ),
          KeyValueRow(
            label: 'عدد الكراسي',
            value: '${booking.seatsCount.toArabicDigits()} مقعد',
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Booking booking) {
    return SectionCard(
      title: 'العميل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name, Phone & Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.customerPhone,
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons: Phone & WhatsApp
              Row(
                children: [
                  _buildSmallActionButton(
                    icon: LucideIcons.phone,
                    label: 'اتصال',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الاتصال بالرقم ${booking.customerPhone}')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildSmallActionButton(
                    icon: LucideIcons.messageSquare,
                    label: 'واتساب',
                    isBold: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فتح محادثة واتساب مع ${booking.customerName}')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Purple alert if customer has duplicate booking on same day
          if (booking.otherBookingNotice != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                if (booking.otherBookingId != null) {
                  context.push('/bookings/${booking.otherBookingId}');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.otherBookingNotice!,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.arrowLeft,
                      size: 16,
                      color: AppColors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    bool isBold = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(BuildContext context, Booking booking) {
    return SectionCard(
      title: 'الماليات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyValueRow(
            label: 'سعر القاعة',
            value: AppFormatters.formatMoney(booking.hallPrice),
          ),
          KeyValueRow(
            label: 'خدمات إضافية',
            value: AppFormatters.formatMoney(booking.bookedServicesTotal),
          ),
          const Divider(color: AppColors.line, height: 16, thickness: 1),
          KeyValueRow(
            label: 'الإجمالي',
            value: AppFormatters.formatMoney(booking.totalAmount),
            valueStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          KeyValueRow(
            label: 'المدفوع',
            value: AppFormatters.formatMoney(booking.paidAmount),
            valueStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 6),
          // Green progress bar
          AppProgressBar(
            progress: booking.paymentProgress,
            height: 10,
            fillColor: AppColors.green,
          ),
          const SizedBox(height: 6),
          KeyValueRow(
            label: 'المتبقي',
            value: AppFormatters.formatMoney(booking.remainingAmount),
            valueStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.amberText,
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'سجل الدفعات (${booking.payments.length.toArabicDigits()})',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),

          // Payment records list
          ...booking.payments.map((payment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${payment.type == "deposit" ? "العربون" : "دفعة"} · ${payment.date.day.toArabicDigits()} ${AppFormatters.arabicMonths[payment.date.month - 1]}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${payment.paymentMethod} · ${payment.receiverName}',
                          style: AppTextStyles.muted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatMoney(payment.amount),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          // Add payment button
          AppPrimaryButton(
            text: 'تسجيل دفعة جديدة',
            icon: const Icon(LucideIcons.plus, size: 18, color: AppColors.white),
            onPressed: () {
              AddPaymentBottomSheet.show(
                context: context,
                bookingId: booking.id,
                remainingAmount: booking.remainingAmount,
                onPaymentSuccess: () {
                  context.read<BookingDetailsCubit>().loadBooking(booking.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(BuildContext context, Booking booking) {
    return SectionCard(
      title: 'البرنامج والخدمات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...booking.services.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            final isLast = index == booking.services.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppFormatters.formatMoney(service.price)}${service.note != null ? " · ${service.note}" : ""}',
                              style: AppTextStyles.muted,
                            ),
                          ],
                        ),
                      ),
                      StatusChip.fromStatus(
                        service.status,
                        onTap: () => _showServiceOptionsSheet(context, booking, service),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(color: AppColors.line, height: 1, thickness: 1),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Add custom service dashed button
          AppDashedButton(
            text: 'إضافة خدمة مخصصة',
            icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
            onPressed: () => _showAddCustomServiceDialog(context, booking),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Booking booking) {
    return SectionCard(
      title: 'الملاحظات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box 1: Event notes
          _buildNoteBox(
            title: 'ملاحظات الفعالية',
            content: booking.eventNotes ?? 'لا توجد ملاحظات خاصة بالفعالية.',
            backgroundColor: AppColors.background,
          ),
          const SizedBox(height: 10),

          // Box 2: Setup notes
          _buildNoteBox(
            title: 'تعليمات التجهيز',
            content: booking.setupNotes ?? 'تجهيز الكوشة والإضاءة المبرمجة.',
            backgroundColor: AppColors.background,
          ),
          const SizedBox(height: 10),

          // Box 3: Internal notes (purple box with lock icon)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.lock, size: 14, color: AppColors.purple),
                    SizedBox(width: 6),
                    Text(
                      'ملاحظات داخلية للموظفين',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking.internalNotes ?? 'ملاحظة داخلية سرية خاصة بإدارة القاعة.',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox({
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogRow(BuildContext context, Booking booking) {
    return InkWell(
      onTap: () => _showActivityLogSheet(context, booking),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'سجل النشاط · ${booking.activityLog.length.toArabicDigits()} عمليات',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const Icon(
              LucideIcons.arrowLeft,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedBottomBar(BuildContext context, Booking booking) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: AppColors.topBarShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              text: 'إضافة دفعة',
              onPressed: () {
                AddPaymentBottomSheet.show(
                  context: context,
                  bookingId: booking.id,
                  remainingAmount: booking.remainingAmount,
                  onPaymentSuccess: () {
                    context.read<BookingDetailsCubit>().loadBooking(booking.id);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppSecondaryButton(
              text: 'مشاركة الإيصال',
              onPressed: () {
                _showReceiptSheet(context, booking);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceOptionsSheet(
    BuildContext context,
    Booking booking,
    ServiceItem service,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'تغيير حالة خدمة: ${service.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('محجوزة (تضاف للمستحقات)', style: AppTextStyles.body),
            trailing: service.status == BookingServiceStatus.booked
                ? const Icon(LucideIcons.check, color: AppColors.green)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              context.read<BookingDetailsCubit>().toggleServiceStatus(
                    service.id,
                    BookingServiceStatus.booked,
                  );
            },
          ),
          ListTile(
            title: const Text('غير محجوزة', style: AppTextStyles.body),
            trailing: service.status == BookingServiceStatus.notBooked
                ? const Icon(LucideIcons.check, color: AppColors.amber)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              context.read<BookingDetailsCubit>().toggleServiceStatus(
                    service.id,
                    BookingServiceStatus.notBooked,
                  );
            },
          ),
          ListTile(
            title: const Text('اختيارية', style: AppTextStyles.body),
            trailing: service.status == BookingServiceStatus.optional
                ? const Icon(LucideIcons.check, color: AppColors.muted)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              context.read<BookingDetailsCubit>().toggleServiceStatus(
                    service.id,
                    BookingServiceStatus.optional,
                  );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCustomServiceDialog(BuildContext context, Booking booking) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة خدمة مخصصة', style: AppTextStyles.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'اسم الخدمة',
              hint: 'مثال: سيارة ليموزين للعروسين',
              controller: nameController,
            ),
            const SizedBox(height: 10),
            AppTextField(
              label: 'السعر (ج.م)',
              hint: '٢٠٠٠',
              controller: priceController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;
              if (name.isNotEmpty && price > 0) {
                context.read<BookingDetailsCubit>().addCustomService(
                      ServiceItem(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        price: price,
                        status: BookingServiceStatus.booked,
                        isCustom: true,
                      ),
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الخدمة وزيادة إجمالي المستحق')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showActivityLogSheet(BuildContext context, Booking booking) {
    AppBottomSheet.show(
      context: context,
      title: 'سجل نشاط الحجز #${booking.id.toArabicDigits()}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: booking.activityLog.map((log) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    log.toArabicDigits(),
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReceiptSheet(BuildContext context, Booking booking) {
    AppBottomSheet.show(
      context: context,
      title: 'إيصال الحجز المالي',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Text(
                  'قاعات قاعتي | ${booking.hallName}',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text('إيصال سداد رقم #${booking.id.toArabicDigits()}', style: AppTextStyles.muted),
                const Divider(height: 20, color: AppColors.line),
                KeyValueRow(label: 'اسم العميل', value: booking.customerName),
                KeyValueRow(label: 'المناسبة', value: booking.eventType),
                KeyValueRow(label: 'تاريخ الفعالية', value: AppFormatters.formatDayMonth(booking.eventDate)),
                KeyValueRow(label: 'إجمالي العقد', value: AppFormatters.formatMoney(booking.totalAmount)),
                KeyValueRow(label: 'إجمالي المسدد', value: AppFormatters.formatMoney(booking.paidAmount), valueStyle: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                KeyValueRow(label: 'المتبقي', value: AppFormatters.formatMoney(booking.remainingAmount), valueStyle: const TextStyle(color: AppColors.amberText, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'مشاركة عبر واتساب أو تطبيقات أخرى',
            icon: const Icon(LucideIcons.share2, size: 18, color: AppColors.white),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تجهيز صورة الإيصال للمشاركة')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Booking booking) {
    if (action == 'edit') {
      context.push('/bookings/new?editBookingId=${booking.id}');
    } else if (action == 'share') {
      _showReceiptSheet(context, booking);
    } else if (action == 'reschedule') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الموعد الجديد من التقويم')),
      );
    } else if (action == 'cancel') {
      _showCancelDialog(context, booking);
    }
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    final reasonController = TextEditingController();
    String refundDecision = 'احتجاز العربون بالكامل';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إلغاء الحجز', style: TextStyle(color: AppColors.red, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('سبب الإلغاء إلزامي، ولن يُحذف الحجز نهائياً بل يُسجل في الملغاة.', style: AppTextStyles.body),
              const SizedBox(height: 10),
              AppTextField(
                label: 'سبب الإلغاء',
                hint: 'مثال: اعتذار العميل لظروف عائلية',
                controller: reasonController,
              ),
              const SizedBox(height: 10),
              const Text('قرار العربون المسدد:', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              DropdownButton<String>(
                value: refundDecision,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'احتجاز العربون بالكامل', child: Text('احتجاز العربون بالكامل')),
                  DropdownMenuItem(value: 'استرداد العربون للعميل', child: Text('استرداد العربون للعميل')),
                  DropdownMenuItem(value: 'استرداد جزئي (٥٠٪)', child: Text('استرداد جزئي (٥٠٪)')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => refundDecision = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('رجوع', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: AppColors.white),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  context.read<BookingDetailsCubit>().cancelBooking(reason, refundDecision);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إلغاء الحجز وتسجيل العملية بسجل النشاط')),
                  );
                }
              },
              child: const Text('تأكيد الإلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}
