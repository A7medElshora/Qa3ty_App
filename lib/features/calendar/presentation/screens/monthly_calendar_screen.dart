import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/core/utils/widgets/app_progress_bar.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../cubits/calendar_cubit.dart';
import '../../data/models/calendar_day_model.dart';
import 'package:qa3ty_app/features/bookings/presentation/widgets/add_payment_bottom_sheet.dart';
import 'package:qa3ty_app/features/halls/data/models/hall_model.dart';

class MonthlyCalendarScreen extends StatelessWidget {
  final String hallId;
  final DateTime? initialMonth;
  final int? initialSelectedDay;

  const MonthlyCalendarScreen({
    super.key,
    this.hallId = 'masia',
    this.initialMonth,
    this.initialSelectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(ServicesLocator.calendarRepo)
        ..loadCalendar(
          hallId: hallId,
          month: initialMonth,
          selectedDay: initialSelectedDay,
        ),
      child: MonthlyCalendarView(hallId: hallId),
    );
  }
}

class MonthlyCalendarView extends StatelessWidget {
  final String hallId;

  const MonthlyCalendarView({
    super.key,
    required this.hallId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 52, left: 16, right: 16),
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              if (state is CalendarLoading) {
                return const AppSkeletonizer(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Column(
                      children: [
                        AppSkeletonPanel(height: 64, lineCount: 1),
                        SizedBox(height: 16),
                        AppSkeletonPanel(height: 74, lineCount: 1),
                        SizedBox(height: 14),
                        AppSkeletonPanel(height: 100, lineCount: 2),
                        SizedBox(height: 14),
                        AppSkeletonPanel(height: 340, lineCount: 6),
                        SizedBox(height: 14),
                        AppSkeletonPanel(height: 180, lineCount: 3),
                      ],
                    ),
                  ),
                );
              }
              if (state is! CalendarLoaded) {
                return const SizedBox.shrink();
              }

