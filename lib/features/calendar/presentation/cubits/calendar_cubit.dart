import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/calendar_day_model.dart';
import '../../data/repos/calendar_repository.dart';

abstract class CalendarState {
  const CalendarState();
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final String hallId;
  final DateTime currentMonth;
  final int selectedDay;
  final String activeFilter; // 'all', 'deposit', 'paid', 'tentative'
  final List<CalendarDayModel> days;
  final MonthSummary summary;
  final List<RemainingPaymentItem> remainingPayments;

  const CalendarLoaded({
    required this.hallId,
    required this.currentMonth,
    required this.selectedDay,
    required this.activeFilter,
    required this.days,
    required this.summary,
    required this.remainingPayments,
  });

  CalendarDayModel? get selectedDayModel {
    try {
      return days.firstWhere((d) => d.dayNumber == selectedDay);
    } catch (_) {
      return null;
    }
  }

  CalendarLoaded copyWith({
    String? hallId,
    DateTime? currentMonth,
    int? selectedDay,
    String? activeFilter,
    List<CalendarDayModel>? days,
    MonthSummary? summary,
    List<RemainingPaymentItem>? remainingPayments,
  }) {
    return CalendarLoaded(
      hallId: hallId ?? this.hallId,
      currentMonth: currentMonth ?? this.currentMonth,
      selectedDay: selectedDay ?? this.selectedDay,
      activeFilter: activeFilter ?? this.activeFilter,
      days: days ?? this.days,
      summary: summary ?? this.summary,
      remainingPayments: remainingPayments ?? this.remainingPayments,
    );
  }
}

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository _repository;

  CalendarCubit(this._repository) : super(const CalendarInitial());

  Future<void> loadCalendar({
    String hallId = 'masia',
    DateTime? month,
    int? selectedDay,
  }) async {
    final previousState = state;
    final today = DateTime.now();
    final targetMonth = month ?? DateTime(today.year, today.month, 1);
    final daysInMonth =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final defaultSelectedDay =
        targetMonth.year == today.year && targetMonth.month == today.month
            ? today.day
            : previousState is CalendarLoaded
                ? previousState.selectedDay
                : 1;
    final targetSelectedDay =
        (selectedDay ?? defaultSelectedDay).clamp(1, daysInMonth).toInt();

    emit(const CalendarLoading());
    try {
      final days =
          await _repository.getCalendarDays(hallId: hallId, month: targetMonth);
      final summary =
          await _repository.getMonthSummary(hallId: hallId, month: targetMonth);
      final remaining = await _repository.getRemainingPayments(hallId: hallId);

      emit(CalendarLoaded(
        hallId: hallId,
        currentMonth: targetMonth,
        selectedDay: targetSelectedDay,
        activeFilter: 'all',
        days: days,
        summary: summary,
        remainingPayments: remaining,
      ));
    } catch (e) {
      // Handle error
    }
  }

  void selectDay(int day) {
    if (state is CalendarLoaded) {
      emit((state as CalendarLoaded).copyWith(selectedDay: day));
    }
  }

  void setFilter(String filter) {
    if (state is CalendarLoaded) {
      emit((state as CalendarLoaded).copyWith(activeFilter: filter));
    }
  }

  void nextMonth() {
    if (state is CalendarLoaded) {
      final current = state as CalendarLoaded;
      final cur = current.currentMonth;
      loadCalendar(
        hallId: current.hallId,
        month: DateTime(cur.year, cur.month + 1, 1),
        selectedDay: current.selectedDay,
      );
    }
  }

  void prevMonth() {
    if (state is CalendarLoaded) {
      final current = state as CalendarLoaded;
      final cur = current.currentMonth;
      loadCalendar(
        hallId: current.hallId,
        month: DateTime(cur.year, cur.month - 1, 1),
        selectedDay: current.selectedDay,
      );
    }
  }

  void goToToday() {
    final current = state;
    final today = DateTime.now();
    loadCalendar(
      hallId: current is CalendarLoaded ? current.hallId : 'masia',
      month: DateTime(today.year, today.month, 1),
      selectedDay: today.day,
    );
  }
}
