import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:qa3ty_app/core/config/env.dart';
import 'package:qa3ty_app/core/networking/api_service.dart';
import 'package:qa3ty_app/core/networking/dio_factory.dart';
import 'package:qa3ty_app/core/networking/token_storage.dart';
import 'package:qa3ty_app/core/cubit/intro_app/intro_app_cubit.dart';
import 'package:qa3ty_app/features/auth/export.dart';
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
import 'package:qa3ty_app/features/sub_accounts/data/services/sub_accounts_service.dart';

class ServicesLocator {
  static final GetIt locator = GetIt.instance;

  static void setup() {
    // Dio & ApiService
    final Dio dio = DioFactory.getDio();
    locator.registerLazySingleton<ApiService>(() => ApiService(dio));

    // TokenStorage & Auth
    locator.registerLazySingleton<TokenStorage>(TokenStorage.new);
    locator.registerLazySingleton<AuthRepository>(() {
      return AppConfig.current.useMockData
          ? MockAuthRepository()
          : RemoteAuthRepository(dio, locator<TokenStorage>());
    });
    locator.registerLazySingleton<AuthCubit>(() {
      return AuthCubit(locator<AuthRepository>());
    });
    DioFactory.setSubscriptionExpiredCallback((message) {
      authCubit.onSubscriptionExpired(message);
    });

    // intro app
    locator.registerLazySingleton<IntroAppCubit>(IntroAppCubit.new);

    final bool useMock = AppConfig.current.useMockData;

    // Repositories
    locator.registerLazySingleton<HallsRepository>(
        () => useMock ? MockHallsRepository() : RemoteHallsRepository(dio));
    locator.registerLazySingleton<CalendarRepository>(() =>
        useMock ? MockCalendarRepository() : RemoteCalendarRepository(dio));
    locator.registerLazySingleton<BookingsRepository>(() =>
        useMock ? MockBookingsRepository() : RemoteBookingsRepository(dio));
    locator.registerLazySingleton<CustomersRepository>(() =>
        useMock ? MockCustomersRepository() : RemoteCustomersRepository(dio));
    locator.registerLazySingleton<ExpensesRepository>(() =>
        useMock ? MockExpensesRepository() : RemoteExpensesRepository(dio));
    locator.registerLazySingleton<InventoryRepository>(() =>
        useMock ? MockInventoryRepository() : RemoteInventoryRepository());
    locator.registerLazySingleton<WorkersRepository>(
        () => useMock ? MockWorkersRepository() : RemoteWorkersRepository());
    locator.registerLazySingleton<NotificationsRepository>(() => useMock
        ? MockNotificationsRepository()
        : RemoteNotificationsRepository());
    locator.registerLazySingleton<SettingsRepository>(
        () => useMock ? MockSettingsRepository() : RemoteSettingsRepository());
    locator.registerLazySingleton<ReportsRepository>(
        () => useMock ? MockReportsRepository() : RemoteReportsRepository());
    locator.registerLazySingleton<SubAccountsService>(
        () => SubAccountsService(dio));
  }

  static TokenStorage get tokenStorage => locator<TokenStorage>();
  static AuthRepository get authRepo => locator<AuthRepository>();
  static AuthCubit get authCubit => locator<AuthCubit>();
  static IntroAppCubit get introAppCubit => locator<IntroAppCubit>();
  static HallsRepository get hallsRepo => locator<HallsRepository>();
  static CalendarRepository get calendarRepo => locator<CalendarRepository>();
  static BookingsRepository get bookingsRepo => locator<BookingsRepository>();
  static CustomersRepository get customersRepo =>
      locator<CustomersRepository>();
  static ExpensesRepository get expensesRepo => locator<ExpensesRepository>();
  static InventoryRepository get inventoryRepo =>
      locator<InventoryRepository>();
  static WorkersRepository get workersRepo => locator<WorkersRepository>();
  static NotificationsRepository get notificationsRepo =>
      locator<NotificationsRepository>();
  static SettingsRepository get settingsRepo => locator<SettingsRepository>();
  static ReportsRepository get reportsRepo => locator<ReportsRepository>();
  static SubAccountsService get subAccountsService =>
      locator<SubAccountsService>();
}
