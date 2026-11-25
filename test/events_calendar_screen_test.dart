import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import 'package:qa3ty_app/features/bookings/data/repos/bookings_repository.dart';
import 'package:qa3ty_app/features/calendar/presentation/screens/events_calendar_screen.dart';

void main() {
  testWidgets('events are shown in cards grouped by hall', (tester) async {
    final locator = ServicesLocator.locator;
    await locator.reset();
    locator.registerSingleton<BookingsRepository>(
      _BookingsRepository([
        _booking(
          id: 1,
          hallId: 'hall-1',
          hallName: 'قاعة النخيل',
          customerName: 'عميل أ',
          date: DateTime(2026, 12, 4),
        ),
        _booking(
          id: 2,
          hallId: 'hall-1',
          hallName: 'قاعة النخيل',
          customerName: 'عميل ب',
          date: DateTime(2026, 12, 8),
        ),
        _booking(
          id: 3,
          hallId: 'hall-2',
          hallName: 'قاعة الماسة',
          customerName: 'عميل ملغي',
          date: DateTime(2026, 12, 1),
          status: BookingLifecycleStatus.cancelled,
        ),
      ]),
    );
    addTearDown(locator.reset);

    await tester.pumpWidget(
      const MaterialApp(home: EventsCalendarScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('قاعة النخيل'), findsOneWidget);
    expect(find.text('عميل أ'), findsOneWidget);
    expect(find.text('عميل ب'), findsOneWidget);
    expect(find.text('عميل ملغي'), findsNothing);
  });
}

class _BookingsRepository extends MockBookingsRepository {
  final List<Booking> bookings;

  _BookingsRepository(this.bookings);

  @override
  Future<List<Booking>> getBookings() async => bookings;
}

Booking _booking({
  required int id,
  required String hallId,
  required String hallName,
  required String customerName,
  required DateTime date,
  BookingLifecycleStatus status = BookingLifecycleStatus.confirmed,
}) {
  return Booking(
    id: id,
    hallId: hallId,
    hallName: hallName,
    customerId: 'customer-$id',
    customerName: customerName,
    customerPhone: '01000000000',
    eventType: 'حفل زفاف',
    eventDate: date,
    timeRange: '18:00–23:00',
    seatsCount: 400,
    hallPrice: 30000,
    services: const [],
    payments: const [],
    status: status,
  );
}
