import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/helpers/phone_number_normalizer.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import 'package:qa3ty_app/features/bookings/data/repos/bookings_repository.dart';
import 'package:qa3ty_app/features/bookings/presentation/cubits/booking_details_cubit.dart';

const _bookingUuid = 'b3e64817-640a-4a25-9fc8-d218d6e32635';

void main() {
  test('service unit prices and quantities are submitted and restored',
      () async {
    final adapter = _BookingSubmissionAdapter();
    final repository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final booking = Booking(
      id: 1001,
      hallId: 'hall-uuid',
      hallName: 'قاعة الاختبار',
      customerId: 'customer-uuid',
      customerName: 'محمد',
      customerPhone: '01000000000',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 24),
      timeRange: '18:00–23:00',
      seatsCount: 300,
      hallPrice: 40000,
      services: const [
        ServiceItem(
          id: 'cake',
          name: 'الجاتوه',
          price: 5000,
          quantity: 3,
          status: BookingServiceStatus.booked,
        ),
        ServiceItem(
          id: 'drinks',
          name: 'المشروبات',
          price: 1000,
          quantity: 4,
          status: BookingServiceStatus.booked,
        ),
      ],
      payments: const [],
    );

    final savedId = await repository.addBooking(booking);
    final payload = adapter.submittedBooking!;
    expect(payload['total_price'], 59000.0);
    expect(payload['notes'], contains('الجاتوه: 15000 ج.م'));
    expect(payload['notes'], contains('المشروبات: 4000 ج.م'));
    expect(payload['notes'], contains('"quantity":3'));
    expect(payload['notes'], contains('"quantity":4'));

    final restored = (await repository.getBookings()).single;
    expect(restored.id, savedId);
    expect(restored.services.map((service) => service.quantity), [3, 4]);
    expect(restored.services.map((service) => service.price), [5000, 1000]);
    expect(restored.bookedServicesTotal, 19000);
    expect(restored.totalAmount, 59000);
  });

  test('successful cancellation updates details without a follow-up read',
      () async {
    final repository = _CountingMockBookingsRepository();
    final booking = (await repository.getBookings()).first;
    final cubit = BookingDetailsCubit(repository);

    await cubit.loadBooking(booking.id);
    await cubit.cancelBooking(reason: 'اعتذار العميل', refund: false);

    expect(repository.detailReads, 2);
    final state = cubit.state as BookingDetailsLoaded;
    expect(state.booking.status, BookingLifecycleStatus.cancelled);
    expect(state.booking.cancellationReason, 'اعتذار العميل');
    await cubit.close();
  });

  test('receipt share text contains the calculated service total and balance',
      () {
    final booking = Booking(
      id: 1001,
      hallId: 'hall-uuid',
      hallName: 'قاعة الاختبار',
      customerId: 'customer-uuid',
      customerName: 'محمد',
      customerPhone: '01000000000',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 24),
      timeRange: '18:00–23:00',
      seatsCount: 300,
      hallPrice: 40000,
      services: const [
        ServiceItem(
          id: 'cake',
          name: 'الجاتوه',
          price: 5000,
          quantity: 3,
          status: BookingServiceStatus.booked,
        ),
      ],
      payments: [
        LedgerEntry(
          id: 'payment-1',
          bookingId: '1001',
          type: 'deposit',
          amount: 15000,
          date: DateTime(2026, 11, 20),
          paymentMethod: 'نقداً',
          receiverName: 'الإدارة',
          note: 'عربون',
        ),
      ],
    );

    final receipt = buildBookingReceiptText(booking);

    expect(receipt, contains('الجاتوه: 3 × 5000 = 15000 ج.م'));
    expect(receipt, contains('الدفعات:'));
    expect(receipt, contains('15000 ج.م · نقداً · 2026-11-20 · عربون'));
    expect(receipt, contains('إجمالي العقد: 55000 ج.م'));
    expect(receipt, contains('المتبقي: 40000 ج.م'));
  });

  test('WhatsApp phone normalization preserves country codes and Arabic digits',
      () {
    expect(normalizePhoneNumberForWhatsApp('٠١٠١٢٣٤٥٦٧٨'), '201012345678');
    expect(normalizePhoneNumberForWhatsApp('+1 (555) 010-1234'), '15550101234');
  });
}

class _CountingMockBookingsRepository extends MockBookingsRepository {
  int detailReads = 0;

  @override
  Future<Booking?> getBookingById(int id) {
    detailReads++;
    return super.getBookingById(id);
  }
}

class _BookingSubmissionAdapter implements HttpClientAdapter {
  Map<String, dynamic>? submittedBooking;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      final bytes = await requestStream!.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      submittedBooking = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return _response({
        'success': true,
        'data': {'id': _bookingUuid}
      }, 201);
    }

    if (options.uri.path == '/bookings') {
      return _response({
        'success': true,
        'data': {
          'items': [
            {
              'id': _bookingUuid,
              'hall_id': 'hall-uuid',
              'customer_id': 'customer-uuid',
              'event_date': '2026-12-24',
              'total_price': 59000,
              'status': 'confirmed',
              'notes': submittedBooking?['notes'] ?? '',
            }
          ],
        },
      }, 200);
    }

    return _response({'success': false}, 404);
  }

  ResponseBody _response(Map<String, dynamic> body, int statusCode) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
