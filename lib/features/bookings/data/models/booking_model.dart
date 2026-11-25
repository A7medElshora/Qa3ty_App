import 'package:qa3ty_app/core/utils/widgets/chips.dart';

enum BookingPaymentStatus {
  unpaid,
  depositOnly,
  partiallyPaid,
  fullyPaid,
}

enum BookingLifecycleStatus {
  tentative,
  confirmed,
  completed,
  cancelled,
}

class LedgerEntry {
  final String id;
  final String bookingId;
  final String type; // 'deposit', 'payment', 'refund', 'charge'
  final int amount; // in EGP
  final DateTime date;
  final String paymentMethod; // نقداً, تحويل إنستاباي, etc.
  final String receiverName;
  final String? note;

  const LedgerEntry({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.receiverName,
    this.note,
  });

  LedgerEntry copyWith({
    String? id,
    String? bookingId,
    String? type,
    int? amount,
    DateTime? date,
    String? paymentMethod,
    String? receiverName,
    String? note,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiverName: receiverName ?? this.receiverName,
      note: note ?? this.note,
    );
  }
}

class BookingCancellationResult {
  final String status;
  final int totalPrice;
  final int totalPaid;
  final int refundAmount;
  final int retainedAmount;
  final String? refundStatus;
  final bool refunded;
  final DateTime? cancelledAt;
  final String? reason;
  final String? refundMethod;
  final String? refundNotes;

  const BookingCancellationResult({
    required this.status,
    required this.totalPrice,
    required this.totalPaid,
    required this.refundAmount,
    required this.retainedAmount,
    this.refundStatus,
    required this.refunded,
    this.cancelledAt,
    this.reason,
    this.refundMethod,
    this.refundNotes,
  });

  factory BookingCancellationResult.fromJson(Map<String, dynamic> json) {
    final financialSummary =
        json['financial_summary'] as Map<String, dynamic>? ?? const {};
    final cancellation =
        json['cancellation'] as Map<String, dynamic>? ?? const {};
    int amount(dynamic value) => (value as num?)?.round() ?? 0;
    final totalPaid =
        amount(financialSummary['total_paid'] ?? cancellation['total_paid']);
    final refundAmount = amount(
        financialSummary['refund_amount'] ?? cancellation['refund_amount']);
    final retainedAmount = amount(
      financialSummary['retained_amount'] ??
          cancellation['retained_amount'] ??
          totalPaid - refundAmount,
    );

    return BookingCancellationResult(
      status: json['status']?.toString() ?? 'cancelled',
      totalPrice: amount(financialSummary['total_price']),
      totalPaid: totalPaid,
      refundAmount: refundAmount,
      retainedAmount: retainedAmount,
      refundStatus:
          (financialSummary['refund_status'] ?? cancellation['refund_status'])
              ?.toString(),
      refunded: cancellation['refunded'] == true || refundAmount > 0,
      cancelledAt: DateTime.tryParse(
        cancellation['cancelled_at']?.toString() ?? '',
      ),
      reason: (cancellation['reason'] ?? json['reason'])?.toString(),
      refundMethod: cancellation['refund_method']?.toString(),
      refundNotes: cancellation['refund_notes']?.toString(),
    );
  }
}

class ServiceItem {
  final String id;
  final String name;

  /// Unit price. The line total is [price] multiplied by [quantity].
  final int price;
  final int quantity;
  final String? note;
  final BookingServiceStatus status;
  final bool isCustom;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.note,
    required this.status,
    this.isCustom = false,
  });

  int get totalPrice => price * quantity;

  ServiceItem copyWith({
    String? id,
    String? name,
    int? price,
    int? quantity,
    String? note,
    BookingServiceStatus? status,
    bool? isCustom,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      status: status ?? this.status,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit_price': price,
        'quantity': quantity,
        'status': status.name,
        'note': note,
        'is_custom': isCustom,
      };

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString();
    final status = BookingServiceStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => BookingServiceStatus.booked,
    );
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['unit_price'] as num?)?.round() ??
          (json['price'] as num?)?.round() ??
          0,
      quantity: (json['quantity'] as num?)?.round() ?? 1,
      note: json['note']?.toString(),
      status: status,
      isCustom: json['is_custom'] == true,
    );
  }
}

class Booking {
  final int id; // e.g. 1042
  final String hallId;
  final String hallName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String eventType;
  final DateTime eventDate;
  final String timeRange;
  final int seatsCount;
  final int hallPrice;
  final List<ServiceItem> services;
  final List<LedgerEntry> payments;
  final BookingLifecycleStatus status;
  final DateTime? dueDate;
  final String? eventNotes;
  final String? setupNotes;
  final String? internalNotes;
  final String? otherBookingNotice;
  final int? otherBookingId;
  final List<String> activityLog;
  final String? cancellationReason;
  final int refundAmount;
  final int retainedAmount;
  final String? refundStatus;
  final String? refundMethod;
  final String? refundNotes;
  final DateTime? cancelledAt;

