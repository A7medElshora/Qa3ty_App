import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import 'package:qa3ty_app/features/bookings/data/repos/bookings_repository.dart';

const _bookingUuid = 'b3e64817-640a-4a25-9fc8-d218d6e32635';
const _hallUuid = 'c0e1a33e-949e-48ba-9a01-0bd66ba7218c';
const _customerUuid = '3f7ff4e1-d349-439a-a23c-2615c01e1b5d';

void main() {
  test('cancellation sends refund details and returns the financial summary',
      () async {
    final adapter = _CancellationResponseAdapter(totalPaid: 5000);
    final repository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final booking = (await repository.getBookings()).single;

    final result = await repository.cancelBooking(
      bookingId: booking.id,
      reason: 'اعتذار العميل لظروف خاصة',
      refund: true,
      refundAmount: 3000,
      refundMethod: 'cash',
      refundNotes: 'تم تسليم المبلغ للعميل',
    );

    expect(adapter.requestUri, '/bookings/$_bookingUuid/cancel');
    expect(adapter.requestBody, {
      'reason': 'اعتذار العميل لظروف خاصة',
      'refund': true,
      'refund_amount': 3000.0,
      'refund_method': 'cash',
      'refund_notes': 'تم تسليم المبلغ للعميل',
    });
    expect(result.status, 'cancelled');
    expect(result.totalPaid, 5000);
    expect(result.refundAmount, 3000);
    expect(result.retainedAmount, 2000);
    expect(result.refundStatus, 'partial_refund');
    expect(result.refunded, isTrue);

    final cancelledBooking = await repository.getBookingById(booking.id);
    expect(cancelledBooking?.status, BookingLifecycleStatus.cancelled);
    expect(cancelledBooking?.cancellationReason, 'اعتذار العميل لظروف خاصة');
    expect(cancelledBooking?.refundAmount, 3000);
    expect(cancelledBooking?.retainedAmount, 2000);
    expect(cancelledBooking?.paidAmount, 2000);
    expect(cancelledBooking?.refundMethod, 'cash');
    expect(cancelledBooking?.refundNotes, 'تم تسليم المبلغ للعميل');
    expect(
      cancelledBooking?.activityLog,
      contains('ملاحظات الاسترداد: تم تسليم المبلغ للعميل'),
    );
  });

  test('unpaid booking cancellation sends no refund fields', () async {
    final adapter = _CancellationResponseAdapter(totalPaid: 0);
    final repository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final booking = (await repository.getBookings()).single;

    final result = await repository.cancelBooking(
      bookingId: booking.id,
      reason: 'اعتذار العميل',
      refund: false,
    );

    expect(adapter.requestBody, {
      'reason': 'اعتذار العميل',
      'refund': false,
    });
    expect(result.totalPaid, 0);
    expect(result.refundAmount, 0);
    expect(result.retainedAmount, 0);
  });
}

class _CancellationResponseAdapter implements HttpClientAdapter {
  final int totalPaid;
  bool _cancelled = false;
  Map<String, dynamic>? requestBody;
  String? requestUri;

  _CancellationResponseAdapter({required this.totalPaid});

  Map<String, dynamic> get _financialSummary {
    final refundAmount =
        _cancelled ? (requestBody?['refund_amount'] as num?)?.round() ?? 0 : 0;
    return {
      'total_price': 30000,
      'total_paid': totalPaid,
      'refund_amount': refundAmount,
      'retained_amount': totalPaid - refundAmount,
      'refund_status': refundAmount == 0
          ? 'no_refund'
          : refundAmount == totalPaid
              ? 'full_refund'
              : 'partial_refund',
    };
  }

  Map<String, dynamic> get _cancellation => {
        'cancelled_at': '2026-11-23T10:00:00Z',
        'reason': requestBody?['reason'] ?? 'اعتذار العميل',
        'total_paid': totalPaid,
        'refunded': _financialSummary['refund_amount'] > 0,
        'refund_amount': _financialSummary['refund_amount'],
        'retained_amount': _financialSummary['retained_amount'],
        'refund_method': requestBody?['refund_method'],
        'refund_status': _financialSummary['refund_status'],
        'refund_notes': requestBody?['refund_notes'],
      };

  Map<String, dynamic> get _booking => {
        'id': _bookingUuid,
        'hall_id': _hallUuid,
        'customer_id': _customerUuid,
        'event_name': 'حفل زفاف أحمد ومريم',
        'event_type': 'wedding',
        'event_date': '2026-11-25',
        'start_time': '18:00',
        'end_time': '23:00',
        'total_price': 30000,
        'total_paid': totalPaid,
        'advance_payment': totalPaid,
        'remaining_balance': 30000 - totalPaid,
        'status': _cancelled ? 'cancelled' : 'confirmed',
        if (_cancelled) 'financial_summary': _financialSummary,
        if (_cancelled) 'cancellation': _cancellation,
      };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUri = options.uri.path;
    if (options.method == 'POST') {
      final bytes = await requestStream!.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      requestBody = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _cancelled = true;
      return _response({
        'success': true,
        'data': {
          ..._booking,
          'financial_summary': _financialSummary,
          'cancellation': _cancellation,
        },
      }, 200);
    }

    if (options.uri.path == '/bookings') {
      return _response({
        'success': true,
        'data': {
          'items': [_booking],
        },
      }, 200);
    }
    if (options.uri.path.endsWith('/payments')) {
      return _response({
        'success': true,
        'data': [
          if (totalPaid > 0)
            {
              'id': 'payment-id',
              'amount': totalPaid,
              'payment_date': '2026-11-20',
              'payment_method': 'cash',
            }
        ],
      }, 200);
    }
    if (options.uri.path == '/bookings/$_bookingUuid') {
      return _response({
        'success': true,
        'data': _booking,
      }, 200);
    }

    return _response({'success': false}, 404);
  }

  ResponseBody _response(Map<String, dynamic> json, int statusCode) {
    return ResponseBody.fromString(
      jsonEncode(json),
      statusCode,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
