import 'dart:async';
import 'dart:developer';
import 'package:qa3ty_app/app.dart';
import 'package:qa3ty_app/app_initi.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'core/config/env.dart';
import 'core/navigation/app_router.dart';
import 'core/utils/route_observer.dart';

void main() async {
  AppConfig.init(flavor: AppFlavor.production);
  runZonedGuarded(
    () async {
      await initializeApp();

      runApp(
        MyApp(
          appRouter: AppRouter(),
          routeLogger: RouteLogger(),
        ),
      );
    },
    (error, stack) {
      log(stack.toString(), name: 'main production error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
