import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/core/helpers/phone_number_normalizer.dart';
import 'package:qa3ty_app/features/calendar/data/repos/calendar_repository.dart';
import 'package:qa3ty_app/features/calendar/presentation/cubits/calendar_cubit.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import 'package:qa3ty_app/features/bookings/data/repos/bookings_repository.dart';
import 'package:qa3ty_app/features/customers/data/models/customer_model.dart';
import 'package:qa3ty_app/features/halls/data/repos/halls_repository.dart';
import 'package:qa3ty_app/features/workers/data/models/worker_model.dart';

const _customerId = 'c0e1a33e-949e-48ba-9a01-0bd66ba7218c';
const _hallId = '637d8866-6490-4244-823e-d9277dc70c3b';
const _bookingUuid = '3f7ff4e1-d349-439a-a23c-2615c01e1b5d';

void main() {
  test('normalizes local and international caller numbers to the same value',
      () {
    expect(normalizePhoneNumber('+20 10 5081 5073'), '1050815073');
    expect(normalizePhoneNumber('٠١٠٥٠٨١٥٠٧٣'), '1050815073');
    expect(phoneNumbersMatch('+20 10 5081 5073', '01050815073'), isTrue);
    expect(phoneNumbersMatch('01050815073', '01150815073'), isFalse);
  });

  test('caller lookup matches a customer stored with a local phone number',
      () async {
    final repository = RemoteCustomersRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = _CustomerBookingsResponseAdapter(),
    );

    final customer = await repository.findCustomerByPhone('+20 10 0000 0000');

    expect(customer?.id, _customerId);
  });

  test('caller lookup falls back to the full customer list', () async {
    final repository = RemoteCustomersRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = _FallbackCallerResponseAdapter(),
    );

    final customer = await repository.findCustomerByPhone('+20 10 0000 0000');

    expect(customer?.id, _customerId);
  });

  test('customer creation returns the server-assigned UUID', () async {
    final adapter = _JsonResponseAdapter(
      '{"success":true,"data":{"id":"$_customerId","full_name":"محمد","phone":"01000000000"}}',
    );
    final repository = RemoteCustomersRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final customer = await repository.addCustomer(
      const Customer(
        id: '',
        name: 'محمد',
        phone: '01000000000',
        totalBookings: 0,
        totalSpent: 0,
      ),
    );

    expect(customer.id, _customerId);
  });

  test('customer totals include paid booking advances from the booking list',
      () async {
    final adapter = _CustomerBookingsResponseAdapter();
    final repository = RemoteCustomersRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final customers = await repository.getCustomers();

    expect(customers, hasLength(1));
    expect(customers.single.totalBookings, 1);
    expect(customers.single.totalSpent, 1200);
  });

  test('booking submits the real customer UUID and selected services',
      () async {
    final adapter = _JsonResponseAdapter(
      '{"success":true,"data":{"id":"$_bookingUuid"}}',
    );
    final repository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final booking = Booking(
      id: 1001,
      hallId: _hallId,
      hallName: 'قاعة الاختبار',
      customerId: _customerId,
      customerName: 'محمد',
      customerPhone: '01000000000',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 24),
      timeRange: '٦:٠٠ م – ١١:٠٠ م',
      seatsCount: 300,
      hallPrice: 40000,
      services: const [
        ServiceItem(
          id: 'cake',
          name: 'الجاتوه',
          price: 5000,
          status: BookingServiceStatus.booked,
        ),
        ServiceItem(
          id: 'drinks',
          name: 'المشروبات',
          price: 2000,
          status: BookingServiceStatus.booked,
        ),
      ],
      payments: const [],
      eventNotes: 'ملاحظات الحجز',
    );

    final bookingId = await repository.addBooking(booking);

    final payload = jsonDecode(adapter.requestBody!) as Map<String, dynamic>;
    expect(payload['customer_id'], _customerId);
    expect(payload.containsKey('customer'), isFalse);
    expect(payload['total_price'], 47000.0);
    expect(payload['notes'], contains('الجاتوه: 5000 ج.م'));
    expect(payload['notes'], contains('المشروبات: 2000 ج.م'));
    expect(payload['notes'], contains('ملاحظات الحجز'));

    await repository.addPayment(
      bookingId: bookingId,
      amount: 5000,
      paymentMethod: 'نقداً',
      receiverName: 'أحمد',
    );
    expect(adapter.requestUri, '/bookings/$_bookingUuid/payments');
  });

  test('booking sends empty notes as a string when none were entered',
      () async {
    final adapter = _JsonResponseAdapter(
      '{"success":true,"data":{"id":"$_bookingUuid"}}',
    );
    final repository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final booking = Booking(
      id: 1002,
      hallId: _hallId,
      hallName: 'قاعة الاختبار',
      customerId: _customerId,
      customerName: 'محمد',
      customerPhone: '01000000000',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 24),
      timeRange: '٦:٠٠ م – ١١:٠٠ م',
      seatsCount: 300,
      hallPrice: 40000,
      services: const [],
      payments: const [],
    );

    await repository.addBooking(booking);

    final payload = jsonDecode(adapter.requestBody!) as Map<String, dynamic>;
    expect(payload['notes'], '');
    expect(payload['notes'], isA<String>());
  });

  test('calendar reload shows the event as deposit after cache invalidation',
      () async {
    final adapter = _JsonResponseAdapter('{"success":true,"data":[]}');
    final repository = RemoteCalendarRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );
    final month = DateTime(2026, 12, 1);

    final initialDays = await repository.getCalendarDays(
      hallId: _hallId,
      month: month,
    );
    expect(initialDays[23].status, DayStatus.available);

    adapter.responseJson = '''
      {"success":true,"data":[{
        "id":"$_bookingUuid",
        "event_date":"2026-12-24",
        "total_price":46500,
        "advance_payment":5000,
        "total_paid":0,
        "remaining_balance":0,
        "status":"confirmed"
      }]}
    ''';
    repository.invalidateCache(hallId: _hallId);

    final refreshedDays = await repository.getCalendarDays(
      hallId: _hallId,
      month: month,
    );
    expect(refreshedDays[23].status, DayStatus.deposit);
    expect(refreshedDays[23].paidAmount, 5000);
    expect(refreshedDays[23].remainingAmount, 41500);
  });

  test('calendar booking ids resolve to the booking UUID for details requests',
      () async {
    final calendarRepository = RemoteCalendarRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = _JsonResponseAdapter('''
          {"success":true,"data":[{
            "id":"$_bookingUuid",
            "event_date":"2026-12-24",
            "total_price":20000,
            "total_paid":5000,
            "status":"confirmed"
          }]}
        '''),
    );
    final calendarDays = await calendarRepository.getCalendarDays(
      hallId: _hallId,
      month: DateTime(2026, 12, 1),
    );
    final bookingId = calendarDays[23].bookingId!;

    final bookingAdapter = _BookingDetailsResponseAdapter();
    final bookingsRepository = RemoteBookingsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = bookingAdapter,
    );

    final booking = await bookingsRepository.getBookingById(bookingId);

    expect(booking, isNotNull);
    expect(bookingAdapter.requestPaths, [
      '/bookings/$_bookingUuid',
      '/bookings/$_bookingUuid/payments',
    ]);
  });

  test('calendar defaults to the current date', () async {
    final cubit = CalendarCubit(MockCalendarRepository());

    await cubit.loadCalendar();

    final state = cubit.state as CalendarLoaded;
    final today = DateTime.now();
    expect(state.currentMonth.year, today.year);
    expect(state.currentMonth.month, today.month);
    expect(state.selectedDay, today.day);
    await cubit.close();
  });

  test('remaining payments include upcoming bookings with stale zero balance',
      () async {
    final eventDate = DateTime.now().add(const Duration(days: 30));
    final date = eventDate.toIso8601String().substring(0, 10);
    final adapter = _JsonResponseAdapter('''
      {"success":true,"data":[{
        "id":"$_bookingUuid",
        "event_date":"$date",
        "event_name":"حفل قادم",
        "total_price":46000,
        "advance_payment":5000,
        "total_paid":0,
        "remaining_balance":0,
        "status":"confirmed"
      }]}
    ''');
    final repository = RemoteCalendarRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final payments = await repository.getRemainingPayments(hallId: _hallId);

    expect(payments, hasLength(1));
    expect(payments.single.remainingAmount, 41000);
  });

  test('hall card balance includes upcoming booking due amounts', () async {
    final eventDate = DateTime.now().add(const Duration(days: 30));
    final adapter = _HallsResponseAdapter(
      eventDate.toIso8601String().substring(0, 10),
    );
    final repository = RemoteHallsRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    final halls = await repository.getHalls();

    expect(halls.single.weekRemainingAmount, 0);
    expect(halls.single.upcomingRemainingAmount, 40000);
  });

  test('worker payment appears in totals and reduces current monthly balance',
      () async {
    final adapter = _WorkerPaymentsResponseAdapter();
    final repository = RemoteWorkersRepository(
      Dio(BaseOptions(baseUrl: 'https://test.example'))
        ..httpClientAdapter = adapter,
    );

    await repository.recordTransaction(
      WorkerTransaction(
        id: 'local-payment',
        workerId: _workerId,
        type: WorkerTransactionType.payment,
        amount: 1200,
        date: DateTime.now(),
      ),
    );
    final workers = await repository.getWorkers();

    expect(workers.single.totalPaid, 1200);
    expect(workers.single.currentBalance, 300);
  });
}

