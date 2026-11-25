import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/utils/widgets/app_header.dart';
import 'package:qa3ty_app/core/utils/widgets/state_widgets.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await ServicesLocator.notificationsRepo.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load notifications: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
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
                title: ' الإشعارات والتنبيهات',
                subtitle: 'متابعة الفعاليات والمستحقات وحركة المخزون',
                actions: [
                  TextButton(
                    onPressed: () async {
                      await ServicesLocator.notificationsRepo.markAllAsRead();
                      _fetchNotifications();
                    },
                    child: const Text('تحديد الكل كمقروء',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const AppListSkeleton(itemCount: 4)
                  : _loadFailed
                      ? ErrorState(
                          message: 'تعذر تحميل الإشعارات حالياً.',
                          onRetry: _fetchNotifications,
                        )
                      : _notifications.isEmpty
                          ? const EmptyState(
                              title: 'لا توجد إشعارات جديدة',
                              subtitle:
                                  'ستظهر هنا كافة تنبيهات الفعاليات والمبالغ المتبقية.',
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, bottom: 80, top: 8),
                                itemCount: _notifications.length,
                                itemBuilder: (context, i) {
                                  final n = _notifications[i];
                                  return _buildNotificationCard(n);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (n.type) {
      case NotificationType.remainingDue:
        icon = LucideIcons.alertCircle;
        iconColor = AppColors.red;
        iconBg = AppColors.redBg;
        break;
      case NotificationType.paymentReceived:
        icon = LucideIcons.badgeCheck;
        iconColor = AppColors.green;
        iconBg = AppColors.greenBg;
        break;
      case NotificationType.lowStock:
        icon = LucideIcons.alertTriangle;
        iconColor = AppColors.amber;
        iconBg = AppColors.amberBg;
        break;
      case NotificationType.upcomingEvent:
        icon = LucideIcons.calendar;
        iconColor = AppColors.primary;
        iconBg = AppColors.primarySoftText.withValues(alpha: 0.3);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: n.isRead ? AppColors.white : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            n.isRead ? null : Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: () async {
          var isRead = n.isRead;
          if (!n.isRead) {
            try {
              await ServicesLocator.notificationsRepo.markAsRead(n.id);
              isRead = true;
            } catch (error, stackTrace) {
              debugPrint(
                'Could not mark notification as read: $error\n$stackTrace',
              );
            }
          }
          if (!mounted) return;
          final index = _notifications.indexWhere((item) => item.id == n.id);
          if (index != -1 && isRead) {
            setState(() {
              _notifications[index] = n.copyWith(isRead: true);
            });
          }
          context.push(
            '/notification-details',
            extra: n.copyWith(isRead: isRead),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(n.title, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(n.message, style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(AppFormatters.formatDayMonth(n.date),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        trailing: n.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
      ),
    );
  }
}