  const Booking({
    required this.id,
    required this.hallId,
    required this.hallName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.eventType,
    required this.eventDate,
    required this.timeRange,
    required this.seatsCount,
    required this.hallPrice,
    required this.services,
    required this.payments,
    this.status = BookingLifecycleStatus.confirmed,
    this.dueDate,
    this.eventNotes,
    this.setupNotes,
    this.internalNotes,
    this.otherBookingNotice,
    this.otherBookingId,
    this.activityLog = const [],
    this.cancellationReason,
    this.refundAmount = 0,
    this.retainedAmount = 0,
    this.refundStatus,
    this.refundMethod,
    this.refundNotes,
    this.cancelledAt,
  });

  /// Total services booked (only status == booked count into total charges)
  int get bookedServicesTotal {
    return services
        .where((s) => s.status == BookingServiceStatus.booked)
        .fold(0, (sum, s) => sum + s.totalPrice);
  }

  /// Total charges = hall price + booked services
  int get totalAmount => hallPrice + bookedServicesTotal;

  /// Total payments recorded
  int get paidAmount {
    if (status == BookingLifecycleStatus.cancelled) return retainedAmount;
    return payments
        .where((p) => p.type == 'payment' || p.type == 'deposit')
        .fold(0, (sum, p) => sum + p.amount);
  }

  /// Remaining amount = charges - payments
  int get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Progress ratio
  double get paymentProgress {
    if (totalAmount <= 0) return 1.0;
    return (paidAmount / totalAmount).clamp(0.0, 1.0);
  }

  /// Payment status computed dynamically
  BookingPaymentStatus get paymentStatus {
    if (paidAmount <= 0) return BookingPaymentStatus.unpaid;
    if (paidAmount >= totalAmount) return BookingPaymentStatus.fullyPaid;
    if (payments.length == 1 && payments.first.type == 'deposit') {
      return BookingPaymentStatus.depositOnly;
    }
    return BookingPaymentStatus.partiallyPaid;
  }

  Booking copyWith({
    int? id,
    String? hallId,
    String? hallName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? eventType,
    DateTime? eventDate,
    String? timeRange,
    int? seatsCount,
    int? hallPrice,
    List<ServiceItem>? services,
    List<LedgerEntry>? payments,
    BookingLifecycleStatus? status,
    DateTime? dueDate,
    String? eventNotes,
    String? setupNotes,
    String? internalNotes,
    String? otherBookingNotice,
    int? otherBookingId,
    List<String>? activityLog,
    String? cancellationReason,
    int? refundAmount,
    int? retainedAmount,
    String? refundStatus,
    String? refundMethod,
    String? refundNotes,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      timeRange: timeRange ?? this.timeRange,
      seatsCount: seatsCount ?? this.seatsCount,
      hallPrice: hallPrice ?? this.hallPrice,
      services: services ?? this.services,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      eventNotes: eventNotes ?? this.eventNotes,
      setupNotes: setupNotes ?? this.setupNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      otherBookingNotice: otherBookingNotice ?? this.otherBookingNotice,
      otherBookingId: otherBookingId ?? this.otherBookingId,
      activityLog: activityLog ?? this.activityLog,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundAmount: refundAmount ?? this.refundAmount,
      retainedAmount: retainedAmount ?? this.retainedAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      refundMethod: refundMethod ?? this.refundMethod,
      refundNotes: refundNotes ?? this.refundNotes,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

String buildBookingReceiptText(Booking booking) {
  final services = booking.services
      .where((service) => service.status == BookingServiceStatus.booked)
      .map((service) {
    return '${service.name}: ${service.quantity} × ${service.price} = ${service.totalPrice} ج.م';
  }).join('\n');
  final payments = List<LedgerEntry>.from(booking.payments)
    ..sort((a, b) => a.date.compareTo(b.date));
  final paymentsText = payments.map((payment) {
    final type = payment.type == 'refund' ? 'استرداد' : 'دفعة';
    return '$type ${payment.amount} ج.م · ${payment.paymentMethod} · '
        '${payment.date.toIso8601String().substring(0, 10)}'
        '${payment.note?.isNotEmpty == true ? ' · ${payment.note}' : ''}';
  }).join('\n');

  return [
    'قاعات قاعتي | ${booking.hallName}',
    'إيصال سداد رقم #${booking.id}',
    'اسم العميل: ${booking.customerName}',
    'رقم العميل: ${booking.customerPhone}',
    'المناسبة: ${booking.eventType}',
    'تاريخ الفعالية: ${booking.eventDate.toIso8601String().substring(0, 10)}',
    'سعر القاعة: ${booking.hallPrice} ج.م',
    if (services.isNotEmpty) 'الخدمات:\n$services',
    'إجمالي العقد: ${booking.totalAmount} ج.م',
    if (paymentsText.isNotEmpty) 'الدفعات:\n$paymentsText',
    'إجمالي المسدد: ${booking.paidAmount} ج.م',
    'المتبقي: ${booking.remainingAmount} ج.م',
  ].join('\n');
}
