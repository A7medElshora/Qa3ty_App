import 'dart:async';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import '../models/booking_model.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(int id);
  Future<List<Booking>> getBookingsByHallId(String hallId);
  Future<void> addBooking(Booking booking);
  Future<void> updateBooking(Booking booking);
  Future<void> addPayment({
    required int bookingId,
    required int amount,
    required String paymentMethod,
    required String receiverName,
    String? note,
  });
  Future<void> toggleServiceStatus(int bookingId, String serviceId, BookingServiceStatus newStatus);
  Future<void> addCustomService(int bookingId, ServiceItem service);
  Future<void> cancelBooking(int bookingId, String reason, String refundDecision);
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
      eventNotes: 'يرجى التأكد من تجهيز كوشة الورد الطبيعي وإضاءة الممر الخاصة بالعروسين.',
      setupNotes: 'فتح القاعة للفرق الفنية والمنظمين من الساعة ٤:٠٠ عصراً.',
      internalNotes: 'العميل من طرف الحاج توفيق – خصم ١٠٪ على الخدمات الإضافية.',
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
  Future<void> addBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _bookings.add(booking);
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

      final updatedPayments = List<LedgerEntry>.from(booking.payments)..add(newPayment);
      final updatedLog = List<String>.from(booking.activityLog)
        ..insert(0, 'تم تسجيل دفعة بقيمة $amount ج.م بواسطة $receiverName (${DateTime.now().month}/${DateTime.now().day})');

      final updatedBooking = booking.copyWith(
        payments: updatedPayments,
        activityLog: updatedLog,
      );
      await updateBooking(updatedBooking);
    }
  }

  @override
  Future<void> toggleServiceStatus(int bookingId, String serviceId, BookingServiceStatus newStatus) async {
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
      final updatedServices = List<ServiceItem>.from(booking.services)..add(service);
      final updatedBooking = booking.copyWith(services: updatedServices);
      await updateBooking(updatedBooking);
    }
  }

  @override
  Future<void> cancelBooking(int bookingId, String reason, String refundDecision) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final booking = await getBookingById(bookingId);
    if (booking != null) {
      final updatedLog = List<String>.from(booking.activityLog)
        ..insert(0, 'تم إلغاء الحجز بسبب: $reason (قرار العربون: $refundDecision)');
      final updatedBooking = booking.copyWith(
        status: BookingLifecycleStatus.cancelled,
        cancellationReason: reason,
        activityLog: updatedLog,
      );
      await updateBooking(updatedBooking);
    }
  }
}
