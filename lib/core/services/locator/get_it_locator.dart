import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:qa3ty_app/core/networking/api_service.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';
import 'package:qa3ty_app/core/cubit/intro_app/intro_app_cubit.dart';
import 'package:qa3ty_app/features/halls/data/repos/halls_repository.dart';
import 'package:qa3ty_app/features/calendar/data/repos/calendar_repository.dart';
import 'package:qa3ty_app/features/bookings/data/repos/bookings_repository.dart';
import 'package:qa3ty_app/features/customers/data/models/customer_model.dart';
import 'package:qa3ty_app/features/expenses/data/models/expense_model.dart';
import 'package:qa3ty_app/features/inventory/data/models/inventory_model.dart';
import 'package:qa3ty_app/features/workers/data/models/worker_model.dart';
import 'package:qa3ty_app/features/notifications/data/models/notification_model.dart';
import 'package:qa3ty_app/features/settings/data/models/settings_model.dart';
import 'package:qa3ty_app/features/reports/data/models/report_model.dart';

class ServicesLocator {
  static final GetIt locator = GetIt.instance;

  static void setup() {
    // Dio & ApiService
    final Dio dio = DioFactory.getDio();
    locator.registerLazySingleton<ApiService>(() => ApiService(dio));

    // intro app
    locator.registerLazySingleton<IntroAppCubit>(() => IntroAppCubit());

    // Repositories (In-memory mock implementations for interactive session)
    locator.registerLazySingleton<HallsRepository>(() => MockHallsRepository());
    locator.registerLazySingleton<CalendarRepository>(() => MockCalendarRepository());
    locator.registerLazySingleton<BookingsRepository>(() => MockBookingsRepository());
    locator.registerLazySingleton<CustomersRepository>(() => MockCustomersRepository());
    locator.registerLazySingleton<ExpensesRepository>(() => MockExpensesRepository());
    locator.registerLazySingleton<InventoryRepository>(() => MockInventoryRepository());
    locator.registerLazySingleton<WorkersRepository>(() => MockWorkersRepository());
    locator.registerLazySingleton<NotificationsRepository>(() => MockNotificationsRepository());
    locator.registerLazySingleton<SettingsRepository>(() => MockSettingsRepository());
    locator.registerLazySingleton<ReportsRepository>(() => MockReportsRepository());
  }

  static IntroAppCubit get introAppCubit => locator<IntroAppCubit>();
  static HallsRepository get hallsRepo => locator<HallsRepository>();
  static CalendarRepository get calendarRepo => locator<CalendarRepository>();
  static BookingsRepository get bookingsRepo => locator<BookingsRepository>();
  static CustomersRepository get customersRepo => locator<CustomersRepository>();
  static ExpensesRepository get expensesRepo => locator<ExpensesRepository>();
  static InventoryRepository get inventoryRepo => locator<InventoryRepository>();
  static WorkersRepository get workersRepo => locator<WorkersRepository>();
  static NotificationsRepository get notificationsRepo => locator<NotificationsRepository>();
  static SettingsRepository get settingsRepo => locator<SettingsRepository>();
  static ReportsRepository get reportsRepo => locator<ReportsRepository>();
}
