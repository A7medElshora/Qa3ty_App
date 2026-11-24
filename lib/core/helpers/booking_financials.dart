double bookingPaidAmount(Map<String, dynamic> booking) {
  final reportedPaid = (booking['total_paid'] as num?)?.toDouble() ?? 0;
  final payments = booking['payments'] as List<dynamic>?;
  if (reportedPaid <= 0 && payments != null && payments.isNotEmpty) {
    final paymentTotal =
        payments.whereType<Map<String, dynamic>>().fold<double>(
              0,
              (total, payment) =>
                  total + ((payment['amount'] as num?)?.toDouble() ?? 0),
            );
    if (paymentTotal > 0) return paymentTotal;
  }

  final advancePayment = (booking['advance_payment'] as num?)?.toDouble() ?? 0;
  return reportedPaid > 0 ? reportedPaid : advancePayment;
}

double bookingRemainingAmount(Map<String, dynamic> booking) {
  final total = (booking['total_price'] as num?)?.toDouble() ?? 0;
  final paid = bookingPaidAmount(booking);
  final reportedRemaining = (booking['remaining_balance'] as num?)?.toDouble();

  if (reportedRemaining != null && !(reportedRemaining <= 0 && total > paid)) {
    return reportedRemaining > 0 ? reportedRemaining : 0;
  }

  final calculatedRemaining = total - paid;
  return calculatedRemaining > 0 ? calculatedRemaining : 0;
}
