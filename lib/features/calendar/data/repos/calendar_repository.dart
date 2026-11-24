import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/helpers/booking_id_registry.dart';
import 'package:qa3ty_app/core/helpers/booking_financials.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarRepository {
  Future<List<CalendarDayModel>> getCalendarDays(
      {required String hallId, required DateTime month});
  Future<MonthSummary> getMonthSummary(
      {required String hallId, required DateTime month});
  Future<List<RemainingPaymentItem>> getRemainingPayments(
      {required String hallId});
  void invalidateCache({String? hallId});
}

class RemoteCalendarRepository implements CalendarRepository {
  final Dio _dio;

  RemoteCalendarRepository(this._dio);

  // In-memory cache for loaded months to speed up UI transitions
  final Map<String, List<dynamic>> _calendarCache = {};

  @override
  void invalidateCache({String? hallId}) {
    if (hallId == null) {
      _calendarCache.clear();
    } else {
      _calendarCache.removeWhere((key, _) => key.startsWith('$hallId-'));
    }
  }

  Future<List<dynamic>> _fetchMonthEvents(String hallId, DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    return _fetchEventsBetween(hallId, firstDay, lastDay);
  }

  Future<List<dynamic>> _fetchEventsBetween(
    String hallId,
    DateTime start,
    DateTime end,
  ) async {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    final cacheKey = '$hallId-$startStr-$endStr';
    if (_calendarCache.containsKey(cacheKey)) {
      return _calendarCache[cacheKey]!;
    }

    try {
      final response = await _dio.get(
        '/bookings/calendar',
        queryParameters: {
          'start_date': startStr,
          'end_date': endStr,
          'hall_id': hallId,
        },
      );

      List<dynamic> items = [];
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        }
      } else if (response.data is List) {
        items = response.data as List<dynamic>;
      }

      _calendarCache[cacheKey] = items;
      return items;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<CalendarDayModel>> getCalendarDays({
    required String hallId,
    required DateTime month,
  }) async {
    final events = await _fetchMonthEvents(hallId, month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();

    final List<CalendarDayModel> result = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dayEvents = events
          .where((e) =>
              e is Map<String, dynamic> &&
              e['status'] != 'cancelled' &&
              e['event_date'] == dateStr)
          .toList();

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

      if (dayEvents.isNotEmpty) {
        if (dayEvents.length > 1) {
          badgeText = dayEvents.length.toString();
        }

        final primaryEvent = dayEvents.first as Map<String, dynamic>;
        final rawId = primaryEvent['id']?.toString() ?? '';
        if (rawId.isNotEmpty) {
          bookingId = BookingIdRegistry.ensureLocalId(rawId);
        }
        customerName =
            (primaryEvent['customers'] as Map<String, dynamic>?)?['full_name']
                    ?.toString() ??
                primaryEvent['event_name']?.toString() ??
                '';
        eventType = primaryEvent['event_type'] == 'wedding'
            ? 'حفل زفاف'
            : primaryEvent['event_type'] == 'engagement'
                ? 'حفل خطوبة'
                : 'مناسبة خاصة';
        final startTime = primaryEvent['start_time']?.toString() ?? '18:00';
        final endTime = primaryEvent['end_time']?.toString() ?? '23:00';
        timeRange = '$startTime – $endTime';
        seatsCount = 450; // Default capacity

        final total = (primaryEvent['total_price'] as num?)?.toDouble() ?? 0.0;
        final paid = bookingPaidAmount(primaryEvent);
        final rem = bookingRemainingAmount(primaryEvent);

        totalAmount = total.round();
        paidAmount = paid.round();
        remainingAmount = rem.round();

        // Check overdue
        final eventDate = DateTime.tryParse(dateStr);
        if (eventDate != null && eventDate.isBefore(now) && rem > 0) {
          hasOverdueDot = true;
        }

        final st = primaryEvent['status']?.toString();
        if (st == 'pending') {
          status = DayStatus.tentative;
        } else if (rem == 0) {
          status = DayStatus.paid;
        } else if (paid > 0 && rem > 0) {
          status = DayStatus.deposit;
        } else {
          status = DayStatus.deposit;
        }
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
    final events = await _fetchMonthEvents(hallId, month);
    final Set<String> bookedDates = {};
    double expected = 0.0;
    double collected = 0.0;

    for (final e in events) {
      if (e is! Map<String, dynamic> || e['status'] == 'cancelled') continue;
      final date = e['event_date']?.toString();
      if (date != null) bookedDates.add(date);

      final total = (e['total_price'] as num?)?.toDouble() ?? 0.0;
      final paid = bookingPaidAmount(e);

      expected += total;
      collected += paid;
    }

    return MonthSummary(
      bookedDays: bookedDates.length,
      expectedRevenue: expected.round(),
      collectedRevenue: collected.round(),
    );
  }

  @override
  Future<List<RemainingPaymentItem>> getRemainingPayments({
    required String hallId,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year + 1, now.month, now.day);
    final events = (await _fetchEventsBetween(hallId, start, end))
        .whereType<Map<String, dynamic>>()
        .where((event) => event['status'] != 'cancelled')
        .toList()
      ..sort((a, b) => (a['event_date']?.toString() ?? '')
          .compareTo(b['event_date']?.toString() ?? ''));

    final List<RemainingPaymentItem> items = [];

    for (final e in events) {
      final rem = bookingRemainingAmount(e);
      if (rem <= 0) continue;

      final customerName =
          (e['customers'] as Map<String, dynamic>?)?['full_name']?.toString() ??
              e['event_name']?.toString() ??
              'عميل';
      final dateStr = e['event_date']?.toString() ?? '';
      final eventDate = DateTime.tryParse(dateStr) ?? now;
      final today = DateTime(now.year, now.month, now.day);
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final daysDiff = eventDay.difference(today).inDays;
      final isDueSoon = daysDiff <= 7 && daysDiff >= 0;

      final rawId = e['id']?.toString() ?? '';
      if (rawId.isEmpty) continue;
      final bookingId = BookingIdRegistry.ensureLocalId(rawId);

      items.add(
        RemainingPaymentItem(
          customerName: customerName,
          dateDescription:
              '$dateStr · بعد $daysDiff يوم${isDueSoon ? " · مستحق قريباً" : ""}',
          remainingAmount: rem.round(),
          isDueSoon: isDueSoon,
          bookingId: bookingId,
        ),
      );
    }

    // Sort by event date ascending
    return items;
  }
}

class MockCalendarRepository implements CalendarRepository {
  @override
  void invalidateCache({String? hallId}) {}

  // TODO(API): Replace with real backend query
  @override
  Future<List<CalendarDayModel>> getCalendarDays({
    required String hallId,
    required DateTime month,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));

    final List<CalendarDayModel> result = [];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
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
