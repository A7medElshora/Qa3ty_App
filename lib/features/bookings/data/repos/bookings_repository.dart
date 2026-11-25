import 'dart:async';
import 'dart:convert';
import 'package:qa3ty_app/core/helpers/booking_id_registry.dart';
import 'package:qa3ty_app/core/networking/api_constants.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/helpers/booking_financials.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import '../models/booking_model.dart';
import 'package:dio/dio.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(int id);
  Future<List<Booking>> getBookingsByHallId(String hallId);
  Future<int> addBooking(Booking booking);
  Future<void> updateBooking(Booking booking);
  Future<void> addPayment({
    required int bookingId,
    required int amount,
    required String paymentMethod,
    required String receiverName,
    String? note,
  });
  Future<void> toggleServiceStatus(
      int bookingId, String serviceId, BookingServiceStatus newStatus);
  Future<void> addCustomService(int bookingId, ServiceItem service);
  Future<BookingCancellationResult> cancelBooking({
    required int bookingId,
    required String reason,
    required bool refund,
    int refundAmount = 0,
    String refundMethod = 'cash',
    String? refundNotes,
  });
}

class MockBookingsRepository implements BookingsRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<Booking> _bookings = [
    // Booking 1042: Exact specification from Screen 2 & 3
    Booking(
      id: 1042,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_1',
      customerName: 'محمد عبد الله',
      customerPhone: '٠١٠١٢٣٤٥٦٧٨',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 15),
      timeRange: '٨:٠٠ م – ١:٠٠ ص',
      seatsCount: 450,
      hallPrice: 40000,
      dueDate: DateTime(2026, 12, 5),
      otherBookingNotice: 'حجز آخر لنفس العميل في نفس اليوم: قاعة النخيل',
      otherBookingId: 1046,
      eventNotes:
          'يرجى التأكد من تجهيز كوشة الورد الطبيعي وإضاءة الممر الخاصة بالعروسين.',
      setupNotes: 'فتح القاعة للفرق الفنية والمنظمين من الساعة ٤:٠٠ عصراً.',
      internalNotes:
          'العميل من طرف الحاج توفيق – خصم ١٠٪ على الخدمات الإضافية.',
      activityLog: const [
        'تم تسجيل دفعة بقيمة ١٠٬٠٠٠ ج.م بواسطة أحمد (٣ نوفمبر)',
        'تم تسجيل العربون بقيمة ٢٠٬٠٠٠ ج.م بواسطة أحمد (١٠ أكتوبر)',
        'تم إنشاء الحجز وتأكيد الموعد (١٠ أكتوبر)',
        'تم إضافة خدمة الدي جي والزفة للعقد (١٠ أكتوبر)',
      ],
      services: const [
        ServiceItem(
          id: 's1',
          name: 'زفة',
          price: 3000,
          note: 'فرقة استعراضية ٨ أفراد',
          status: BookingServiceStatus.booked,
        ),
        ServiceItem(
          id: 's2',
          name: 'دي جي',
          price: 5000,
          note: 'أحدث التجهيزات الصوتية',
          status: BookingServiceStatus.booked,
        ),
        ServiceItem(
          id: 's3',
          name: 'دبكة',
          price: 4000,
          note: 'غير مضاف للإجمالي بعد',
          status: BookingServiceStatus.notBooked,
        ),
        ServiceItem(
          id: 's4',
          name: 'ليزر شو',
          price: 2500,
          note: 'عروض ليزر متحركة',
          status: BookingServiceStatus.optional,
        ),
        ServiceItem(
          id: 's5',
          name: 'مؤثرات الدخان',
          price: 1500,
          note: 'دخان ثقيل ومدافع ورد',
          status: BookingServiceStatus.optional,
        ),
        ServiceItem(
          id: 's6',
          name: 'إضاءة',
          price: 3500,
          note: 'إضاءة سينمائية وتوزيع ألوان',
          status: BookingServiceStatus.optional,
        ),
      ],
      payments: [
        LedgerEntry(
          id: 'pay_1',
          bookingId: '1042',
          type: 'deposit',
          amount: 20000,
          date: DateTime(2026, 10, 10),
          paymentMethod: 'نقداً',
          receiverName: 'استلمها أحمد',
          note: 'عربون الحجز الأولي',
        ),
        LedgerEntry(
          id: 'pay_2',
          bookingId: '1042',
          type: 'payment',
          amount: 10000,
          date: DateTime(2026, 11, 3),
          paymentMethod: 'تحويل إنستاباي',
          receiverName: 'استلمها أحمد',
          note: 'الدفعة الثانية',
        ),
      ],
    ),

    // Booking 1040: Sarah Mahmoud (Due soon)
    Booking(
      id: 1040,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_2',
      customerName: 'سارة محمود',
      customerPhone: '٠١١٩٨٧٦٥٤٣٢',
      eventType: 'حفل خطوبة',
      eventDate: DateTime(2026, 12, 6),
      timeRange: '٧:٠٠ م – ١٢:٠٠ ص',
      seatsCount: 300,
      hallPrice: 35000,
      dueDate: DateTime(2026, 11, 28),
      services: const [
        ServiceItem(
          id: 's1',
          name: 'دي جي',
          price: 5000,
          status: BookingServiceStatus.booked,
        ),
      ],
      payments: [
        LedgerEntry(
          id: 'pay_3',
          bookingId: '1040',
          type: 'deposit',
          amount: 18000,
          date: DateTime(2026, 10, 5),
          paymentMethod: 'نقداً',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),

    // Booking 1044: Kareem Yasser
    Booking(
      id: 1044,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_3',
      customerName: 'كريم ياسر',
      customerPhone: '٠١٢٣٤٥٦٧٨٩٠',
      eventType: 'كتب كتاب',
      eventDate: DateTime(2026, 12, 24),
      timeRange: '٨:٠٠ م – ١:٠٠ ص',
      seatsCount: 400,
      hallPrice: 30000,
      dueDate: DateTime(2026, 12, 10),
      services: const [
        ServiceItem(
          id: 's1',
          name: 'زفة',
          price: 3000,
          status: BookingServiceStatus.booked,
        ),
      ],
      payments: [
        LedgerEntry(
          id: 'pay_4',
          bookingId: '1044',
          type: 'deposit',
          amount: 24000,
          date: DateTime(2026, 11, 1),
          paymentMethod: 'تحويل إنستاباي',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),

    // Fully paid booking for Day 1
    Booking(
      id: 1038,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_4',
      customerName: 'طارق حسام',
      customerPhone: '٠١٥١١٢٢٣٣٤٤',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 1),
      timeRange: '٨:٠٠ م – ١:٠٠ ص',
      seatsCount: 500,
      hallPrice: 40000,
      services: const [],
      payments: [
        LedgerEntry(
          id: 'pay_5',
          bookingId: '1038',
          type: 'deposit',
          amount: 40000,
          date: DateTime(2026, 9, 15),
          paymentMethod: 'تحويل بنكي',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),

    // Day 11: Two bookings (badge "٢")
    Booking(
      id: 1048,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_5',
      customerName: 'محمود سامي',
      customerPhone: '٠١٠٢٢٣٣٤٤٥٥',
      eventType: 'حفل تخرج',
      eventDate: DateTime(2026, 12, 11),
      timeRange: '١:٠٠ ظ – ٥:٠٠ م',
      seatsCount: 300,
      hallPrice: 25000,
      services: const [],
      payments: [
        LedgerEntry(
          id: 'pay_6',
          bookingId: '1048',
          type: 'payment',
          amount: 25000,
          date: DateTime(2026, 11, 5),
          paymentMethod: 'نقداً',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),
    Booking(
      id: 1049,
      hallId: 'masia',
      hallName: 'قاعة الماسة',
      customerId: 'cust_6',
      customerName: 'رامي عادل',
      customerPhone: '٠١٢٩٩٨٨٧٧٦٦',
      eventType: 'حفل زفاف',
      eventDate: DateTime(2026, 12, 11),
      timeRange: '٨:٠٠ م – ١:٠٠ ص',
      seatsCount: 450,
      hallPrice: 42000,
      services: const [],
      payments: [
        LedgerEntry(
          id: 'pay_7',
          bookingId: '1049',
          type: 'payment',
          amount: 42000,
          date: DateTime(2026, 11, 7),
          paymentMethod: 'نقداً',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),

    // Hall Nakheel booking for customer 1 on same day
    Booking(
      id: 1046,
      hallId: 'nakheel',
      hallName: 'قاعة النخيل',
      customerId: 'cust_1',
      customerName: 'محمد عبد الله',
      customerPhone: '٠١٠١٢٣٤٥٦٧٨',
      eventType: 'عشاء واستقبال خاص',
      eventDate: DateTime(2026, 12, 15),
      timeRange: '٥:٠٠ م – ٨:٠٠ م',
      seatsCount: 200,
      hallPrice: 18000,
      services: const [],
      payments: [
        LedgerEntry(
          id: 'pay_8',
          bookingId: '1046',
          type: 'payment',
          amount: 18000,
          date: DateTime(2026, 10, 12),
          paymentMethod: 'نقداً',
          receiverName: 'استلمها أحمد',
        ),
      ],
    ),
  ];

  @override
  Future<List<Booking>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_bookings);
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Booking>> getBookingsByHallId(String hallId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _bookings.where((b) => b.hallId == hallId).toList();
  }

  @override
  Future<int> addBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _bookings.add(booking);
    return booking.id;
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _bookings[index] = booking;
    }
  }

  @override
  Future<void> addPayment({
    required int bookingId,
    required int amount,
    required String paymentMethod,
    required String receiverName,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final booking = await getBookingById(bookingId);
    if (booking != null) {
      final newPayment = LedgerEntry(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId.toString(),
        type: 'payment',
        amount: amount,
        date: DateTime.now(),
        paymentMethod: paymentMethod,
        receiverName: receiverName,
        note: note,
      );

      final updatedPayments = List<LedgerEntry>.from(booking.payments)
        ..add(newPayment);
      final updatedLog = List<String>.from(booking.activityLog)
        ..insert(0,
            'تم تسجيل دفعة بقيمة $amount ج.م بواسطة $receiverName (${DateTime.now().month}/${DateTime.now().day})');

      final updatedBooking = booking.copyWith(
        payments: updatedPayments,
        activityLog: updatedLog,
      );
      await updateBooking(updatedBooking);
    }
  }

  @override
  Future<void> toggleServiceStatus(
      int bookingId, String serviceId, BookingServiceStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final booking = await getBookingById(bookingId);
    if (booking != null) {
      final updatedServices = booking.services.map((s) {
        if (s.id == serviceId) {
          return s.copyWith(status: newStatus);
        }
        return s;
      }).toList();

      final updatedBooking = booking.copyWith(services: updatedServices);
      await updateBooking(updatedBooking);
    }
  }

  @override
  Future<void> addCustomService(int bookingId, ServiceItem service) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final booking = await getBookingById(bookingId);
    if (booking != null) {
      final updatedServices = List<ServiceItem>.from(booking.services)
        ..add(service);
      final updatedBooking = booking.copyWith(services: updatedServices);
      await updateBooking(updatedBooking);
    }
  }

  @override
  Future<BookingCancellationResult> cancelBooking({
    required int bookingId,
    required String reason,
    required bool refund,
    int refundAmount = 0,
    String refundMethod = 'cash',
    String? refundNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw StateError('لا يمكن إلغاء حجز غير موجود.');
    }
    if (refundAmount < 0 ||
        refundAmount > booking.paidAmount ||
        (!refund && refundAmount != 0) ||
        (refund && refundAmount == 0)) {
      throw ArgumentError('مبلغ الاسترداد غير صالح.');
    }

    final actualRefund = refund ? refundAmount : 0;
    final retainedAmount = booking.paidAmount - actualRefund;
    final refundStatus = actualRefund == 0
        ? 'no_refund'
        : actualRefund == booking.paidAmount
            ? 'full_refund'
            : 'partial_refund';
    final cancelledAt = DateTime.now();
    final updatedLog = List<String>.from(booking.activityLog)
      ..insertAll(0, [
        'تم إلغاء الحجز بتاريخ ${cancelledAt.toIso8601String().substring(0, 10)}. السبب: $reason',
        'المبلغ المسترد: $actualRefund ج.م، والمبلغ المحتفظ به: $retainedAmount ج.م.',
      ]);
    final updatedBooking = booking.copyWith(
      status: BookingLifecycleStatus.cancelled,
      cancellationReason: reason,
      refundAmount: actualRefund,
      retainedAmount: retainedAmount,
      refundStatus: refundStatus,
      refundMethod: refund ? refundMethod : null,
      refundNotes: refund ? refundNotes : null,
      cancelledAt: cancelledAt,
      activityLog: updatedLog,
    );
    await updateBooking(updatedBooking);

    return BookingCancellationResult(
      status: 'cancelled',
      totalPrice: booking.totalAmount,
      totalPaid: booking.paidAmount,
      refundAmount: actualRefund,
      retainedAmount: retainedAmount,
      refundStatus: refundStatus,
      refunded: actualRefund > 0,
      cancelledAt: cancelledAt,
      reason: reason,
      refundMethod: refund ? refundMethod : null,
      refundNotes: refund ? refundNotes : null,
    );
  }
}

class RemoteBookingsRepository implements BookingsRepository {
  final Dio _dio;

  RemoteBookingsRepository(this._dio);

  int _ensureIntId(String uuid) => BookingIdRegistry.ensureLocalId(uuid);

  String _getUuid(int id) =>
      BookingIdRegistry.uuidForLocalId(id) ?? id.toString();

  // Local storage for services not supported by API
  final Map<int, List<ServiceItem>> _bookingServices = {};

  Booking _mapJsonToBooking(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final intId = _ensureIntId(rawId);

    final hallMap = json['halls'] as Map<String, dynamic>?;
    final customerMap = json['customers'] as Map<String, dynamic>?;

    final eventTypeRaw = json['event_type']?.toString();
    String eventTypeArabic = 'حفل زفاف';
    if (eventTypeRaw == 'engagement') {
      eventTypeArabic = 'حفل خطوبة';
    } else if (eventTypeRaw == 'birthday') {
      eventTypeArabic = 'عيد ميلاد';
    } else if (eventTypeRaw == 'conference') {
      eventTypeArabic = 'مؤتمر';
    }

    final dateStr = json['event_date']?.toString() ?? '';
    final eventDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    final startTime = json['start_time']?.toString() ?? '18:00';
    final endTime = json['end_time']?.toString() ?? '23:00';

    final statusRaw = json['status']?.toString();
    final financialSummary =
        json['financial_summary'] as Map<String, dynamic>? ?? const {};
    final cancellation =
        json['cancellation'] as Map<String, dynamic>? ?? const {};
    final total =
        ((financialSummary['total_price'] ?? json['total_price']) as num?)
                ?.round() ??
            0;
    final reportedPaid =
        ((financialSummary['total_paid'] ?? json['total_paid']) as num?)
                ?.round() ??
            0;
    final grossPaid =
        reportedPaid > 0 ? reportedPaid : bookingPaidAmount(json).round();
    final refundAmount = ((financialSummary['refund_amount'] ??
                cancellation['refund_amount']) as num?)
            ?.round() ??
        0;
    final retainedAmount = ((financialSummary['retained_amount'] ??
                cancellation['retained_amount']) as num?)
            ?.round() ??
        (statusRaw == 'cancelled'
            ? (grossPaid - refundAmount).clamp(0, grossPaid).toInt()
            : 0);
    final refundStatus =
        (financialSummary['refund_status'] ?? cancellation['refund_status'])
            ?.toString();
    final refundMethod = cancellation['refund_method']?.toString();
    final refundNotes = cancellation['refund_notes']?.toString();
    final cancelledAt = DateTime.tryParse(
      cancellation['cancelled_at']?.toString() ?? '',
    );
    final cancellationReason = cancellation['reason']?.toString() ??
        json['cancellation_reason']?.toString();
    BookingLifecycleStatus lifecycle = BookingLifecycleStatus.confirmed;
    if (statusRaw == 'pending') {
      lifecycle = BookingLifecycleStatus.tentative;
    } else if (statusRaw == 'completed') {
      lifecycle = BookingLifecycleStatus.completed;
    } else if (statusRaw == 'cancelled') {
      lifecycle = BookingLifecycleStatus.cancelled;
    }
    final cancellationLog = statusRaw == 'cancelled'
        ? [
            if (cancellation['cancelled_at'] != null)
              'تم إلغاء الحجز بتاريخ ${cancellation['cancelled_at']}',
            if (cancellationReason != null) 'سبب الإلغاء: $cancellationReason',
            'المبلغ المسترد: $refundAmount ج.م، والمبلغ المحتفظ به: $retainedAmount ج.م.',
            if (refundMethod != null)
              'طريقة الاسترداد: ${refundMethod == 'bank_transfer' ? 'تحويل بنكي' : refundMethod == 'cash' ? 'نقداً' : refundMethod}',
            if (refundNotes?.isNotEmpty == true)
              'ملاحظات الاسترداد: $refundNotes',
          ]
        : const <String>[];

    final notes = json['notes']?.toString() ?? '';
    const servicesMarker = '__QA3ATY_SERVICES__:';
    List<ServiceItem>? persistedServices;
    var visibleNotes = notes;
    final markerIndex = notes.indexOf(servicesMarker);
    if (markerIndex >= 0) {
      final markerEnd = notes.indexOf('\n', markerIndex);
      final encodedServices = notes
          .substring(markerIndex + servicesMarker.length,
              markerEnd < 0 ? null : markerEnd)
          .trim();
      try {
        final decoded = jsonDecode(encodedServices);
        if (decoded is List) {
          persistedServices = decoded
              .whereType<Map<String, dynamic>>()
              .map(ServiceItem.fromJson)
              .toList();
        }
      } on FormatException {
        persistedServices = null;
      }
      visibleNotes = notes
          .replaceRange(
            markerIndex,
            markerEnd < 0 ? notes.length : markerEnd + 1,
            '',
          )
          .trim();
    }
    final services = _bookingServices[intId] ?? persistedServices ?? const [];
    final hallPrice = ((json['hall_price'] as num?)?.round()) ??
        (total -
                services
                    .where((service) =>
                        service.status == BookingServiceStatus.booked)
                    .fold(0, (sum, service) => sum + service.totalPrice))
            .clamp(0, total)
            .toInt();

    return Booking(
      id: intId,
      hallId: json['hall_id']?.toString() ?? '',
      hallName: hallMap?['name']?.toString() ?? 'القاعة',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: customerMap?['full_name']?.toString() ??
          json['event_name']?.toString() ??
          'عميل',
      customerPhone: customerMap?['phone']?.toString() ?? '',
      eventType: eventTypeArabic,
      eventDate: eventDate,
      timeRange: '$startTime – $endTime',
      seatsCount: 450,
      hallPrice: hallPrice,
      dueDate: eventDate.subtract(const Duration(days: 10)),
      eventNotes: visibleNotes.isEmpty ? null : visibleNotes,
      setupNotes: 'تجهيز الكوشة والإضاءة المبرمجة.',
      internalNotes: 'ملاحظات داخلية للموظفين.',
      activityLog: [
        ...cancellationLog,
        'تم تسجيل دفعة بقيمة $grossPaid ج.م',
        'تم إنشاء الحجز وتأكيد الموعد ($dateStr)',
      ],
      services: services,
      payments: [
        if (grossPaid > 0)
          LedgerEntry(
            id: 'p_initial',
            bookingId: intId.toString(),
            type: 'deposit',
            amount: grossPaid,
            date: eventDate.subtract(const Duration(days: 30)),
            paymentMethod: 'نقداً',
            receiverName: 'الإدارة',
          ),
      ],
      status: lifecycle,
      cancellationReason: cancellationReason,
      refundAmount: refundAmount,
      retainedAmount: retainedAmount,
      refundStatus: refundStatus,
      refundMethod: refundMethod,
      refundNotes: refundNotes,
      cancelledAt: cancelledAt,
    );
  }

  @override
  Future<List<Booking>> getBookings() async {
    try {
      final response = await _dio.get('/bookings');
      List<dynamic> items = [];
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is Map<String, dynamic> &&
            data['data']['items'] is List) {
          items = data['data']['items'] as List<dynamic>;
        } else if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        }
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => _mapJsonToBooking(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    final uuid = _getUuid(id);
    try {
      final response = await _dio.get('/bookings/$uuid');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final bookingJson = data['data'] as Map<String, dynamic>;
          final booking = _mapJsonToBooking(bookingJson);

          // Also fetch payments
          List<LedgerEntry> payments = [];
          try {
            final payRes = await _dio.get('/bookings/$uuid/payments');
            if (payRes.data is Map<String, dynamic> &&
                payRes.data['data'] is List) {
              final payList = payRes.data['data'] as List<dynamic>;
              payments = payList.whereType<Map<String, dynamic>>().map((p) {
                final amount = (p['amount'] as num?)?.round() ?? 0;
                final dateStr = p['payment_date']?.toString();
                final date = dateStr != null
                    ? (DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now())
                    : DateTime.now();
                return LedgerEntry(
                  id: p['id']?.toString() ?? '',
                  bookingId: id.toString(),
                  type: p['payment_method'] == 'cash' ? 'deposit' : 'payment',
                  amount: amount,
                  date: date,
                  paymentMethod:
                      p['payment_method'] == 'cash' ? 'نقداً' : 'تحويل بنكي',
                  receiverName: 'الإدارة',
                  note: p['notes']?.toString(),
                );
              }).toList();
            }
          } catch (_) {}

          return booking.copyWith(
            payments: payments.isNotEmpty ? payments : booking.payments,
          );
        }
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<Booking>> getBookingsByHallId(String hallId) async {
    try {
      final response =
          await _dio.get('/bookings', queryParameters: {'hall_id': hallId});
      List<dynamic> items = [];
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is Map<String, dynamic> &&
            data['data']['items'] is List) {
          items = data['data']['items'] as List<dynamic>;
        } else if (data['data'] is List) {
          items = data['data'] as List<dynamic>;
        }
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => _mapJsonToBooking(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<int> addBooking(Booking booking) async {
    try {
      final dateStr =
          '${booking.eventDate.year}-${booking.eventDate.month.toString().padLeft(2, '0')}-${booking.eventDate.day.toString().padLeft(2, '0')}';
      final selectedServices = booking.services
          .where((service) => service.status == BookingServiceStatus.booked)
          .map((service) =>
              '${service.name}: ${service.totalPrice} ج.م (${service.quantity} × ${service.price} ج.م للوحدة)')
          .join('، ');
      final notes = [
        if (selectedServices.isNotEmpty) 'الخدمات المختارة: $selectedServices',
        if (booking.services.isNotEmpty)
          '__QA3ATY_SERVICES__:${jsonEncode(booking.services.map((service) => service.toJson()).toList())}',
        if (booking.eventNotes?.isNotEmpty == true) booking.eventNotes!,
      ].join('\n');
      final response = await _dio.post(
        '/bookings',
        data: {
          'hall_id': booking.hallId,
          'customer_id': booking.customerId,
          'event_name': '${booking.eventType} ${booking.customerName}',
          'event_type': 'wedding',
          'event_date': dateStr,
          'start_time': '18:00',
          'end_time': '23:00',
          'total_price': booking.totalAmount.toDouble(),
          'advance_payment': booking.paidAmount.toDouble(),
          'status': 'confirmed',
          'drinks_cake_responsibility': 'tenant',
          'notes': notes,
        },
      );
      if (response.data is! Map<String, dynamic>) {
        throw StateError(
            'The server created a booking without returning its ID.');
      }
      final responseData = response.data as Map<String, dynamic>;
      final bookingData = responseData['data'];
      final uuid = bookingData is Map<String, dynamic>
          ? bookingData['id']?.toString()
          : null;
      if (uuid == null || uuid.isEmpty) {
        throw StateError(
            'The server created a booking without returning its ID.');
      }
      final localId = _ensureIntId(uuid);
      _bookingServices[localId] = booking.services;
      return localId;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final uuid = _getUuid(booking.id);
    try {
      await _dio.put(
        '/bookings/$uuid',
        data: {
          'total_price': booking.totalAmount.toDouble(),
          'notes': booking.eventNotes,
        },
      );
      _bookingServices[booking.id] = booking.services;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> addPayment({
    required int bookingId,
    required int amount,
    required String paymentMethod,
    required String receiverName,
    String? note,
  }) async {
    final uuid = _getUuid(bookingId);
    try {
      // Map payment methods: cash is documented, others mapped to cash or logged
      String method = 'cash';
      if (paymentMethod.contains('تحويل') || paymentMethod.contains('بنك')) {
        method = 'bank_transfer';
      }

      await _dio.post(
        '/bookings/$uuid/payments',
        data: {
          'amount': amount.toDouble(),
          'payment_method': method,
          'payment_date': DateTime.now().toUtc().toIso8601String(),
          'notes': note ?? 'دفعة بواسطة $receiverName',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> toggleServiceStatus(
      int bookingId, String serviceId, BookingServiceStatus newStatus) async {
    // TODO(API): Services catalog not in API, maintained locally
    final services = _bookingServices[bookingId] ?? [];
    final idx = services.indexWhere((s) => s.id == serviceId);
    if (idx != -1) {
      services[idx] = services[idx].copyWith(status: newStatus);
      _bookingServices[bookingId] = services;
    }
  }

  @override
  Future<void> addCustomService(int bookingId, ServiceItem service) async {
    // TODO(API): Custom services not in API, maintained locally
    final services = List<ServiceItem>.from(_bookingServices[bookingId] ?? [])
      ..add(service);
    _bookingServices[bookingId] = services;
  }

  @override
  Future<BookingCancellationResult> cancelBooking({
    required int bookingId,
    required String reason,
    required bool refund,
    int refundAmount = 0,
    String refundMethod = 'cash',
    String? refundNotes,
  }) async {
    final uuid = _getUuid(bookingId);
    try {
      final response = await _dio.post(
        ApiConstants.bookingCancel.replaceFirst('{id}', uuid),
        data: {
          'reason': reason,
          'refund': refund,
          if (refund) 'refund_amount': refundAmount.toDouble(),
          if (refund) 'refund_method': refundMethod,
          if (refund && refundNotes?.trim().isNotEmpty == true)
            'refund_notes': refundNotes!.trim(),
        },
      );
      if (response.data is! Map<String, dynamic>) {
        throw StateError('The server cancelled the booking without a result.');
      }

      final responseData = response.data as Map<String, dynamic>;
      final result = responseData['data'];
      if (responseData['success'] != true || result is! Map<String, dynamic>) {
        throw StateError('The server returned an invalid cancellation result.');
      }
      return BookingCancellationResult.fromJson(result);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
