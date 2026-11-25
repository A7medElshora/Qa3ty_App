import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class IncomingCallBridge {
  IncomingCallBridge._();

  static final IncomingCallBridge instance = IncomingCallBridge._();
  static const pushNotificationPayloadPrefix = 'qa3ty-push:';

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
  late final StreamController<String> _notificationTaps =
      StreamController<String>.broadcast(
    onListen: () {
      final payload = _pendingNotificationPayload;
      if (payload == null) return;
      _pendingNotificationPayload = null;
      scheduleMicrotask(() => _notificationTaps.add(payload));
    },
  );
  bool _initialized = false;
  String? _pendingPhone;
  String? _pendingNotificationPayload;

  Stream<String> get incomingCalls => _incomingCalls.stream;
  Stream<String> get notificationTaps => _notificationTaps.stream;

  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
      onDidReceiveNotificationResponse: (response) {
        _dispatchPayload(response.payload);
      },
    );
    _initialized = true;

    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true && payload != null) {
      _dispatchPayload(payload);
    }
  }

  void _dispatchPayload(String? payload) {
    if (payload == null) return;
    if (payload.startsWith(pushNotificationPayloadPrefix)) {
      _publishNotificationTap(
        payload.substring(pushNotificationPayloadPrefix.length),
      );
      return;
    }
    _publishIncomingCall(payload);
  }

  void _publishNotificationTap(String payload) {
    if (_notificationTaps.hasListener) {
      _notificationTaps.add(payload);
    } else {
      _pendingNotificationPayload = payload;
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
