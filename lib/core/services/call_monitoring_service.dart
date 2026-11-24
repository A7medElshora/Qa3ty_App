import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/helpers/phone_number_normalizer.dart';
import 'incoming_call_bridge.dart';

class CallMonitoringService {
  CallMonitoringService._();

  static const _enabledKey = 'incoming_call_monitoring_enabled';
  static const _serviceChannelId = 'call_monitoring_service';
  static const _callsChannelId = 'incoming_calls';
  static const _serviceNotificationId = 8801;
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await IncomingCallBridge.instance.initialize();

    final notifications = FlutterLocalNotificationsPlugin();
    final androidNotifications =
        notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _serviceChannelId,
        'مراقبة المكالمات',
        description: 'تشغيل خدمة استقبال تنبيهات المكالمات الواردة',
        importance: Importance.low,
      ),
    );
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        _callsChannelId,
        'المكالمات الواردة',
        description: 'تنبيه عند ورود مكالمة لفتح بيانات العميل',
        importance: Importance.high,
      ),
    );

    final configured = await _service.configure(
      iosConfiguration: IosConfiguration(autoStart: false),
      androidConfiguration: AndroidConfiguration(
        onStart: incomingCallServiceOnStart,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: _serviceChannelId,
        initialNotificationTitle: 'قاعتي',
        initialNotificationContent: 'مراقبة المكالمات الواردة مفعلة',
        foregroundServiceNotificationId: _serviceNotificationId,
        foregroundServiceTypes: const [AndroidForegroundType.specialUse],
      ),
    );

    if (!configured) {
      throw PlatformException(
        code: 'CALL_SERVICE_CONFIGURATION_FAILED',
        message: 'تعذر إعداد خدمة مراقبة المكالمات.',
      );
    }

    await resumeIfEnabled();
  }

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  static Future<bool> enable() async {
    if (!Platform.isAndroid) return false;

    final phonePermission = await Permission.phone.request();
    if (!phonePermission.isGranted) return false;

    final notificationPermission = await Permission.notification.request();
    if (!notificationPermission.isGranted) return false;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, true);
    if (!await _startIfNeeded()) {
      await preferences.setBool(_enabledKey, false);
      return false;
    }
    return true;
  }

  static Future<void> disable() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, false);
    if (await _service.isRunning()) {
      _service.invoke('stopMonitoring');
    }
  }

  static Future<void> resumeIfEnabled() async {
    if (!await isEnabled()) return;

    final hasPhonePermission = await Permission.phone.isGranted;
    final hasNotificationPermission = await Permission.notification.isGranted;
    if (!hasPhonePermission || !hasNotificationPermission) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_enabledKey, false);
      return;
    }

    await _startIfNeeded();
  }

  static Future<bool> _startIfNeeded() async {
    if (await _service.isRunning()) return true;
    final started = await _service.startService();
    return started || await _service.isRunning();
  }
}

@pragma('vm:entry-point')
void incomingCallServiceOnStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();

  if (!(preferences.getBool('incoming_call_monitoring_enabled') ?? false)) {
    service.stopSelf();
    return;
  }

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
  );
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_calls',
          'المكالمات الواردة',
          description: 'تنبيه عند ورود مكالمة لفتح بيانات العميل',
          importance: Importance.high,
        ),
      );

  String? lastNumber;
  DateTime? lastIncomingAt;

  service.on('stopMonitoring').listen((_) => service.stopSelf());
  int? lastNotificationId;
  String? lastKnownPhone;

  PhoneState.stream.listen(
    (event) {
      if (event.status == PhoneStateStatus.CALL_ENDED) {
        lastNumber = null;
        lastIncomingAt = null;
        lastKnownPhone = null;
        return;
      }

      if (event.status != PhoneStateStatus.CALL_INCOMING &&
          event.status != PhoneStateStatus.CALL_STARTED) {
        return;
      }

      final phone = event.number?.trim() ?? '';
      if (phone.isNotEmpty &&
          phone.toLowerCase() != 'unknown' &&
          phone.toLowerCase() != 'private') {
        lastKnownPhone = phone;
      }
      final outgoingPhone = lastKnownPhone ?? phone;
      if (outgoingPhone.isEmpty ||
          outgoingPhone.toLowerCase() == 'unknown' ||
          outgoingPhone.toLowerCase() == 'private') {
        return;
      }
      final normalizedPhone = normalizePhoneNumber(outgoingPhone);
      if (normalizedPhone.isEmpty) return;
      final now = DateTime.now();
      if (normalizedPhone == lastNumber &&
          lastIncomingAt != null &&
          now.difference(lastIncomingAt!) < const Duration(seconds: 30)) {
        return;
      }

      lastNumber = normalizedPhone;
      lastIncomingAt = now;
      unawaited(_showIncomingCallNotification(
        notifications,
        normalizedPhone,
        existingNotificationId: lastNotificationId,
      ).then((id) => lastNotificationId = id));
    },
    onError: (Object error, StackTrace stackTrace) {
      debugPrint('Incoming call stream failed: $error\n$stackTrace');
    },
  );
}

Future<int> _showIncomingCallNotification(
  FlutterLocalNotificationsPlugin notifications,
  String phone, {
  int? existingNotificationId,
}) async {
  final notificationId = existingNotificationId ??
      DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff);
  await notifications.show(
    id: notificationId,
    title: 'مكالمة واردة',
    body: phone.isEmpty
        ? 'اضغط لفتح قاعتي وتسجيل بيانات المتصل'
        : 'رقم المتصل: $phone',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'incoming_calls',
        'المكالمات الواردة',
        channelDescription: 'تنبيه عند ورود مكالمة لفتح بيانات العميل',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.private,
        icon: 'ic_bg_service_small',
      ),
    ),
    payload: phone,
  );
  return notificationId;
}