class _JsonResponseAdapter implements HttpClientAdapter {
  String responseJson;
  String? requestBody;
  String? requestUri;

  _JsonResponseAdapter(this.responseJson);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUri = options.uri.path;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      requestBody = utf8.decode(bytes);
    }
    return ResponseBody.fromString(
      responseJson,
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _BookingDetailsResponseAdapter implements HttpClientAdapter {
  final List<String> requestPaths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPaths.add(options.uri.path);
    final responseJson = options.uri.path.endsWith('/payments')
        ? '{"success":true,"data":[]}'
        : '''
          {"success":true,"data":{
            "id":"$_bookingUuid",
            "hall_id":"$_hallId",
            "customer_id":"$_customerId",
            "event_date":"2026-12-24",
            "total_price":20000,
            "total_paid":5000,
            "status":"confirmed"
          }}
        ''';
    return ResponseBody.fromString(
      responseJson,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _HallsResponseAdapter implements HttpClientAdapter {
  final String eventDate;

  _HallsResponseAdapter(this.eventDate);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final responseJson = options.uri.path == '/halls'
        ? jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': _hallId,
                  'name': 'قاعة الاختبار',
                  'address': 'طنطا',
                  'capacity': 300,
                  'is_active': true,
                }
              ],
              'pagination': {'total': 1, 'limit': 50, 'offset': 0},
            },
          })
        : jsonEncode({
            'success': true,
            'data': [
              {
                'id': _bookingUuid,
                'event_date': eventDate,
                'total_price': 50000,
                'advance_payment': 10000,
                'total_paid': 0,
                'remaining_balance': 0,
                'status': 'confirmed',
              }
            ],
          });

    return ResponseBody.fromString(
      responseJson,
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FallbackCallerResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final items = options.uri.queryParameters.containsKey('search')
        ? <Map<String, dynamic>>[]
        : [
            {
              'id': _customerId,
              'full_name': 'عميل الاختبار',
              'phone': '01000000000',
            }
          ];
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'items': items},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CustomerBookingsResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final responseJson = options.uri.path == '/customers'
        ? jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': _customerId,
                  'full_name': 'عميل الاختبار',
                  'phone': '01000000000',
                  'bookings_count': 0,
                  'total_spent': 0,
                }
              ],
            },
          })
        : jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': _bookingUuid,
                  'customer_id': _customerId,
                  'event_date': '2026-11-23',
                  'total_price': 5000,
                  'advance_payment': 1200,
                  'total_paid': 0,
                  'remaining_balance': 3800,
                  'status': 'confirmed',
                }
              ],
            },
          });
    return ResponseBody.fromString(
      responseJson,
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _workerId = 'b0868f75-a60e-4fb7-a7b1-5850f187dcaf';

class _WorkerPaymentsResponseAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> _payments = [];

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
      final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final payment = {
        'id': 'server-payment-id',
        'worker_id': _workerId,
        ...body,
      };
      _payments.add(payment);
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'data': payment}),
        201,
        headers: {
          'content-type': ['application/json']
        },
      );
    }

    final responseJson = options.uri.path == '/workers'
        ? jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': _workerId,
                  'full_name': 'عامل الاختبار',
                  'phone': '01020304050',
                  'job_title': 'مشرف صالة',
                  'salary_type': 'fixed',
                  'fixed_salary': 1500,
                  'status': 'active',
                }
              ],
            },
          })
        : jsonEncode({'success': true, 'data': _payments});
    return ResponseBody.fromString(
      responseJson,
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
