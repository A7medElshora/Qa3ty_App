import 'package:dio/dio.dart';
import 'package:qa3ty_app/core/networking/api_constants.dart';
import 'package:retrofit/retrofit.dart';

// NOTE: build_runner generated code is replaced by manual implementation in api_service.g.dart
// to avoid Retrofit annotation conflicts. Run `dart run build_runner build` to regenerate
// if adding new endpoints.

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String? baseUrl}) = _ApiService;

  // 1. Auth Endpoints
  @POST(ApiConstants.login)
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST(ApiConstants.refresh)
  Future<dynamic> refreshToken(@Body() Map<String, dynamic> body);

  @POST(ApiConstants.logout)
  Future<dynamic> logout();

  @GET(ApiConstants.currentUser)
  Future<dynamic> getCurrentUser();

  @POST(ApiConstants.changePassword)
  Future<dynamic> changePassword(@Body() Map<String, dynamic> body);

  // 2. Dashboard
  @GET(ApiConstants.dashboardSummary)
  Future<dynamic> getDashboardSummary();

  // 3. Halls Endpoints
  @GET(ApiConstants.halls)
  Future<dynamic> getHalls(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.halls)
  Future<dynamic> createHall(@Body() Map<String, dynamic> body);

  @GET('{path}')
  Future<dynamic> getHallDetails(@Path('path') String path);

  @PUT('{path}')
  Future<dynamic> updateHall(@Path('path') String path, @Body() Map<String, dynamic> body);

  @DELETE('{path}')
  Future<dynamic> deleteHall(@Path('path') String path);

  // 4. Customers Endpoints
  @GET(ApiConstants.customers)
  Future<dynamic> getCustomers(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.customers)
  Future<dynamic> createCustomer(@Body() Map<String, dynamic> body);

  @PUT('{path}')
  Future<dynamic> updateCustomer(@Path('path') String path, @Body() Map<String, dynamic> body);

  @DELETE('{path}')
  Future<dynamic> deleteCustomer(@Path('path') String path);

  // 5. Bookings & Calendar Endpoints
  @GET(ApiConstants.bookings)
  Future<dynamic> getBookings(@Queries() Map<String, dynamic>? queries);

  @GET(ApiConstants.calendar)
  Future<dynamic> getCalendarBookings(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.bookings)
  Future<dynamic> createBooking(@Body() Map<String, dynamic> body);

  // 6. Expenses & Categories
  @GET(ApiConstants.expenses)
  Future<dynamic> getExpenses(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.expenses)
  Future<dynamic> createExpense(@Body() Map<String, dynamic> body);

  @GET(ApiConstants.expenseCategories)
  Future<dynamic> getExpenseCategories();

  @POST(ApiConstants.expenseCategories)
  Future<dynamic> createExpenseCategory(@Body() Map<String, dynamic> body);

  // 7. Workers
  @GET(ApiConstants.workers)
  Future<dynamic> getWorkers(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.workers)
  Future<dynamic> createWorker(@Body() Map<String, dynamic> body);

  // 8. Inventory
  @GET(ApiConstants.inventory)
  Future<dynamic> getInventoryItems(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.inventory)
  Future<dynamic> createInventoryItem(@Body() Map<String, dynamic> body);

  @GET(ApiConstants.inventoryMovements)
  Future<dynamic> getInventoryMovements(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.inventoryMovements)
  Future<dynamic> recordInventoryMovement(@Body() Map<String, dynamic> body);

  // 9. Notifications
  @GET(ApiConstants.notifications)
  Future<dynamic> getNotifications(@Queries() Map<String, dynamic>? queries);

  @POST(ApiConstants.deviceTokens)
  Future<dynamic> registerDeviceToken(@Body() Map<String, dynamic> body);

  // 10. Reports
  @GET(ApiConstants.reportsMonthly)
  Future<dynamic> getMonthlyReport(@Queries() Map<String, dynamic>? queries);

  @GET(ApiConstants.reportsProfitLoss)
  Future<dynamic> getProfitLossReport(@Queries() Map<String, dynamic>? queries);

  @GET(ApiConstants.reportsExportExcel)
  Future<dynamic> exportMonthlyExcel(@Queries() Map<String, dynamic>? queries);
}
