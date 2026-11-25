import 'dart:async';
import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/helpers/booking_financials.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/api_response.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../models/hall_model.dart';

class DashboardSummary {
  final int hallsCount;
  final int customersCount;
  final int bookingsCount;
  final int dueBookingsCount;
  final List<dynamic> upcomingBookings;
  final Map<String, dynamic>? dailyFinancial;

  const DashboardSummary({
    required this.hallsCount,
    required this.customersCount,
    required this.bookingsCount,
    required this.dueBookingsCount,
    required this.upcomingBookings,
    this.dailyFinancial,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final upcoming = (json['upcoming_bookings'] as List<dynamic>?) ?? [];
    int dueCount = 0;
    for (final b in upcoming) {
      if (b is Map<String, dynamic>) {
        final remaining = bookingRemainingAmount(b);
        if (remaining > 0) dueCount++;
      }
    }

    return DashboardSummary(
      hallsCount: (json['halls_count'] as num?)?.toInt() ?? 0,
      customersCount: (json['customers_count'] as num?)?.toInt() ?? 0,
      bookingsCount: (json['bookings_count'] as num?)?.toInt() ?? 0,
      dueBookingsCount: dueCount,
      upcomingBookings: upcoming,
      dailyFinancial: json['daily_financial'] as Map<String, dynamic>?,
    );
  }
}

abstract class HallsRepository {
  Future<List<Hall>> getHalls();
  Future<Hall?> getHallById(String id);
  Future<void> addHall(Hall hall);
  Future<void> updateHall(Hall hall);
  Future<void> deleteHall(String id);
  Future<DashboardSummary?> getDashboardSummary();
}

class RemoteHallsRepository implements HallsRepository {
  final Dio _dio;

  RemoteHallsRepository(this._dio);

  @override
  Future<List<Hall>> getHalls() async {
    try {
      final response =
          await _dio.get('/halls', queryParameters: {'active': 'true'});
      final apiRes = ApiResponse<List<dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json is Map<String, dynamic> && json['items'] is List)
            ? json['items'] as List<dynamic>
            : (json as List<dynamic>? ?? []),
      );

      final rawList = apiRes.requireData;
      final List<Hall> halls = [];

