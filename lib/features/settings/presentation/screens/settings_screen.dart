import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/section_card.dart';
import 'package:qa3ty_app/core/utils/widgets/key_value_row.dart';
import 'package:qa3ty_app/core/utils/widgets/app_buttons.dart';
import 'package:qa3ty_app/core/utils/widgets/app_text_field.dart';
import '../../data/models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VenueSettings? _settings;
  bool _isLoading = true;
  bool _notifEvents = true;
  bool _notifPayments = true;
  bool _notifStock = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    final data = await ServicesLocator.settingsRepo.getSettings();
    setState(() {
      _settings = data;
      _isLoading = false;
    });
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
                title: 'الإعدادات والاشتراك',
                subtitle: 'إدارة حساب المنشأة وتفاصيل الباقة والتنبيهات',
                showBackButton: false,
                actions: [
                  // Experimental Data Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.amber, width: 1.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.flaskConical, size: 12, color: AppColors.amberText),
                        SizedBox(width: 4),
                        Text(
                          'بيانات تجريبية',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amberText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                      child: Column(
                        children: [
                          // 1) Subscription Card
                          _buildSubscriptionCard(),

                          const SizedBox(height: 14),

                          // 2) Venue Profile Card
                          SectionCard(
                            title: 'بيانات المنشأة والحساب',
                            child: Column(
                              children: [
                                KeyValueRow(label: 'اسم المنشأة', value: _settings?.venueName ?? ''),
                                KeyValueRow(label: 'المدير المسؤول', value: _settings?.ownerName ?? ''),
                                KeyValueRow(label: 'الهاتف', value: _settings?.phone ?? ''),
                                KeyValueRow(label: 'البريد الإلكتروني', value: _settings?.email ?? ''),
                                const Divider(color: AppColors.line, height: 16),
                                AppSecondaryButton(
                                  text: 'تغيير كلمة المرور',
                                  height: 40,
                                  onPressed: _showChangePasswordDialog,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 3) Notifications Settings Card
                          SectionCard(
                            title: 'تفضيلات الإشعارات والتنبيهات',
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('تنبيهات الفعاليات القادمة (قبل ٤٨ ساعة)', style: AppTextStyles.body),
                                  value: _notifEvents,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _notifEvents = val),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('تنبيهات الدفعات والمستحقات القريبة', style: AppTextStyles.body),
                                  value: _notifPayments,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _notifPayments = val),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('تنبيهات انخفاض رصيد المخزون', style: AppTextStyles.body),
                                  value: _notifStock,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _notifStock = val),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 4) Logout button
                          AppSecondaryButton(
                            text: 'تسجيل الخروج من الحساب',
                            textColor: AppColors.red,
                            borderColor: AppColors.red,
                            icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.red),
                            onPressed: _showLogoutConfirmDialog,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _settings?.planName ?? 'الباقة السنوية',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'نشط ومفعل',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'تاريخ الانتهاء: ${AppFormatters.formatFullDate(_settings?.planEndDate ?? DateTime(2026, 12, 31))}',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.primarySoftText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المدة المتبقية: ${(_settings?.daysLeft ?? 240).toArabicDigits()} يوماً',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تغيير كلمة المرور', style: AppTextStyles.cardTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'كلمة المرور الحالية', controller: oldCtrl, obscureText: true),
            const SizedBox(height: 10),
            AppTextField(label: 'كلمة المرور الجديدة', controller: newCtrl, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
              );
            },
            child: const Text('تأكيد التغيير', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد تسجيل الخروج', style: TextStyle(color: AppColors.red, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
              );
            },
            child: const Text('تسجيل خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
