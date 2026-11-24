import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/auth/export.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/halls_home_screen.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:qa3ty_app/features/halls/presentation/cubits/halls_cubit.dart';
import 'package:qa3ty_app/features/calendar/presentation/screens/monthly_calendar_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/bookings_list_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/new_booking_stepper_screen.dart';
import 'package:qa3ty_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:qa3ty_app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:qa3ty_app/features/customers/data/models/customer_model.dart';
import 'package:qa3ty_app/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:qa3ty_app/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:qa3ty_app/features/workers/presentation/screens/workers_screen.dart';
import 'package:qa3ty_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:qa3ty_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:qa3ty_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:qa3ty_app/features/more/presentation/screens/more_screen.dart';
import 'package:qa3ty_app/features/sub_accounts/presentation/screens/sub_accounts_list_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppConfig.current.useMockData ? '/halls' : '/splash',
    refreshListenable: GoRouterRefreshStream(ServicesLocator.authCubit.stream),
    redirect: (context, state) {
      final authState = ServicesLocator.authCubit.state;
      final loc = state.matchedLocation;

      if (authState is AccountSuspendedState) {
        return loc == '/suspended' ? null : '/suspended';
      }

      if (authState is SubscriptionExpiredState) {
        return loc == '/subscription-expired' ? null : '/subscription-expired';
      }

      if (AppConfig.current.useMockData) {
        if (state.matchedLocation == '/splash') return '/halls';
        return null;
      }

      if (authState is AuthInitial || authState is AuthLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      if (authState is Unauthenticated || authState is AuthErrorState) {
        final isAuthRoute = loc == '/login' || loc == '/splash';
        return isAuthRoute ? null : '/login';
      }

      if (authState is Authenticated) {
        final user = authState.user;
        if ((loc == '/expenses' || loc.startsWith('/expenses/')) &&
            !user.permissions.canManageExpenses) {
          return '/more';
        }
        if ((loc == '/reports' || loc.startsWith('/reports/')) &&
            !user.permissions.canViewReports) {
          return '/more';
        }
        if ((loc == '/inventory' || loc.startsWith('/inventory/')) &&
            !user.permissions.canManageInventory) {
          return '/more';
        }
        if ((loc == '/workers' || loc.startsWith('/workers/')) &&
            !user.permissions.canManageWorkers) {
          return '/more';
        }
        if (loc == '/sub-accounts' && !user.isPrimary) {
          return '/settings';
        }
        if (loc == '/bookings/new' && !user.permissions.canManageBookings) {
          return '/bookings';
        }
        if (loc == '/splash' ||
            loc == '/login' ||
            loc == '/suspended' ||
            loc == '/subscription-expired') {
          return '/halls';
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/suspended',
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/subscription-expired',
        builder: (context, state) {
          final authState = ServicesLocator.authCubit.state;
          return SubscriptionExpiredScreen(
            message: authState is SubscriptionExpiredState
                ? authState.message
                : null,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/incoming-call',
        builder: (context, state) => IncomingCallScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/customer-profile/:id',
        builder: (context, state) => CustomerProfileScreen(
          customerId: state.pathParameters['id'] ?? '',
          initialCustomer:
              state.extra is Customer ? state.extra as Customer : null,
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BlocProvider(
            create: (_) => HallsCubit(ServicesLocator.hallsRepo)..loadHalls(),
            child: ScaffoldWithNavBar(navigationShell: navigationShell),
          );
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
        redirect: (context, state) {
          final hallId = state.uri.queryParameters['hallId'];
          return hallId == null || hallId.isEmpty
              ? '/halls'
              : '/halls/$hallId/calendar';
        },
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
          final initialDate = DateTime.tryParse(
            state.uri.queryParameters['date'] ?? '',
          );
          return NewBookingStepperScreen(
            initialHallId: hallId,
            initialDay: day,
            initialDate: initialDate,
            initialCustomerPhone: state.uri.queryParameters['phone'],
            initialCustomerName: state.uri.queryParameters['name'],
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
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/sub-accounts',
        builder: (context, state) => const SubAccountsListScreen(),
      ),
    ],
  );

  // Backward compatibility with onGenerateRoute if needed
  Route? onGenerateRoute(RouteSettings routeSettings) => null;
}