              final cubit = context.read<CalendarCubit>();
              final selectedDayModel = state.selectedDayModel;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Header: Back button + Title/Subtitle on right, + button on left
                    Row(
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
                                    context.go('/halls');
                                  }
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HallInfo(hallId: hallId),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (PermissionGuard.canManageBookings)
                          CircleIconButton.primary(
                            icon: const Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: AppColors.white,
                            ),
                            onTap: () => _openNewBooking(
                              context,
                              cubit,
                              state.currentMonth,
                              day: state.selectedDay,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 2) Month Navigation: Prev Month, Month Title, Next Month, Today Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildMonthNavButton(
                                icon: LucideIcons.chevronRight,
                                onTap: () => cubit.prevMonth(),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppFormatters.formatMonthYear(
                                      state.currentMonth),
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildMonthNavButton(
                                icon: LucideIcons.chevronLeft,
                                onTap: () => cubit.nextMonth(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => cubit.goToToday(),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.line, width: 1.0),
                            ),
                            child: const Text(
                              'اليوم',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3) Month Summary Card: primary background, 3 stats
                    _buildMonthSummaryCard(state.summary),

                    const SizedBox(height: 14),

                    // 4) Filter Chips: الكل, عربون فقط, مدفوع, مؤقت
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppChip(
                            label: 'الكل',
                            isSelected: state.activeFilter == 'all',
                            onTap: () => cubit.setFilter('all'),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'عربون فقط',
                            isSelected: state.activeFilter == 'deposit',
                            onTap: () => cubit.setFilter('deposit'),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'مدفوع',
                            isSelected: state.activeFilter == 'paid',
                            onTap: () => cubit.setFilter('paid'),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'مؤقت',
                            isSelected: state.activeFilter == 'tentative',
                            onTap: () => cubit.setFilter('tentative'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5) Calendar Grid Card
                    _buildCalendarGridCard(context, state),

                    const SizedBox(height: 14),

                    // 6) Bottom Sheet Preview for Selected Day
                    _buildSelectedDayPreview(context, state, selectedDayModel),

                    if (PermissionGuard.canViewReports) ...[
                      const SizedBox(height: 14),
                      _buildRemainingPaymentsSection(context, state),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openNewBooking(
    BuildContext context,
    CalendarCubit cubit,
    DateTime month, {
    int? day,
  }) async {
    final bookingDate = DateTime(
      month.year,
      month.month,
      day ?? DateTime.now().day,
    );
    final dateQuery =
        '&date=${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
    final created = await context.push<bool>(
      '/bookings/new?hallId=$hallId$dateQuery',
    );
    if (created == true && context.mounted) {
      await cubit.loadCalendar(
        hallId: hallId,
        month: month,
        selectedDay: bookingDate.day,
      );
    }
  }

  Future<void> _openBookingDetails(
    BuildContext context,
    CalendarLoaded state,
    int bookingId,
  ) async {
    final wasCancelled = await context.push<bool>('/bookings/$bookingId');
    if (wasCancelled == true && context.mounted) {
      ServicesLocator.calendarRepo.invalidateCache(hallId: state.hallId);
      await context.read<CalendarCubit>().loadCalendar(
            hallId: state.hallId,
            month: state.currentMonth,
            selectedDay: state.selectedDay,
          );
    }
  }

  Widget _buildMonthNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSummaryCard(MonthSummary summary) {
    final canViewReports = PermissionGuard.canViewReports;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1) Booked days
          Expanded(
            child: _buildSummaryItem(
              value: '${summary.bookedDays.toArabicDigits()} يوم',
              label: 'محجوز',
            ),
          ),
          if (canViewReports) ...[
            Container(
              width: 1,
              height: 32,
              color: AppColors.primarySoftText.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSummaryItem(
                value: AppFormatters.formatMoneyOnly(summary.expectedRevenue),
                label: 'المتوقع (ج.م)',
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.primarySoftText.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildSummaryItem(
                value: AppFormatters.formatMoneyOnly(summary.collectedRevenue),
                label: 'المُحصَّل (ج.م)',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.bigAmount,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.primarySoftText,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGridCard(BuildContext context, CalendarLoaded state) {
    final cubit = context.read<CalendarCubit>();
    final firstWeekdayOffset =
        (DateTime(state.currentMonth.year, state.currentMonth.month, 1)
                    .weekday +
                1) %
            7;
    final daysInMonth = state.days.length;
    final rowCount = (firstWeekdayOffset + daysInMonth + 6) ~/ 7;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        children: [
          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppFormatters.arabicWeekdaysShort.map((dayName) {
              return SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Days grid
          Table(
            children: List.generate(rowCount, (rowIndex) {
              return TableRow(
                children: List.generate(7, (colIndex) {
                  final cellIndex = rowIndex * 7 + colIndex;
                  final dayNumber = cellIndex - firstWeekdayOffset + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(
                      width: 46,
                      height: 40,
                    );
                  }

                  final dayModel = state.days[dayNumber - 1];
                  final isSelected = dayNumber == state.selectedDay;

                  // Dimming logic
                  bool isDimmed = false;
                  if (state.activeFilter == 'deposit' &&
                      dayModel.status != DayStatus.deposit) {
                    isDimmed = true;
                  } else if (state.activeFilter == 'paid' &&
                      dayModel.status != DayStatus.paid) {
                    isDimmed = true;
                  } else if (state.activeFilter == 'tentative' &&
                      dayModel.status != DayStatus.tentative) {
                    isDimmed = true;
                  }

                  return Container(
                    width: 46,
                    height: 40,
                    alignment: Alignment.center,
                    child: DayCircle(
                      dayNumber: dayNumber,
                      status: dayModel.status,
                      size: 36,
                      isSelected: isSelected,
                      hasOverdueDot: dayModel.hasOverdueDot,
                      badgeText: dayModel.badgeText,
                      isDimmed: isDimmed,
                      onTap: () => cubit.selectDay(dayNumber),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayPreview(
    BuildContext context,
    CalendarLoaded state,
    CalendarDayModel? model,
  ) {
    final selectedDate = DateTime(
      state.currentMonth.year,
      state.currentMonth.month,
      state.selectedDay,
    );
    if (model == null ||
        model.status == DayStatus.available ||
        model.status == DayStatus.blocked) {
      // Empty / Available day
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.topBarShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppFormatters.formatFullDate(selectedDate),
                    style: AppTextStyles.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip.fromStatus(BookingServiceStatus.optional),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'لا يوجد حجز مؤكد في هذا اليوم، الفترات متاحة للحجز.',
              style: AppTextStyles.muted,
            ),
            const SizedBox(height: 14),
            if (PermissionGuard.canManageBookings)
              AppPrimaryButton(
                text: 'حجز جديد في هذا اليوم',
                onPressed: () => _openNewBooking(
                  context,
                  context.read<CalendarCubit>(),
                  state.currentMonth,
                  day: state.selectedDay,
                ),
              ),
          ],
        ),
      );
    }

    final double progress =
        (model.totalAmount != null && model.totalAmount! > 0)
            ? (model.paidAmount! / model.totalAmount!)
            : 0.625;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 26, 51, 0.08),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Date and status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppFormatters.formatDayMonth(selectedDate),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.fromStatus(BookingServiceStatus.depositOnly),
            ],
          ),

          const SizedBox(height: 6),

          // Customer and event type
          Text(
            '${model.customerName ?? "محمد عبد الله"} · ${model.eventType ?? "حفل زفاف"}',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(height: 2),

          // Time and capacity
          Text(
            '${model.timeRange ?? "٨:٠٠ م – ١:٠٠ ص"} · ${(model.seatsCount ?? 450).toArabicDigits()} مقعد',
            style: AppTextStyles.muted,
          ),

          const SizedBox(height: 10),

          // Progress bar (fills amber from right)
          AppProgressBar(
            progress: progress,
            height: 8,
            fillColor: AppColors.amber,
          ),

          const SizedBox(height: 8),

          // Paid and remaining row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'المدفوع ${AppFormatters.formatMoney(model.paidAmount ?? 30000)}',
                  style: AppTextStyles.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'المتبقي ${AppFormatters.formatMoney(model.remainingAmount ?? 18000)}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Two equal buttons: فتح التفاصيل + إضافة دفعة
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  text: 'فتح التفاصيل',
                  onPressed: () => _openBookingDetails(
                    context,
                    state,
                    model.bookingId ?? 1042,
                  ),
                ),
              ),
              if (PermissionGuard.canManageBookings) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AppSecondaryButton(
                    text: 'إضافة دفعة',
                    onPressed: () {
                      final bId = model.bookingId ?? 1042;
                      AddPaymentBottomSheet.show(
                        context: context,
                        bookingId: bId,
                        remainingAmount: model.remainingAmount ?? 18000,
                        onPaymentSuccess: () {
                          ServicesLocator.calendarRepo
                              .invalidateCache(hallId: hallId);
                          context.read<CalendarCubit>().loadCalendar(
                                hallId: hallId,
                                month: state.currentMonth,
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingPaymentsSection(
    BuildContext context,
    CalendarLoaded state,
  ) {
    final items = state.remainingPayments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مبالغ متبقية',
              style: AppTextStyles.sectionTitle,
            ),
            GestureDetector(
              onTap: () => context.push('/bookings?filter=due'),
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: () => _openBookingDetails(
                      context,
                      state,
                      item.bookingId,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.customerName,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.dateDescription.toArabicDigits(),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: item.isDueSoon
                                        ? AppColors.red
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: item.isDueSoon
                                  ? AppColors.redBg
                                  : AppColors.amberBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppFormatters.formatMoney(item.remainingAmount),
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.isDueSoon
                                    ? AppColors.red
                                    : AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        color: AppColors.line, height: 1, thickness: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HallInfo extends StatefulWidget {
  final String hallId;

  const _HallInfo({required this.hallId});

  @override
  State<_HallInfo> createState() => _HallInfoState();
}

class _HallInfoState extends State<_HallInfo> {
  late Future<Hall?> _hallFuture;

  @override
  void initState() {
    super.initState();
    _hallFuture = ServicesLocator.hallsRepo.getHallById(widget.hallId);
  }

  @override
  void didUpdateWidget(covariant _HallInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hallId != widget.hallId) {
      _hallFuture = ServicesLocator.hallsRepo.getHallById(widget.hallId);
    }
  }

  void _loadHall() {
    setState(() {
      _hallFuture = ServicesLocator.hallsRepo.getHallById(widget.hallId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Hall?>(
      future: _hallFuture,
      builder: (context, snapshot) {
        final hall = snapshot.data;
        final title = snapshot.hasError
            ? 'تعذر تحميل بيانات القاعة'
            : snapshot.connectionState != ConnectionState.done
                ? 'جاري تحميل بيانات القاعة'
                : hall?.name ?? 'القاعة غير موجودة';
        final subtitle = hall == null
            ? snapshot.hasError
                ? 'اضغط لإعادة المحاولة'
                : ''
            : '${hall.capacity.toArabicDigits()} مقعد · ${hall.location}';

        return GestureDetector(
          onTap: snapshot.hasError ? _loadHall : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
