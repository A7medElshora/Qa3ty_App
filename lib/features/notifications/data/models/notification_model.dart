import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_exceptions.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';

enum NotificationType {
  upcomingEvent, // مناسبة قريبة
  remainingDue, // مبلغ متبقٍ
  paymentReceived, // دفعة جديدة
  lowStock, // انخفاض مخزون
}

NotificationType notificationTypeFrom(String value) {
  final type = value.toLowerCase();
  if (type.contains('due') ||
      type.contains('remaining') ||
      type.contains('deposit') ||
      type.contains('advance')) {
    return NotificationType.remainingDue;
  }
  if (type.contains('payment')) return NotificationType.paymentReceived;
  if (type.contains('stock')) return NotificationType.lowStock;
  return NotificationType.upcomingEvent;
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final String? route;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.route,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    NotificationType? type,
    bool? isRead,
    String? route,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
    );
  }
}

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> registerDeviceToken({required String fcmToken});
}

class RemoteNotificationsRepository implements NotificationsRepository {
  final Dio _dio;

  RemoteNotificationsRepository([Dio? dio]) : _dio = dio ?? DioFactory.getDio();

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final data = response.data;
      final List rawItems = (data is Map && data['data'] != null)
          ? (data['data'] is Map ? (data['data']['items'] ?? []) : data['data'])
          : (data is List ? data : []);

      final notifications = rawItems.map<AppNotification>((item) {
        final nType = notificationTypeFrom(item['type']?.toString() ?? '');

        DateTime d = DateTime.now();
        final rawDate = item['created_at'] ?? item['date'];
        if (rawDate != null) {
          d = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
        }

        return AppNotification(
          id: item['id']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          message: item['message']?.toString() ?? '',
          date: d,
          type: nType,
          isRead: item['is_read'] == true,
          route: _internalNotificationRoute(
            item['route']?.toString() ?? item['action_url']?.toString(),
          ),
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return notifications;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (_) {
      // If endpoint doesn't support bulk, ignore or fallback
    }
  }

  @override
  Future<void> registerDeviceToken({required String fcmToken}) async {
    try {
      await _dio.post(
        '/device-tokens',
        data: {
          'token': fcmToken,
          'device_label': 'Qa3ty Flutter App',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

String? _internalNotificationRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return null;
  }
  return route;
}

class MockNotificationsRepository implements NotificationsRepository {
  // TODO(API): Replace in-memory mock data with Retrofit / Dio API service
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_1',
      title: 'مبلغ متبقي مستحق قريباً',
      message: 'سارة محمود: متبقي ٢٢٬٠٠٠ ج.م لحفل ٦ ديسمبر (بعد ١٥ يوم)',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.remainingDue,
      isRead: false,
      route: '/bookings/1040',
    ),
    AppNotification(
      id: 'notif_2',
      title: 'دفعة جديدة تم تحصيلها',
      message: 'تم استلام ١٠٬٠٠٠ ج.م من محمد عبد الله (حجز ١٠٤٢#)',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.paymentReceived,
      isRead: false,
      route: '/bookings/1042',
    ),
    AppNotification(
      id: 'notif_3',
      title: 'تنبيه انخفاض المخزون',
      message: 'سائل دخان ثقيل وصل إلى ٤ عبوات فقط (أقل من الحد الأدنى ٥)',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.lowStock,
      isRead: true,
      route: '/inventory',
    ),
    AppNotification(
      id: 'notif_4',
      title: 'مناسبة قريبة غداً',
      message: 'حفل زفاف في قاعة الماسة الساعة ٨:٠٠ م',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.upcomingEvent,
      isRead: true,
      route: '/halls/masia/calendar',
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List<AppNotification>.from(_notifications)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 50));
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> registerDeviceToken({required String fcmToken}) async {}
}
