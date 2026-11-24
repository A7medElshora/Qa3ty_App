// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained equivalent of Retrofit-generated code.
// Run `dart run build_runner build --delete-conflicting-outputs` to regenerate.

part of 'api_service.dart';

class _ApiService implements ApiService {
  _ApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  String? baseUrl;

  // 1. Auth
  @override
  Future<dynamic> login(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.login, data: body)).data;

  @override
  Future<dynamic> refreshToken(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.refresh, data: body)).data;

  @override
  Future<dynamic> logout() async =>
      (await _dio.post(ApiConstants.logout)).data;

  @override
  Future<dynamic> getCurrentUser() async =>
      (await _dio.get(ApiConstants.currentUser)).data;

  @override
  Future<dynamic> changePassword(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.changePassword, data: body)).data;

  // 2. Dashboard
  @override
  Future<dynamic> getDashboardSummary() async =>
      (await _dio.get(ApiConstants.dashboardSummary)).data;

  // 3. Halls
  @override
  Future<dynamic> getHalls(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.halls, queryParameters: queries)).data;

  @override
  Future<dynamic> createHall(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.halls, data: body)).data;

  @override
  Future<dynamic> getHallDetails(String path) async =>
      (await _dio.get(path)).data;

  @override
  Future<dynamic> updateHall(String path, Map<String, dynamic> body) async =>
      (await _dio.put(path, data: body)).data;

  @override
  Future<dynamic> deleteHall(String path) async =>
      (await _dio.delete(path)).data;

  // 4. Customers
  @override
  Future<dynamic> getCustomers(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.customers, queryParameters: queries)).data;

  @override
  Future<dynamic> createCustomer(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.customers, data: body)).data;

  @override
  Future<dynamic> updateCustomer(String path, Map<String, dynamic> body) async =>
      (await _dio.put(path, data: body)).data;

  @override
  Future<dynamic> deleteCustomer(String path) async =>
      (await _dio.delete(path)).data;

  // 5. Bookings & Calendar
  @override
  Future<dynamic> getBookings(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.bookings, queryParameters: queries)).data;

  @override
  Future<dynamic> getCalendarBookings(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.calendar, queryParameters: queries)).data;

  @override
  Future<dynamic> createBooking(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.bookings, data: body)).data;

  // 6. Expenses & Categories
  @override
  Future<dynamic> getExpenses(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.expenses, queryParameters: queries)).data;

  @override
  Future<dynamic> createExpense(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.expenses, data: body)).data;

  @override
  Future<dynamic> getExpenseCategories() async =>
      (await _dio.get(ApiConstants.expenseCategories)).data;

  @override
  Future<dynamic> createExpenseCategory(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.expenseCategories, data: body)).data;

  // 7. Workers
  @override
  Future<dynamic> getWorkers(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.workers, queryParameters: queries)).data;

  @override
  Future<dynamic> createWorker(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.workers, data: body)).data;

  // 8. Inventory
  @override
  Future<dynamic> getInventoryItems(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.inventory, queryParameters: queries)).data;

  @override
  Future<dynamic> createInventoryItem(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.inventory, data: body)).data;

  @override
  Future<dynamic> getInventoryMovements(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.inventoryMovements, queryParameters: queries)).data;

  @override
  Future<dynamic> recordInventoryMovement(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.inventoryMovements, data: body)).data;

  // 9. Notifications
  @override
  Future<dynamic> getNotifications(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.notifications, queryParameters: queries)).data;

  @override
  Future<dynamic> registerDeviceToken(Map<String, dynamic> body) async =>
      (await _dio.post(ApiConstants.deviceTokens, data: body)).data;

  // 10. Reports
  @override
  Future<dynamic> getMonthlyReport(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.reportsMonthly, queryParameters: queries)).data;

  @override
  Future<dynamic> getProfitLossReport(Map<String, dynamic>? queries) async =>
      (await _dio.get(ApiConstants.reportsProfitLoss, queryParameters: queries)).data;

  @override
  Future<dynamic> exportMonthlyExcel(Map<String, dynamic>? queries) async =>
      (await _dio.get(
        ApiConstants.reportsExportExcel,
        queryParameters: queries,
        options: Options(responseType: ResponseType.bytes),
      )).data;
}
