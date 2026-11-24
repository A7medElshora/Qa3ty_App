import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/navigation/scaffold_with_nav_bar.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/core/helpers/formatters.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_nav.dart';
import 'package:qa3ty_app/core/utils/widgets/day_circle.dart';
import 'package:qa3ty_app/features/halls/data/models/hall_model.dart';
import 'package:qa3ty_app/features/halls/presentation/cubits/halls_cubit.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/halls_home_screen.dart';
import 'package:qa3ty_app/features/auth/data/models/user_model.dart';
import 'package:qa3ty_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:qa3ty_app/features/calendar/presentation/screens/monthly_calendar_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:qa3ty_app/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:qa3ty_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:qa3ty_app/features/more/presentation/screens/more_screen.dart';

Widget createTestWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, c) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: c!,
        );
      },
      theme: ThemeData(
        fontFamily: AppTextStyles.fontFamily,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: child,
    ),
  );
}

Widget createHallsTestWidget() {
  return BlocProvider(
    create: (_) => HallsCubit(ServicesLocator.hallsRepo)..loadHalls(),
    child: createTestWidget(const HallsHomeScreen()),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ServicesLocator.setup();
  });

  group('Screen 1: HallsHomeScreen (قاعاتي) Tests', () {
    testWidgets('renders all components matching design at 390 width',
        (tester) async {
      ServicesLocator.authCubit.emit(
        const Authenticated(
          AppUser(
            id: 'test-user',
            username: 'gemy',
            fullName: 'جمال الشيخ',
            role: 'tenant_admin',
            isPrimary: true,
            permissions: UserPermissions(
              canManageBookings: true,
              canViewReports: true,
              canManageExpenses: true,
              canManageInventory: true,
              canManageWorkers: true,
              canManageSubAccounts: true,
            ),
          ),
        ),
      );
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createHallsTestWidget());
      await tester.pumpAndSettle();

      // 1) Verify Header
      expect(find.text('مرحباً، جمال الشيخ'), findsOneWidget);
      expect(find.text('قاعاتي'), findsOneWidget);

      // 2) Verify AlertStrip
      expect(find.text('٢ فعاليات خلال ٧ أيام عليها مبالغ متبقية'),
          findsOneWidget);
      expect(find.text('عرض'), findsOneWidget);

      // 3) Verify Halls Cards
      expect(find.text('قاعة الماسة'), findsOneWidget);
      expect(find.text('طنطا، الغربية'), findsOneWidget);
      expect(find.text('٦٠٠ مقعد'), findsOneWidget);

      expect(find.text('قاعة النخيل'), findsOneWidget);
      expect(find.text('المنصورة، الدقهلية'), findsOneWidget);
      expect(find.text('٣٥٠ مقعد'), findsOneWidget);

      // 4) Verify Week summaries
      expect(find.text('هذا الأسبوع: ٤ حجوزات'), findsOneWidget);
      expect(find.text('هذا الأسبوع: ٢ حجوزات'), findsOneWidget);

      // 5) Verify Legend
      expect(find.text('متاح'), findsOneWidget);
      expect(find.text('مدفوع'), findsOneWidget);
      expect(find.text('عربون'), findsOneWidget);
      expect(find.text('مؤقت'), findsOneWidget);
      expect(find.text('محجوب'), findsOneWidget);
    });

    testWidgets('shows a prominent first-hall action when no halls exist',
        (tester) async {
      final repository = ServicesLocator.hallsRepo;
      final halls = await tester.runAsync(repository.getHalls) ?? [];
      for (final hall in halls) {
        await tester.runAsync(() => repository.deleteHall(hall.id));
      }

      try {
        await tester.pumpWidget(createHallsTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('ابدأ بإضافة أول قاعة'), findsOneWidget);
        expect(find.text('أضف أول قاعة الآن'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      } finally {
        for (final hall in halls) {
          await tester.runAsync(() => repository.addHall(hall));
        }
      }
    });

    testWidgets('reloads halls after returning from the add-hall form',
        (tester) async {
      final repository = ServicesLocator.hallsRepo;
      final originalHalls = await tester.runAsync(repository.getHalls) ?? [];
      const testHall = Hall(
        id: 'refresh_test_hall',
        name: 'قاعة اختبار التحديث',
        location: 'القاهرة',
        capacity: 100,
        currentWeekSchedule: [],
        weekBookingsCount: 0,
        weekRemainingAmount: 0,
      );

      for (final hall in originalHalls) {
        await tester.runAsync(() => repository.deleteHall(hall.id));
      }

      final router = GoRouter(
        initialLocation: '/halls',
        routes: [
          GoRoute(
            path: '/halls',
            builder: (context, state) => const HallsHomeScreen(),
          ),
          GoRoute(
            path: '/halls/form',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  await repository.addHall(testHall);
                  if (context.mounted) context.pop();
                },
                child: const Text('حفظ القاعة الاختبارية'),
              ),
            ),
          ),
        ],
      );

      try {
        await tester.pumpWidget(
          BlocProvider(
            create: (_) => HallsCubit(repository)..loadHalls(),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              child: MaterialApp.router(
                locale: const Locale('ar'),
                routerConfig: router,
                builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
                theme: ThemeData(fontFamily: AppTextStyles.fontFamily),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('أضف أول قاعة الآن'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('حفظ القاعة الاختبارية'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(find.text('قاعة اختبار التحديث'), findsOneWidget);
      } finally {
        await tester.runAsync(() async {
          await repository.deleteHall(testHall.id);
          for (final hall in originalHalls) {
            await repository.addHall(hall);
          }
        });
        router.dispose();
      }
    });
  });

  testWidgets('bottom navigation fits long selected labels on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 1,
            onTap: _ignoreTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navRect = tester.getRect(find.byType(AppBottomNav));
    expect(navRect.bottom, 800);
    expect(navRect.height, lessThan(90));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reloads halls whenever the halls tab is revisited',
      (tester) async {
    final repository = ServicesLocator.hallsRepo;
    final originalHalls = await tester.runAsync(repository.getHalls) ?? [];
    const hall = Hall(
      id: 'tab_refresh_test',
      name: 'قاعة التحديث عند العودة',
      location: 'المنوفية',
      capacity: 250,
      currentWeekSchedule: [],
      weekBookingsCount: 0,
      weekRemainingAmount: 0,
    );
    await tester.runAsync(() async {
      for (final existingHall in originalHalls) {
        await repository.deleteHall(existingHall.id);
      }
    });

    final router = GoRouter(
      initialLocation: '/halls',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => BlocProvider(
            create: (_) => HallsCubit(repository)..loadHalls(),
            child: ScaffoldWithNavBar(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/halls',
                  builder: (context, state) => const HallsHomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/expenses',
                  builder: (context, state) =>
                      const Scaffold(body: Text('صفحة المصروفات')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    try {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
            theme: ThemeData(fontFamily: AppTextStyles.fontFamily),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ابدأ بإضافة أول قاعة'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.receipt));
      await tester.pumpAndSettle();
      await tester.runAsync(() => repository.addHall(hall));

      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byIcon(LucideIcons.building2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hall.name), findsOneWidget);
    } finally {
      await tester.runAsync(() async {
        await repository.deleteHall(hall.id);
        for (final existingHall in originalHalls) {
          await repository.addHall(existingHall);
        }
      });
      router.dispose();
    }
  });

  group('Screen 2: MonthlyCalendarScreen (التقويم الشهري) Tests', () {
    testWidgets('starts on today and renders the current month length',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(const MonthlyCalendarScreen(hallId: 'masia')),
      );
      await tester.pumpAndSettle();

      final today = DateTime.now();
      expect(
        find.text(AppFormatters.formatMonthYear(today)),
        findsOneWidget,
      );

      final dayCircles =
          tester.widgetList<DayCircle>(find.byType(DayCircle)).toList();
      final dateCircles =
          dayCircles.where((circle) => circle.dayNumber != null).toList();
      expect(
        dateCircles.where((circle) => circle.isSelected).single.dayNumber,
        today.day,
      );
      expect(
        dateCircles.length,
        DateTime(today.year, today.month + 1, 0).day,
      );
    });

    testWidgets('renders all monthly calendar elements matching design',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          MonthlyCalendarScreen(
            hallId: 'masia',
            initialMonth: DateTime(2026, 12, 1),
            initialSelectedDay: 15,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1) Verify Header
      expect(find.text('قاعة الماسة'), findsOneWidget);
      expect(find.text('٦٠٠ مقعد · طنطا، الغربية'), findsOneWidget);

      // 2) Verify Month title & Today chip
      expect(find.text('ديسمبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);

      // 3) Verify Month Summary Card
      expect(find.text('١٤ يوم'), findsOneWidget);
      expect(find.text('محجوز'), findsOneWidget);
      expect(find.text('٤٨٠٬٠٠٠'), findsOneWidget);
      expect(find.text('المتوقع (ج.م)'), findsOneWidget);
      expect(find.text('٣١٠٬٠٠٠'), findsOneWidget);
      expect(find.text('المُحصَّل (ج.م)'), findsOneWidget);

      // 4) Verify Filter Chips
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('عربون فقط'), findsAtLeastNWidgets(1));
      expect(find.text('مدفوع'), findsOneWidget);
      expect(find.text('مؤقت'), findsOneWidget);

      // 5) Verify Selected Day 15 Preview Bottom Sheet
      expect(find.text('الثلاثاء ١٥ ديسمبر'), findsOneWidget);
      expect(find.text('محمد عبد الله · حفل زفاف'), findsOneWidget);
      expect(find.text('٨:٠٠ م – ١:٠٠ ص · ٤٥٠ مقعد'), findsOneWidget);
      expect(find.text('فتح التفاصيل'), findsOneWidget);
      expect(find.text('إضافة دفعة'), findsOneWidget);

      // 6) Verify Remaining Amounts Section
      expect(find.text('مبالغ متبقية'), findsOneWidget);
      expect(find.text('سارة محمود'), findsOneWidget);
      expect(find.text('كريم ياسر'), findsOneWidget);
    });

    testWidgets('shows metadata for the selected hall from the repository',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const hall = Hall(
        id: 'calendar_metadata_test',
        name: 'قاعة جاردينيا الحقيقية',
        location: 'الشهداء',
        capacity: 350,
        currentWeekSchedule: [],
        weekBookingsCount: 0,
        weekRemainingAmount: 0,
      );
      final repository = ServicesLocator.hallsRepo;

      try {
        await tester.runAsync(() => repository.addHall(hall));
        await tester.pumpWidget(
          createTestWidget(
            const MonthlyCalendarScreen(hallId: 'calendar_metadata_test'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(hall.name), findsOneWidget);
        expect(find.text('٣٥٠ مقعد · الشهداء'), findsOneWidget);
      } finally {
        await tester.runAsync(() => repository.deleteHall(hall.id));
      }
    });
  });

  testWidgets('expense form lists halls returned by the repository',
      (tester) async {
    const hall = Hall(
      id: 'expense_hall_test',
      name: 'قاعة تجريبية حقيقية',
      location: 'المنوفية',
      capacity: 200,
      currentWeekSchedule: [],
      weekBookingsCount: 0,
      weekRemainingAmount: 0,
    );
    final repository = ServicesLocator.hallsRepo;
    final originalHalls = await tester.runAsync(repository.getHalls) ?? [];

    try {
      await tester.runAsync(() async {
        for (final existingHall in originalHalls) {
          await repository.deleteHall(existingHall.id);
        }
        await repository.addHall(hall);
      });

      await tester.pumpWidget(createTestWidget(const ExpenseFormScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(hall.name), findsAtLeastNWidgets(1));
      expect(find.text('القاعة المعنية (١)'), findsOneWidget);
      expect(find.text('قاعة الماسة'), findsNothing);
      expect(find.text('قاعة النخيل'), findsNothing);
      expect(find.text('عام لجميع القاعات'), findsOneWidget);
    } finally {
      await tester.runAsync(() async {
        await repository.deleteHall(hall.id);
        for (final existingHall in originalHalls) {
          await repository.addHall(existingHall);
        }
      });
    }
  });

  group('Screen 3: BookingDetailsScreen (تفاصيل الحجز) Tests', () {
    testWidgets('renders all booking details cards matching design',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
          createTestWidget(const BookingDetailsScreen(bookingId: 1042)));
      await tester.pumpAndSettle();

      // 1) Verify Header
      expect(find.text('تفاصيل الحجز'), findsOneWidget);
      expect(find.text('حجز رقم #١٠٤٢'), findsOneWidget);

      // 2) Verify StatusBanner
      expect(find.textContaining('عربون مدفوع · متبقي'), findsOneWidget);
      expect(find.text('الفعالية بعد ٢٤ يوماً · موعد سداد المتبقي ٥ ديسمبر'),
          findsOneWidget);

      // 3) Verify Event Card
      expect(find.text('الفعالية'), findsOneWidget);
      expect(find.text('حفل زفاف'), findsOneWidget);
      expect(find.text('٤٥٠ مقعد'), findsOneWidget);

      // 4) Verify Customer Card
      expect(find.text('العميل'), findsOneWidget);
      expect(find.text('محمد عبد الله'), findsOneWidget);
      expect(find.text('٠١٠١٢٣٤٥٦٧٨'), findsOneWidget);
      expect(find.text('اتصال'), findsOneWidget);
      expect(find.text('واتساب'), findsOneWidget);
      expect(find.text('حجز آخر لنفس العميل في نفس اليوم: قاعة النخيل'),
          findsOneWidget);

      // 5) Verify Financials Card
      expect(find.text('الماليات'), findsOneWidget);
      expect(find.text('سعر القاعة'), findsOneWidget);
      expect(find.text('خدمات إضافية'), findsOneWidget);
      expect(find.text('سجل الدفعات (٢)'), findsOneWidget);
      expect(find.text('العربون · ١٠ أكتوبر'), findsOneWidget);
      expect(find.text('دفعة · ٣ نوفمبر'), findsOneWidget);

      // 6) Verify Services Card
      expect(find.text('البرنامج والخدمات'), findsOneWidget);
      expect(find.text('زفة'), findsOneWidget);
      expect(find.text('دي جي'), findsOneWidget);
      expect(find.text('دبكة'), findsOneWidget);
      expect(find.text('إضافة خدمة مخصصة'), findsOneWidget);

      // 7) Verify Notes Card
      expect(find.text('الملاحظات'), findsOneWidget);
      expect(find.text('ملاحظات الفعالية'), findsOneWidget);
      expect(find.text('تعليمات التجهيز'), findsOneWidget);
      expect(find.text('ملاحظات داخلية للموظفين'), findsOneWidget);

      // 8) Verify Fixed Bottom Buttons
      expect(find.text('إضافة دفعة'), findsOneWidget);
      expect(find.text('مشاركة الإيصال'), findsOneWidget);
    });
  });

  testWidgets(
      'hides financial dashboard amounts and booking controls without permissions',
      (tester) async {
    ServicesLocator.authCubit.emit(
      const Authenticated(
        AppUser(
          id: 'readonly-user',
          username: 'staff',
          fullName: 'موظف',
          role: 'tenant_staff',
          isPrimary: false,
          permissions: UserPermissions(
            canManageBookings: false,
            canViewReports: false,
            canManageExpenses: false,
            canManageInventory: false,
            canManageWorkers: false,
          ),
        ),
      ),
    );

    await tester.pumpWidget(createHallsTestWidget());
    await tester.pumpAndSettle();
    expect(find.textContaining('مستحق '), findsNothing);
    expect(find.text('٢ فعاليات خلال ٧ أيام عليها مبالغ متبقية'), findsNothing);

    await tester.pumpWidget(
      createTestWidget(
        MonthlyCalendarScreen(
          hallId: 'masia',
          initialMonth: DateTime(2026, 12, 1),
          initialSelectedDay: 15,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('المتوقع (ج.م)'), findsNothing);
    expect(find.text('المُحصَّل (ج.م)'), findsNothing);
    expect(find.text('مبالغ متبقية'), findsNothing);
    expect(find.text('إضافة دفعة'), findsNothing);

    await tester.pumpWidget(
      createTestWidget(const BookingDetailsScreen(bookingId: 1042)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.moreVertical));
    await tester.pumpAndSettle();
    expect(find.text('تعديل الحجز'), findsNothing);
    expect(find.text('إلغاء الحجز'), findsNothing);
    expect(find.text('إضافة دفعة'), findsNothing);

    await tester.pumpWidget(
      createTestWidget(
        const AppBottomNav(currentIndex: 0, onTap: _ignoreTap),
      ),
    );
    expect(find.text('المصروفات'), findsNothing);
  });

  testWidgets('exposes account management only to the primary account',
      (tester) async {
    ServicesLocator.authCubit.emit(
      const Authenticated(
        AppUser(
          id: 'primary-user',
          username: 'owner',
          fullName: 'صاحب القاعة',
          role: 'tenant_admin',
          isPrimary: true,
        ),
      ),
    );
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('إدارة الحسابات والصلاحيات'), findsOneWidget);

    ServicesLocator.authCubit.emit(
      const Authenticated(
        AppUser(
          id: 'staff-user',
          username: 'staff',
          fullName: 'موظف',
          role: 'tenant_staff',
          isPrimary: false,
        ),
      ),
    );
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('إدارة الحسابات والصلاحيات'), findsNothing);
  });

  testWidgets('hides restricted sections from the More screen', (tester) async {
    ServicesLocator.authCubit.emit(
      const Authenticated(
        AppUser(
          id: 'staff-user',
          username: 'staff',
          fullName: 'موظف',
          role: 'tenant_staff',
          permissions: UserPermissions(
            canManageBookings: false,
            canViewReports: false,
            canManageExpenses: false,
            canManageInventory: false,
            canManageWorkers: false,
          ),
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const MoreScreen()));

    expect(find.text('المصروفات والتكاليف'), findsNothing);
    expect(find.text('المخزون والمستلزمات'), findsNothing);
    expect(find.text('شؤون العمال والموظفين'), findsNothing);
    expect(find.text('التقارير المالية والأرباح'), findsNothing);
    expect(find.text('كافة الحجوزات'), findsOneWidget);
  });
}

void _ignoreTap(int _) {}
