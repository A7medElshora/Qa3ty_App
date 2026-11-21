import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';

class CalendarDayModel {
  final int dayNumber;
  final DayStatus status;
  final bool hasOverdueDot;
  final String? badgeText;
  final int? bookingId;
  final String? customerName;
  final String? eventType;
  final String? timeRange;
  final int? seatsCount;
  final int? totalAmount;
  final int? paidAmount;
  final int? remainingAmount;

  const CalendarDayModel({
    required this.dayNumber,
    required this.status,
    this.hasOverdueDot = false,
    this.badgeText,
    this.bookingId,
    this.customerName,
    this.eventType,
    this.timeRange,
    this.seatsCount,
    this.totalAmount,
    this.paidAmount,
    this.remainingAmount,
  });
}

class MonthSummary {
  final int bookedDays;
  final int expectedRevenue;
  final int collectedRevenue;

  const MonthSummary({
    required this.bookedDays,
    required this.expectedRevenue,
    required this.collectedRevenue,
  });
}

class RemainingPaymentItem {
  final String customerName;
  final String dateDescription; // e.g. "الأحد ٦ ديسمبر · بعد ١٥ يوم · مستحق قريباً"
  final int remainingAmount;
  final bool isDueSoon;
  final int bookingId;

  const RemainingPaymentItem({
    required this.customerName,
    required this.dateDescription,
    required this.remainingAmount,
    required this.isDueSoon,
    required this.bookingId,
  });
}
