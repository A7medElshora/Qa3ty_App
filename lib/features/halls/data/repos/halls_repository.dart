import 'dart:async';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import '../models/hall_model.dart';

abstract class HallsRepository {
  Future<List<Hall>> getHalls();
  Future<Hall?> getHallById(String id);
  Future<void> addHall(Hall hall);
  Future<void> updateHall(Hall hall);
  Future<void> deleteHall(String id);
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
      currentWeekSchedule: [
        // Saturday is index 0 in week, day 21 (Today)
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
          status: DayStatus.blocked,
          isToday: false,
        ),
        HallDaySchedule(
          dayNumber: 27,
          dayName: 'الجمعة',
          status: DayStatus.deposit,
          isToday: false,
          bookingId: 1047,
        ),
      ],
    ),
  ];

  @override
  Future<List<Hall>> getHalls() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_halls);
  }

  @override
  Future<Hall?> getHallById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _halls.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addHall(Hall hall) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _halls.add(hall);
  }

  @override
  Future<void> updateHall(Hall hall) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _halls.indexWhere((h) => h.id == hall.id);
    if (index != -1) {
      _halls[index] = hall;
    }
  }

  @override
  Future<void> deleteHall(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _halls.removeWhere((h) => h.id == id);
  }
}
