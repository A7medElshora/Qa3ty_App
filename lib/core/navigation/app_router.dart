import 'package:flutter/material.dart';
import 'package:qa3ty_app/core/export.dart';
import 'package:qa3ty_app/features/auth/presentation/screens/splash_screen.dart';

class AppRouter {
  Route? onGenerateRoute(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments;

    switch (routeSettings.name) {
      case splashScreen:
        return MaterialPageRoute(
          builder: (_) {
            return const SplashScreen();
          },
        );
    }

    return null;
  }
}
