import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/key_value_row.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/features/bookings/data/models/booking_model.dart';
import '../../data/models/customer_model.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;
  final Customer? initialCustomer;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Customer? _customer;
  List<Booking> _bookings = [];
  String? _customerError;
  String? _bookingsError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.initialCustomer;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _customerError = null;
      _bookingsError = null;
    });

    try {
      final customer = await ServicesLocator.customersRepo
          .getCustomerById(widget.customerId);
      if (customer != null) _customer = customer;
      if (_customer == null) {
        _customerError = 'تعذر العثور على بيانات العميل.';
      }
    } catch (error) {
      if (_customer == null) {
        _customerError =
            error is ApiException ? error.message : 'تعذر تحميل بيانات العميل.';
      }
    }

    try {
      final bookings = await ServicesLocator.bookingsRepo.getBookings();
      _bookings = bookings
          .where((booking) => booking.customerId == widget.customerId)
          .toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    } catch (error) {
      _bookingsError =
          error is ApiException ? error.message : 'تعذر تحميل سجل الحجوزات.';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: _customer?.name ?? 'ملف العميل',
                subtitle: _customer?.phone,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customerError != null
                      ? _buildError()
                      : _buildProfile(_customer!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _customerError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              text: 'إعادة المحاولة',
              onPressed: _loadProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(Customer customer) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            title: 'بيانات العميل',
            child: Column(
              children: [
                KeyValueRow(label: 'الاسم', value: customer.name),
                KeyValueRow(label: 'رقم الهاتف', value: customer.phone),
                if (customer.email?.isNotEmpty == true)
                  KeyValueRow(
                      label: 'العنوان / البريد', value: customer.email!),
                KeyValueRow(
                  label: 'عدد الحجوزات',
                  value: customer.totalBookings.toArabicDigits(),
                ),
                KeyValueRow(
                  label: 'إجمالي المدفوع',
                  value: AppFormatters.formatMoney(customer.totalSpent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'سجل الحجوزات',
            child: _bookingsError != null
                ? Text(
                    'تعذر تحميل سجل الحجوزات: $_bookingsError',
                    style: const TextStyle(color: AppColors.red),
                  )
                : _bookings.isEmpty
                    ? const Text(
                        'لا توجد حجوزات مسجلة لهذا العميل.',
                        style: AppTextStyles.muted,
                      )
                    : Column(
                        children: _bookings
                            .map((booking) => _buildBookingTile(booking))
                            .toList(),
                      ),
          ),
          if (PermissionGuard.canManageBookings) ...[
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'إنشاء حجز جديد لهذا العميل',
              onPressed: () {
                final uri = Uri(
                  path: '/bookings/new',
                  queryParameters: {
                    'phone': customer.phone,
                    'name': customer.name,
                  },
                );
                context.push(uri.toString());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingTile(Booking booking) {
    final status = switch (booking.status) {
      BookingLifecycleStatus.tentative => 'مبدئي',
      BookingLifecycleStatus.confirmed => 'مؤكد',
      BookingLifecycleStatus.completed => 'مكتمل',
      BookingLifecycleStatus.cancelled => 'ملغي',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/bookings/${booking.id}'),
      title: Text(booking.hallName, style: AppTextStyles.cardTitle),
      subtitle: Text(
        '${AppFormatters.formatFullDate(booking.eventDate)} · $status',
        style: AppTextStyles.muted,
      ),
      trailing: Text(
        AppFormatters.formatMoney(booking.totalAmount),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
