import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import '../../data/models/notification_model.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final route = notification.route;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الإشعار'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(notification.title, style: AppTextStyles.cardTitle),
            const SizedBox(height: 10),
            Text(
              AppFormatters.formatDayMonth(notification.date),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Text(notification.message, style: AppTextStyles.body),
            ),
            if (route != null &&
                route.startsWith('/') &&
                !route.startsWith('//')) ...[
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.push(route),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح التفاصيل المرتبطة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
