import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import 'package:qa3ty_app/features/customers/data/models/customer_model.dart';

class IncomingCallScreen extends StatefulWidget {
  final String phone;

  const IncomingCallScreen({
    super.key,
    required this.phone,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  Customer? _matchedCustomer;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveCaller();
  }

  Future<void> _resolveCaller() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    if (widget.phone.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNewBooking();
      });
      return;
    }

    try {
      final customer =
          await ServicesLocator.customersRepo.findCustomerByPhone(widget.phone);
      if (!mounted) return;

      if (customer == null) {
        _openNewBooking();
        return;
      }

      _matchedCustomer = customer;
      final bookings = await ServicesLocator.bookingsRepo.getBookings();
      if (!mounted) return;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final upcomingBookings = bookings
          .where(
            (booking) =>
                booking.customerId == customer.id &&
                booking.status != BookingLifecycleStatus.cancelled &&
                !booking.eventDate.isBefore(todayDate),
          )
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      if (upcomingBookings.isNotEmpty) {
        context.go('/bookings/${upcomingBookings.first.id}');
      } else {
        _openCustomerProfile(customer);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'تعذر الاتصال بالخادم للبحث عن العميل.';
        _isLoading = false;
      });
    }
  }

  void _openNewBooking() {
    final uri = Uri(
      path: '/bookings/new',
      queryParameters: {
        if (widget.phone.trim().isNotEmpty) 'phone': widget.phone,
      },
    );
    context.go(uri.toString());
  }

  void _openCustomerProfile(Customer customer) {
    context.go(
      '/customer-profile/${Uri.encodeComponent(customer.id)}',
      extra: customer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'بيانات المتصل',
                subtitle: 'جارٍ البحث في سجل العملاء',
              ),
            ),
            Expanded(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تعذر البحث عن العميل: $_error',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: 16),
                            AppPrimaryButton(
                              text: 'إعادة المحاولة',
                              onPressed: _resolveCaller,
                            ),
                            const SizedBox(height: 8),
                            AppSecondaryButton(
                              text: _matchedCustomer == null
                                  ? 'فتح حجز جديد'
                                  : 'فتح ملف العميل',
                              onPressed: _matchedCustomer == null
                                  ? _openNewBooking
                                  : () =>
                                      _openCustomerProfile(_matchedCustomer!),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
