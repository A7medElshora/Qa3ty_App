import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';

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

      context.go(
        '/customer-profile/${Uri.encodeComponent(customer.id)}',
        extra: customer,
      );
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
                              text: 'فتح حجز جديد',
                              onPressed: _openNewBooking,
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
