import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class IncomingCallBridge {
  IncomingCallBridge._();

  static final IncomingCallBridge instance = IncomingCallBridge._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  late final StreamController<String> _incomingCalls =
      StreamController<String>.broadcast(
    onListen: () {
      final phone = _pendingPhone;
      if (phone == null) return;
      _pendingPhone = null;
      scheduleMicrotask(() => _incomingCalls.add(phone));
    },
  );
  bool _initialized = false;
  String? _pendingPhone;

  Stream<String> get incomingCalls => _incomingCalls.stream;

  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _publishIncomingCall(response.payload ?? '');
      },
    );
    _initialized = true;

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true && payload != null) {
      _publishIncomingCall(payload);
    }
  }

  void _publishIncomingCall(String phone) {
    if (_incomingCalls.hasListener) {
      _incomingCalls.add(phone);
    } else {
      _pendingPhone = phone;
    }
  }
}
