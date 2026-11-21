import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import 'package:qa3ty_app/core/utils/widgets/circle_icon_button.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_sheet.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/models/customer_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    final list = await ServicesLocator.customersRepo.getCustomers();
    setState(() {
      _customers = list;
      _isLoading = false;
    });
  }

  List<Customer> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'سجل العملاء',
                subtitle: 'إدارة بيانات العملاء وتاريخ حجوزاتهم والمدفوعات',
                showBackButton: false,
                actions: [
                  CircleIconButton.primary(
                    icon: const Icon(LucideIcons.userPlus, size: 20, color: AppColors.white),
                    onTap: _showAddCustomerSheet,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: AppTextField(
                hint: 'بحث باسم العميل أو رقم الهاتف...',
                controller: _searchController,
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.muted),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Customers list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? const EmptyState(
                          title: 'لا يوجد عملاء مطابقون',
                          subtitle: 'يمكنك إضافة عميل جديد باستخدام الزر العلوي.',
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchCustomers,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 8),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, i) {
                              final customer = _filteredCustomers[i];
                              return _buildCustomerCard(customer);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _showCustomerDetailsSheet(customer),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoftText.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.user, color: AppColors.primary, size: 22),
        ),
        title: Text(customer.name, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(customer.phone, style: AppTextStyles.muted),
            const SizedBox(height: 2),
            Text('عدد الحجوزات: ${customer.totalBookings.toArabicDigits()}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('إجمالي المدفوعات', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            Text(
              AppFormatters.formatMoney(customer.totalSpent),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    AppBottomSheet.show(
      context: context,
      title: 'إضافة عميل جديد',
      child: Column(
        children: [
          AppTextField(label: 'اسم العميل', controller: nameCtrl),
          const SizedBox(height: 10),
          AppTextField(label: 'رقم الهاتف', controller: phoneCtrl, keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          AppTextField(label: 'البريد الإلكتروني (اختياري)', controller: emailCtrl, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'حفظ العميل',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final c = Customer(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  totalBookings: 0,
                  totalSpent: 0,
                );
                await ServicesLocator.customersRepo.addCustomer(c);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchCustomers();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCustomerDetailsSheet(Customer customer) {
    AppBottomSheet.show(
      context: context,
      title: 'ملف العميل: ${customer.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.phone, color: AppColors.primary),
            title: Text(customer.phone, style: AppTextStyles.body),
            subtitle: const Text('رقم الهاتف الأساسي', style: TextStyle(fontSize: 11)),
          ),
          if (customer.email != null)
            ListTile(
              leading: const Icon(LucideIcons.mail, color: AppColors.primary),
              title: Text(customer.email!, style: AppTextStyles.body),
              subtitle: const Text('البريد الإلكتروني', style: TextStyle(fontSize: 11)),
            ),
          ListTile(
            leading: const Icon(LucideIcons.calendarCheck, color: AppColors.primary),
            title: Text('${customer.totalBookings.toArabicDigits()} حجوزات سابقة وحالية', style: AppTextStyles.body),
            subtitle: const Text('سجل الحجوزات', style: TextStyle(fontSize: 11)),
          ),
          ListTile(
            leading: const Icon(LucideIcons.badgePercent, color: AppColors.green),
            title: Text(AppFormatters.formatMoney(customer.totalSpent), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green)),
            subtitle: const Text('إجمالي قيمة العقود المسددة', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            text: 'إنشاء حجز جديد لهذا العميل',
            onPressed: () {
              Navigator.pop(context);
              context.push('/bookings/new');
            },
          ),
        ],
      ),
    );
  }
}
