import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/features/calendar/data/models/calendar_day_model.dart';
import 'package:qa3ty_app/features/calendar/data/repos/calendar_repository.dart';
import 'package:qa3ty_app/features/calendar/presentation/widgets/hall_availability_date_picker.dart';

void main() {
  testWidgets('booking date picker marks occupied days and returns free days',
      (tester) async {
    final repository = _AvailabilityRepository();
    DateTime? selectedDate;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selectedDate = await showHallAvailabilityDatePicker(
                  context: context,
                  hallId: 'hall-1',
                  initialDate: DateTime(2026, 12, 10),
                  repository: repository,
                );
              },
              child: const Text('اختيار موعد'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('اختيار موعد'));
    await tester.pumpAndSettle();
    expect(repository.requestedHallId, 'hall-1');
    final chooseButton = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('اختيار'),
        matching: find.byType(TextButton),
      ),
    );
    expect(chooseButton.onPressed, isNull);

    await tester.ensureVisible(find.text('١١'));
    await tester.tap(find.text('١١'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اختيار'));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(2026, 12, 11));
  });
}

class _AvailabilityRepository implements CalendarRepository {
  String? requestedHallId;

  @override
  Future<List<CalendarDayModel>> getCalendarDays({
    required String hallId,
    required DateTime month,
  }) async {
    requestedHallId = hallId;
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(
      dayCount,
      (index) => CalendarDayModel(
        dayNumber: index + 1,
        status: index + 1 == 10 ? DayStatus.deposit : DayStatus.available,
      ),
    );
  }

  @override
  Future<MonthSummary> getMonthSummary({
    required String hallId,
    required DateTime month,
  }) async =>
      const MonthSummary(
        bookedDays: 0,
        expectedRevenue: 0,
        collectedRevenue: 0,
      );

  @override
  Future<List<RemainingPaymentItem>> getRemainingPayments({
    required String hallId,
  }) async =>
      const [];

  @override
  void invalidateCache({String? hallId}) {}
}
