import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'incoming_call_bridge.dart';

class PushNotificationDetails {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime date;
  final String? route;

  const PushNotificationDetails({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.route,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'date': date.toIso8601String(),
        'route': route,
      };

  factory PushNotificationDetails.fromJson(Map<String, dynamic> json) {
    return PushNotificationDetails(
      id: json['id']?.toString() ?? 'push-notification',
      title: json['title']?.toString() ?? 'إشعار جديد',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      route: _internalRoute(json['route']?.toString()),
    );
  }
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();
  static const _notificationChannelId = 'push_notifications';
  static final StreamController<PushNotificationDetails> _openedNotifications =
      StreamController<PushNotificationDetails>.broadcast();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isAuthenticated = false;
  String? _fcmToken;
  String? _registeredToken;
  String? _registeringToken;
  Future<void> Function(String token)? _registerDeviceToken;
  PushNotificationDetails? _pendingOpenedNotification;

  Stream<PushNotificationDetails> get openedNotifications =>
      _openedNotifications.stream;

  Future<void> initialize({
    required Future<void> Function(String token) registerDeviceToken,
  }) async {
    if (_initialized) return;

    _registerDeviceToken = registerDeviceToken;
    await _initializeLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_showForegroundNotification(message)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Foreground push notification failed: $error\n$stackTrace',
        );
      },
    );
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _publishOpenedNotification(_fromRemoteMessage(message));
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (kDebugMode) debugPrint('FCM TOKEN refreshed: $token');
      _fcmToken = token;
      unawaited(_registerTokenIfReady());
    });
    _initialized = true;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission was denied.');
      return;
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    _fcmToken = token;
    if (kDebugMode) {
      debugPrint('FCM TOKEN: ${token ?? 'not available'}');
    }
    if (token != null && token.isNotEmpty) {
      unawaited(_registerTokenIfReady());
    }

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _publishOpenedNotification(_fromRemoteMessage(initialMessage));
    }
  }

  void setAuthenticated(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (isAuthenticated) unawaited(_registerTokenIfReady());
  }

  PushNotificationDetails? takePendingOpenedNotification() {
    final notification = _pendingOpenedNotification;
    _pendingOpenedNotification = null;
    return notification;
  }

  void handleLocalNotificationTap(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
            'Notification payload must be a JSON object.');
      }
      _publishOpenedNotification(PushNotificationDetails.fromJson(decoded));
    } on FormatException catch (error, stackTrace) {
      debugPrint(
          'Could not read notification tap payload: $error\n$stackTrace');
    }
  }

  Future<void> _registerTokenIfReady() async {
    final token = _fcmToken;
    final register = _registerDeviceToken;
    if (!_isAuthenticated ||
        token == null ||
        register == null ||
        token == _registeredToken ||
        token == _registeringToken) {
      return;
    }
    _registeringToken = token;
    try {
      await register(token);
      _registeredToken = token;
    } catch (error, stackTrace) {
      debugPrint('Could not register FCM device token: $error\n$stackTrace');
    } finally {
      if (_registeringToken == token) _registeringToken = null;
    }
  }

  PushNotificationDetails _fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final route = _internalRoute(
      data['route']?.toString() ?? data['action_url']?.toString(),
    );
    return PushNotificationDetails(
      id: data['notification_id']?.toString() ??
          message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title']?.toString() ?? 'إشعار جديد',
      message: notification?.body ?? data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      date: DateTime.now(),
      route: route,
    );
  }

  void _publishOpenedNotification(PushNotificationDetails notification) {
    if (!_openedNotifications.hasListener) {
      _pendingOpenedNotification = notification;
      return;
    }
    _openedNotifications.add(notification);
  }

  Future<void> _initializeLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notificationChannelId,
            'إشعارات التطبيق',
            description: 'إشعارات قاعتي',
            importance: Importance.high,
          ),
        );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final details = _fromRemoteMessage(message);
      await _localNotifications.show(
        id: details.id.hashCode & 0x7fffffff,
        title: details.title,
        body: details.message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            'إشعارات التطبيق',
            channelDescription: 'إشعارات قاعتي',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: 'ic_bg_service_small',
          ),
        ),
        payload:
            '${IncomingCallBridge.pushNotificationPayloadPrefix}${jsonEncode(details.toJson())}',
      );
    } catch (error, stackTrace) {
      debugPrint(
          'Could not show foreground push notification: $error\n$stackTrace');
    }
  }
}

String? _internalRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return null;
  }
  return route;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (message.notification == null) {
    await PushNotificationsService.instance._initializeLocalNotifications();
    await PushNotificationsService.instance
        ._showForegroundNotification(message);
  }
  debugPrint('Background push message received: ${message.messageId}');
}