      final now = DateTime.now();
      // Calculate current week starting from Saturday
      // DateTime.weekday: Monday=1 ... Sunday=7, Saturday=6
      final daysSinceSaturday =
          (now.weekday == DateTime.saturday) ? 0 : (now.weekday + 1) % 7;
      final saturday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysSinceSaturday));
      final upcomingEnd = DateTime(now.year + 1, now.month, now.day);

      final startStr =
          '${saturday.year}-${saturday.month.toString().padLeft(2, '0')}-${saturday.day.toString().padLeft(2, '0')}';
      final endStr =
          '${upcomingEnd.year}-${upcomingEnd.month.toString().padLeft(2, '0')}-${upcomingEnd.day.toString().padLeft(2, '0')}';

      for (final raw in rawList) {
        if (raw is! Map<String, dynamic>) continue;
        final hallId = raw['id']?.toString() ?? '';

        // Fetch a year of events for upcoming balances and the current week.
        List<dynamic> calendarEvents = [];
        final calRes = await _dio.get(
          '/bookings/calendar',
          queryParameters: {
            'start_date': startStr,
            'end_date': endStr,
            'hall_id': hallId,
          },
        );
        if (calRes.data is Map<String, dynamic> &&
            calRes.data['data'] is List) {
          calendarEvents = calRes.data['data'] as List<dynamic>;
        }

        // Build 7-day schedule
        final List<HallDaySchedule> weekSchedule = [];
        int weekBookings = 0;
        int weekRemaining = 0;
        var upcomingRemaining = 0;
        var upcomingWeekEvents = 0;
        for (final event in calendarEvents.whereType<Map<String, dynamic>>()) {
          if (event['status'] != 'cancelled') {
            upcomingRemaining += bookingRemainingAmount(event).round();
            final eventDate = DateTime.tryParse(
              event['event_date']?.toString() ?? '',
            );
            final today = DateTime(now.year, now.month, now.day);
            final lastUpcomingDay = today.add(const Duration(days: 7));
            final eventDay = eventDate == null
                ? null
                : DateTime(eventDate.year, eventDate.month, eventDate.day);
            if (eventDay != null &&
                !eventDay.isBefore(today) &&
                !eventDay.isAfter(lastUpcomingDay)) {
              upcomingWeekEvents++;
            }
          }
        }

        const weekdayNames = [
          'السبت',
          'الأحد',
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة'
        ];

        for (int i = 0; i < 7; i++) {
          final dayDate = saturday.add(Duration(days: i));
          final dateStr =
              '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
          final isToday = dayDate.year == now.year &&
              dayDate.month == now.month &&
              dayDate.day == now.day;

          final dayEvents = calendarEvents
              .where((e) =>
                  e is Map<String, dynamic> &&
                  e['status'] != 'cancelled' &&
                  e['event_date'] == dateStr)
              .toList();

          DayStatus status = DayStatus.available;
          int? bookingId;

          if (dayEvents.isNotEmpty) {
            weekBookings += dayEvents.length;
            bool hasDeposit = false;
            bool allPaid = true;
            bool hasTentative = false;

            for (final ev in dayEvents) {
              final rem = bookingRemainingAmount(ev);
              final paid = bookingPaidAmount(ev);
              final st = ev['status']?.toString();

              weekRemaining += rem.round();

              if (st == 'pending') {
                hasTentative = true;
              } else if (rem == 0) {
                // fully paid
              } else if (paid > 0 && rem > 0) {
                hasDeposit = true;
                allPaid = false;
              } else {
                allPaid = false;
              }
            }

            if (hasDeposit) {
              status = DayStatus.deposit;
            } else if (allPaid) {
              status = DayStatus.paid;
            } else if (hasTentative) {
              status = DayStatus.tentative;
            } else {
              status = DayStatus.deposit;
            }
          }

          weekSchedule.add(
            HallDaySchedule(
              dayNumber: dayDate.day,
              dayName: weekdayNames[i],
              status: status,
              isToday: isToday,
              bookingId: bookingId,
            ),
          );
        }

        halls.add(
          Hall(
            id: hallId,
            name: raw['name']?.toString() ?? '',
            location: raw['address']?.toString() ?? 'الموقع غير محدد',
            capacity: (raw['capacity'] as num?)?.toInt() ?? 0,
            // TODO(API): working hours & daily slots are not in API, using defaults
            workingHours: '٨:٠٠ م – ٢:٠٠ ص',
            dailySlotsCount: 1,
            slotTimes: const ['٨:٠٠ م – ١:٠٠ ص'],
            isActive: raw['is_active'] != false,
            currentWeekSchedule: weekSchedule,
            weekBookingsCount: weekBookings,
            weekRemainingAmount: weekRemaining,
            upcomingRemainingAmount: upcomingRemaining,
            upcomingWeekEventsCount: upcomingWeekEvents,
          ),
        );
      }

      return halls;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Hall?> getHallById(String id) async {
    try {
      final response = await _dio.get('/halls/$id');
      final apiRes = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      final raw = apiRes.requireData;
      return Hall(
        id: raw['id']?.toString() ?? id,
        name: raw['name']?.toString() ?? '',
        location: raw['address']?.toString() ?? '',
        capacity: (raw['capacity'] as num?)?.toInt() ?? 0,
        workingHours: '٨:٠٠ م – ٢:٠٠ ص',
        dailySlotsCount: 1,
        slotTimes: const ['٨:٠٠ م – ١:٠٠ ص'],
        isActive: raw['is_active'] != false,
        currentWeekSchedule: const [],
        weekBookingsCount: 0,
        weekRemainingAmount: 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> addHall(Hall hall) async {
    try {
      await _dio.post(
        '/halls',
        data: {
          'name': hall.name,
          'address': hall.location,
          'capacity': hall.capacity > 0 ? hall.capacity : null,
          'is_active': hall.isActive,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateHall(Hall hall) async {
    try {
      await _dio.put(
        '/halls/${hall.id}',
        data: {
          'name': hall.name,
          'address': hall.location,
          'capacity': hall.capacity > 0 ? hall.capacity : null,
          'is_active': hall.isActive,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteHall(String id) async {
    try {
      await _dio.delete('/halls/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<DashboardSummary?> getDashboardSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return DashboardSummary.fromJson(
              data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class MockHallsRepository implements HallsRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<Hall> _halls = [
    const Hall(
      id: 'masia',
      name: 'قاعة الماسة',
      location: 'طنطا، الغربية',
      capacity: 600,
      workingHours: '٨:٠٠ م – ٢:٠٠ ص',
      dailySlotsCount: 1,
      slotTimes: ['٨:٠٠ م – ١:٠٠ ص'],
      isActive: true,
      weekBookingsCount: 4,
      weekRemainingAmount: 45000,
      upcomingRemainingAmount: 45000,
      upcomingWeekEventsCount: 4,
      currentWeekSchedule: [
        HallDaySchedule(
          dayNumber: 21,
          dayName: 'السبت',
          status: DayStatus.paid,
          isToday: true,
          bookingId: 1041,
        ),
        HallDaySchedule(
          dayNumber: 22,
          dayName: 'الأحد',
          status: DayStatus.available,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 23,
          dayName: 'الاثنين',
          status: DayStatus.deposit,
          isToday: false,
          bookingId: 1042,
        ),
        HallDaySchedule(
          dayNumber: 24,
          dayName: 'الثلاثاء',
          status: DayStatus.available,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 25,
          dayName: 'الأربعاء',
          status: DayStatus.tentative,
          isToday: false,
          bookingId: 1043,
        ),
        HallDaySchedule(
          dayNumber: 26,
          dayName: 'الخميس',
          status: DayStatus.deposit,
          isToday: false,
          bookingId: 1044,
        ),
        HallDaySchedule(
          dayNumber: 27,
          dayName: 'الجمعة',
          status: DayStatus.paid,
          isToday: false,
          bookingId: 1045,
        ),
      ],
    ),
    const Hall(
      id: 'nakheel',
      name: 'قاعة النخيل',
      location: 'المنصورة، الدقهلية',
      capacity: 350,
      workingHours: '٧:٠٠ م – ١:٠٠ ص',
      dailySlotsCount: 1,
      slotTimes: ['٧:٠٠ م – ١:٠٠ ص'],
      isActive: true,
      weekBookingsCount: 2,
      weekRemainingAmount: 12000,
      upcomingRemainingAmount: 12000,
      upcomingWeekEventsCount: 2,
      currentWeekSchedule: [
        HallDaySchedule(
          dayNumber: 21,
          dayName: 'السبت',
          status: DayStatus.available,
          isToday: true,
        ),
        HallDaySchedule(
          dayNumber: 22,
          dayName: 'الأحد',
          status: DayStatus.available,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 23,
          dayName: 'الاثنين',
          status: DayStatus.paid,
          isToday: false,
          bookingId: 1046,
        ),
        HallDaySchedule(
          dayNumber: 24,
          dayName: 'الثلاثاء',
          status: DayStatus.available,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 25,
          dayName: 'الأربعاء',
          status: DayStatus.available,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 26,
          dayName: 'الخميس',
          status: DayStatus.deposit,
          isToday: false,
          bookingId: 1047,
        ),
        HallDaySchedule(
          dayNumber: 27,
          dayName: 'الجمعة',
          status: DayStatus.available,
          isToday: false,
        ),
      ],
    ),
  ];

  @override
  Future<List<Hall>> getHalls() async {
    await Future.delayed(const Duration(milliseconds: 30));
    return List.unmodifiable(_halls);
  }

  @override
  Future<Hall?> getHallById(String id) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _halls
        .cast<Hall?>()
        .firstWhere((h) => h?.id == id, orElse: () => null);
  }

  @override
  Future<void> addHall(Hall hall) async {
    await Future.delayed(const Duration(milliseconds: 40));
    _halls.add(hall);
  }

  @override
  Future<void> updateHall(Hall hall) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final index = _halls.indexWhere((h) => h.id == hall.id);
    if (index != -1) {
      _halls[index] = hall;
    }
  }

  @override
  Future<void> deleteHall(String id) async {
    await Future.delayed(const Duration(milliseconds: 30));
    _halls.removeWhere((h) => h.id == id);
  }

  @override
  Future<DashboardSummary?> getDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 20));
    return const DashboardSummary(
      hallsCount: 2,
      customersCount: 120,
      bookingsCount: 45,
      dueBookingsCount: 2,
      upcomingBookings: [],
    );
  }
}
