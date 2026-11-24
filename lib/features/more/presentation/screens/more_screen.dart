import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/permission_guard.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreMenuItem>[
      _MoreMenuItem(
        icon: LucideIcons.building2,
        title: 'القاعات والإدارة',
        subtitle: 'إضافة وتعديل ومتابعة جداول القاعات',
        route: '/halls',
      ),
      _MoreMenuItem(
        icon: LucideIcons.calendarCheck,
        title: 'كافة الحجوزات',
        subtitle: 'قوائم الحجوزات القادمة والمكتملة والملغاة',
        route: '/bookings',
      ),
      _MoreMenuItem(
        icon: LucideIcons.receipt,
        title: 'المصروفات والتكاليف',
        subtitle: 'تسجيل الفواتير والصيانة والمصروفات العامة',
        route: '/expenses',
        visible: PermissionGuard.canManageExpenses,
      ),
      _MoreMenuItem(
        icon: LucideIcons.boxes,
        title: 'المخزون والمستلزمات',
        subtitle: 'أرصدة الأصناف وحركات الشراء والاستهلاك',
        route: '/inventory',
        visible: PermissionGuard.canManageInventory,
      ),
      _MoreMenuItem(
        icon: LucideIcons.users2,
        title: 'شؤون العمال والموظفين',
        subtitle: 'الأجور اليومية والشهرية وسجل الدفعات',
        route: '/workers',
        visible: PermissionGuard.canManageWorkers,
      ),
      _MoreMenuItem(
        icon: LucideIcons.barChart3,
        title: 'التقارير المالية والأرباح',
        subtitle: 'تحليل الإيرادات وصافي الأرباح ومقارنة القاعات',
        route: '/reports',
        visible: PermissionGuard.canViewReports,
      ),
      _MoreMenuItem(
        icon: LucideIcons.bell,
        title: ' التنبيهات والإشعارات',
        subtitle: 'المناسبات القريبة وتنبيهات المستحقات',
        route: '/notifications',
      ),
      _MoreMenuItem(
        icon: LucideIcons.settings,
        title: 'الإعدادات والاشتراك',
        subtitle: 'بيانات المنشأة وتفاصيل الباقة والحساب',
        route: '/settings',
      ),
    ].where((item) => item.visible).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 52, left: 16, right: 16, bottom: 8),
              child: AppHeader(
                title: 'المزيد',
                subtitle: 'لوحة التحكم السريعة والخدمات الإدارية',
                showBackButton: false,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 100, top: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ListTile(
                      onTap: () => context.push(item.route),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(item.icon, size: 20, color: AppColors.primary),
                      ),
                      title: Text(item.title, style: AppTextStyles.cardTitle),
                      subtitle: Text(item.subtitle, style: AppTextStyles.muted),
                      trailing: const Icon(LucideIcons.arrowLeft,
                          size: 16, color: AppColors.muted),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool visible;

  _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.visible = true,
  });
}
