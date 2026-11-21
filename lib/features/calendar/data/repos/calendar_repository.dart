import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarRepository {
  Future<List<CalendarDayModel>> getCalendarDays({required String hallId, required DateTime month});
  Future<MonthSummary> getMonthSummary({required String hallId, required DateTime month});
  Future<List<RemainingPaymentItem>> getRemainingPayments({required String hallId});
}

class MockCalendarRepository implements CalendarRepository {
  // TODO(API): Replace with real backend query
  @override
  Future<List<CalendarDayModel>> getCalendarDays({
    required String hallId,
    required DateTime month,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));

    // December 2026: 31 days
    // Day states per exact specification:
    // 1: paid
    // 3: deposit
    // 5: tentative
    // 6: deposit + overdueDot
    // 8: paid
    // 10: deposit
    // 11: paid + badge "٢"
    // 12: blocked
    // 15: deposit and selected (Booking 1042)
    // 17, 18: paid
    // 19: deposit
    // 22: tentative
    // 24: deposit
    // 25, 26: paid
    // 29: deposit
    // 31: paid
    // others: available

    final List<CalendarDayModel> result = [];
    for (int day = 1; day <= 31; day++) {
      DayStatus status = DayStatus.available;
      bool hasOverdueDot = false;
      String? badgeText;
      int? bookingId;
      String? customerName;
      String? eventType;
      String? timeRange;
      int? seatsCount;
      int? totalAmount;
      int? paidAmount;
      int? remainingAmount;

      if (day == 1) {
        status = DayStatus.paid;
        bookingId = 1038;
      } else if (day == 3) {
        status = DayStatus.deposit;
      } else if (day == 5) {
        status = DayStatus.tentative;
      } else if (day == 6) {
        status = DayStatus.deposit;
        hasOverdueDot = true;
        bookingId = 1040;
      } else if (day == 8) {
        status = DayStatus.paid;
      } else if (day == 10) {
        status = DayStatus.deposit;
      } else if (day == 11) {
        status = DayStatus.paid;
        badgeText = '2';
        bookingId = 1048;
      } else if (day == 12) {
        status = DayStatus.blocked;
      } else if (day == 15) {
        status = DayStatus.deposit;
        bookingId = 1042;
        customerName = 'محمد عبد الله';
        eventType = 'حفل زفاف';
        timeRange = '٨:٠٠ م – ١:٠٠ ص';
        seatsCount = 450;
        totalAmount = 48000;
        paidAmount = 30000;
        remainingAmount = 18000;
      } else if (day == 17 || day == 18) {
        status = DayStatus.paid;
      } else if (day == 19) {
        status = DayStatus.deposit;
      } else if (day == 22) {
        status = DayStatus.tentative;
      } else if (day == 24) {
        status = DayStatus.deposit;
        bookingId = 1044;
      } else if (day == 25 || day == 26) {
        status = DayStatus.paid;
      } else if (day == 29) {
        status = DayStatus.deposit;
      } else if (day == 31) {
        status = DayStatus.paid;
      }

      result.add(CalendarDayModel(
        dayNumber: day,
        status: status,
        hasOverdueDot: hasOverdueDot,
        badgeText: badgeText,
        bookingId: bookingId,
        customerName: customerName,
        eventType: eventType,
        timeRange: timeRange,
        seatsCount: seatsCount,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
      ));
    }

    return result;
  }

  @override
  Future<MonthSummary> getMonthSummary({
    required String hallId,
    required DateTime month,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    // Exact specification: "١٤ يوم / محجوز", "٤٨٠٬٠٠٠ / المتوقع (ج.م)", "٣١٠٬٠٠٠ / المُحصَّل (ج.م)"
    return const MonthSummary(
      bookedDays: 14,
      expectedRevenue: 480000,
      collectedRevenue: 310000,
    );
  }

  @override
  Future<List<RemainingPaymentItem>> getRemainingPayments({
    required String hallId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return const [
      RemainingPaymentItem(
        customerName: 'سارة محمود',
        dateDescription: 'الأحد ٦ ديسمبر · بعد ١٥ يوم · مستحق قريباً',
        remainingAmount: 22000,
        isDueSoon: true,
        bookingId: 1040,
      ),
      RemainingPaymentItem(
        customerName: 'محمد عبد الله',
        dateDescription: 'الثلاثاء ١٥ ديسمبر · بعد ٢٤ يوم',
        remainingAmount: 18000,
        isDueSoon: false,
        bookingId: 1042,
      ),
      RemainingPaymentItem(
        customerName: 'كريم ياسر',
        dateDescription: 'الخميس ٢٤ ديسمبر · بعد ٣٣ يوم',
        remainingAmount: 9000,
        isDueSoon: false,
        bookingId: 1044,
      ),
    ];
  }
}
