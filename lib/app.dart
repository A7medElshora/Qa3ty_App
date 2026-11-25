import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qa3ty_app/core/export.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/services/incoming_call_bridge.dart';
import 'package:qa3ty_app/core/services/push_notifications_service.dart';
import 'package:qa3ty_app/features/auth/export.dart';
import 'package:qa3ty_app/features/notifications/data/models/notification_model.dart';
import 'core/cubit/internet/internet_cubit.dart';

final GlobalKey<NavigatorState> navigatorKey = rootNavigatorKey;

class MyApp extends StatefulWidget {
  final AppRouter appRouter;
  final RouteLogger routeLogger;

  const MyApp({
    super.key,
    required this.appRouter,
    required this.routeLogger,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _incomingCallSubscription;
  StreamSubscription<String>? _localNotificationSubscription;
  StreamSubscription<PushNotificationDetails>? _pushNotificationSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  String? _pendingIncomingPhone;
  PushNotificationDetails? _pendingPushNotification;
  bool _routerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _incomingCallSubscription =
        IncomingCallBridge.instance.incomingCalls.listen(_queueIncomingCall);
    _localNotificationSubscription =
        IncomingCallBridge.instance.notificationTaps.listen(
      PushNotificationsService.instance.handleLocalNotificationTap,
    );
    _pushNotificationSubscription = PushNotificationsService
        .instance.openedNotifications
        .listen(_queuePushNotification);
    PushNotificationsService.instance.setAuthenticated(
      ServicesLocator.authCubit.state is Authenticated,
    );
    _authSubscription = ServicesLocator.authCubit.stream.listen((_) {
      PushNotificationsService.instance.setAuthenticated(
        ServicesLocator.authCubit.state is Authenticated,
      );
      _openPendingIncomingCall();
      _openPendingPushNotification();
    });
    _initializeIncomingCallBridge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routerReady = true;
      _pendingPushNotification =
          PushNotificationsService.instance.takePendingOpenedNotification();
      _openPendingIncomingCall();
      _openPendingPushNotification();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ServicesLocator.introAppCubit.refreshRemoteConfig();
    }
  }

  Future<void> _initializeIncomingCallBridge() async {
    try {
      await IncomingCallBridge.instance.initialize();
    } on MissingPluginException {
      // Incoming-call notifications are available only on Android.
    } on PlatformException {
      debugPrint('Could not read the pending incoming-call notification.');
    }
  }

  void _queueIncomingCall(String phone) {
    _pendingIncomingPhone = phone;
    _openPendingIncomingCall();
  }

  void _queuePushNotification(PushNotificationDetails notification) {
    _pendingPushNotification = notification;
    _openPendingPushNotification();
  }

  void _openPendingPushNotification() {
    final notification = _pendingPushNotification;
    if (!_routerReady || notification == null) return;

    final isMock = AppConfig.current.useMockData;
    final isAuthenticated = ServicesLocator.authCubit.state is Authenticated;
    if (!isMock && !isAuthenticated) return;

    _pendingPushNotification = null;
    AppRouter.router.push(
      '/notification-details',
      extra: AppNotification(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        date: notification.date,
        type: notificationTypeFrom(notification.type),
        route: notification.route,
      ),
    );
  }

  void _openPendingIncomingCall() {
    final phone = _pendingIncomingPhone;
    if (!_routerReady || phone == null) return;

    final isMock = AppConfig.current.useMockData;
    final isAuthenticated = ServicesLocator.authCubit.state is Authenticated;
    if (!isMock && !isAuthenticated) return;

    _pendingIncomingPhone = null;
    if (phone.trim().isEmpty) {
      AppRouter.router.push('/bookings/new');
      return;
    }
    final uri = Uri(
      path: '/incoming-call',
      queryParameters: {'phone': phone},
    );
    AppRouter.router.push(uri.toString());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomingCallSubscription?.cancel();
    _localNotificationSubscription?.cancel();
    _pushNotificationSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildAppWithProviders(
      child: BlocListener<InternetCubit, InternetState>(
        listener: (context, state) {
          if (state is ConnectedState) {
            ServicesLocator.introAppCubit.initApp();
          }
          if (state is NotConnectedState) {
            showToast(
              msg: 'الانترنت غير مستقر حاليا',
              state: ToastedStates.error,
            );
          }
        },
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'قاعتي | Qa3aty',
            locale: const Locale('ar'),
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            theme: ThemeData(
              fontFamily: AppTextStyles.fontFamily,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                surface: AppColors.card,
              ),
              useMaterial3: true,
            ),
          ),
        ),
      ),
    );
  }
}
