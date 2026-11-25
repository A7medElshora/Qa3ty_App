import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';

class HallDaySchedule {
  final int dayNumber;
  final String dayName;
  final DayStatus status;
  final bool isToday;
  final int? bookingId;

  const HallDaySchedule({
    required this.dayNumber,
    required this.dayName,
    required this.status,
    this.isToday = false,
    this.bookingId,
  });

  HallDaySchedule copyWith({
    int? dayNumber,
    String? dayName,
    DayStatus? status,
    bool? isToday,
    int? bookingId,
  }) {
    return HallDaySchedule(
      dayNumber: dayNumber ?? this.dayNumber,
      dayName: dayName ?? this.dayName,
      status: status ?? this.status,
      isToday: isToday ?? this.isToday,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}

class Hall {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final String workingHours;
  final int dailySlotsCount;
  final List<String> slotTimes;
  final bool isActive;
  final List<HallDaySchedule> currentWeekSchedule;
  final int weekBookingsCount;
  final int weekRemainingAmount;
  final int upcomingRemainingAmount;
  final int upcomingWeekEventsCount;

  const Hall({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    this.workingHours = '٨:٠٠ م – ٢:٠٠ ص',
    this.dailySlotsCount = 1,
    this.slotTimes = const ['٨:٠٠ م – ١:٠٠ ص'],
    this.isActive = true,
    required this.currentWeekSchedule,
    required this.weekBookingsCount,
    required this.weekRemainingAmount,
    this.upcomingRemainingAmount = 0,
    this.upcomingWeekEventsCount = 0,
  });

  Hall copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    String? workingHours,
    int? dailySlotsCount,
    List<String>? slotTimes,
    bool? isActive,
    List<HallDaySchedule>? currentWeekSchedule,
    int? weekBookingsCount,
    int? weekRemainingAmount,
    int? upcomingRemainingAmount,
    int? upcomingWeekEventsCount,
  }) {
    return Hall(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      workingHours: workingHours ?? this.workingHours,
      dailySlotsCount: dailySlotsCount ?? this.dailySlotsCount,
      slotTimes: slotTimes ?? this.slotTimes,
      isActive: isActive ?? this.isActive,
      currentWeekSchedule: currentWeekSchedule ?? this.currentWeekSchedule,
      weekBookingsCount: weekBookingsCount ?? this.weekBookingsCount,
      weekRemainingAmount: weekRemainingAmount ?? this.weekRemainingAmount,
      upcomingRemainingAmount:
          upcomingRemainingAmount ?? this.upcomingRemainingAmount,
      upcomingWeekEventsCount:
          upcomingWeekEventsCount ?? this.upcomingWeekEventsCount,
    );
  }
}
