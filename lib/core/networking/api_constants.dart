import 'package:qa3ty_app/core/config/env.dart';

class ApiConstants {
  // Base URLs (Lovable Cloud)
  static const String devBaseUrl =
      'https://elshora-qa3aty2026.lovable.app/api/public/v1';
  static const String prodBaseUrl =
      'https://elshora-qa3aty2026.lovable.app/api/public/v1';

  // Dynamic Base URL resolving according to active Flavor / Config
  static String get apiBaseUrl => AppConfig.current.baseUrl;

  // 1. Auth Endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // 2. Dashboard
  static const String dashboardSummary = '/dashboard/summary';

  // 3. Halls Endpoints
  static const String halls = '/halls';
  static const String hallDetails = '/halls/{id}';

  // 4. Customers Endpoints
  static const String customers = '/customers';
  static const String customerDetails = '/customers/{id}';

  // 5. Bookings Endpoints
  static const String bookings = '/bookings';
  static const String calendar = '/bookings/calendar';
  static const String bookingDetails = '/bookings/{id}';
  static const String bookingCancel = '/bookings/{id}/cancel';
  static const String bookingPayments = '/bookings/{id}/payments';
  static const String bookingItems = '/bookings/{id}/items';

  // 6. Expenses Endpoints
  static const String expenses = '/expenses';
  static const String expenseCategories = '/expense-categories';

  // 7. Workers Endpoints
  static const String workers = '/workers';
  static const String workerPayments = '/workers/{id}/payments';

  // 8. Inventory Endpoints
  static const String inventory = '/inventory';
  static const String inventoryMovements = '/inventory/movements';

  // 9. Notifications & FCM
  static const String notifications = '/notifications';
  static const String notificationRead = '/notifications/{id}/read';
  static const String deviceTokens = '/device-tokens';

  // 10. Reports
  static const String reportsMonthly = '/reports/monthly';
  static const String reportsYearly = '/reports/yearly';
  static const String reportsProfitLoss = '/reports/profit-loss';
  static const String reportsBookings = '/reports/bookings';
  static const String reportsExportExcel = '/reports/export/excel';

  // 11. Sub-account endpoints
  static const String subAccounts = '/sub-accounts';
  static const String subAccountDetails = '/sub-accounts/{id}';
  static const String subAccountResetPassword = '/sub-accounts/{id}/reset-password';
}
