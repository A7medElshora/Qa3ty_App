import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/halls_home_screen.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:qa3ty_app/features/calendar/presentation/screens/monthly_calendar_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/bookings_list_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/new_booking_stepper_screen.dart';
import 'package:qa3ty_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:qa3ty_app/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:qa3ty_app/features/workers/presentation/screens/workers_screen.dart';
import 'package:qa3ty_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:qa3ty_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:qa3ty_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:qa3ty_app/features/more/presentation/screens/more_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/halls',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Halls
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/halls',
                builder: (context, state) => const HallsHomeScreen(),
              ),
            ],
          ),

          // Branch 1: Expenses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),

          // Branch 2: Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Branch 3: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),

          // Branch 4: More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // Calendar Route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/calendar',
        builder: (context, state) => const MonthlyCalendarScreen(hallId: 'masia'),
      ),

      // Halls Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/halls/form',
        builder: (context, state) {
          final editId = state.uri.queryParameters['editId'];
          return HallFormScreen(editHallId: editId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/halls/:id/calendar',
        builder: (context, state) {
          final hallId = state.pathParameters['id'] ?? 'masia';
          return MonthlyCalendarScreen(hallId: hallId);
        },
      ),

      // Bookings Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookings',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          return BookingsListScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookings/new',
        builder: (context, state) {
          final hallId = state.uri.queryParameters['hallId'];
          final dayStr = state.uri.queryParameters['day'];
          final day = dayStr != null ? int.tryParse(dayStr) : null;
          return NewBookingStepperScreen(
            initialHallId: hallId,
            initialDay: day,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookings/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '1042') ?? 1042;
          return BookingDetailsScreen(bookingId: id);
        },
      ),

      // Expenses Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/expenses/form',
        builder: (context, state) => const ExpenseFormScreen(),
      ),

      // Inventory Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),

      // Workers Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/workers',
        builder: (context, state) => const WorkersScreen(),
      ),

      // Reports Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),


      // Settings Subroutes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  // Backward compatibility with onGenerateRoute if needed
  Route? onGenerateRoute(RouteSettings routeSettings) => null;
}
