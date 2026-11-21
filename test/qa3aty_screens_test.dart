import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/core/utils/constant/app_color.dart';
import 'package:qa3ty_app/core/utils/constant/app_style.dart';
import 'package:qa3ty_app/features/halls/presentation/screens/halls_home_screen.dart';
import 'package:qa3ty_app/features/calendar/presentation/screens/monthly_calendar_screen.dart';
import 'package:qa3ty_app/features/bookings/presentation/screens/booking_details_screen.dart';

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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ServicesLocator.setup();
  });

  group('Screen 1: HallsHomeScreen (قاعاتي) Tests', () {
    testWidgets('renders all components matching design at 390 width', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const HallsHomeScreen()));
      await tester.pumpAndSettle();

      // 1) Verify Header
      expect(find.text('مرحباً، أحمد'), findsOneWidget);
      expect(find.text('قاعاتي'), findsOneWidget);

      // 2) Verify AlertStrip
      expect(find.text('٢ فعاليات خلال ٧ أيام عليها مبالغ متبقية'), findsOneWidget);
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
  });

  group('Screen 2: MonthlyCalendarScreen (التقويم الشهري) Tests', () {
    testWidgets('renders all monthly calendar elements matching design', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const MonthlyCalendarScreen(hallId: 'masia')));
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
  });

  group('Screen 3: BookingDetailsScreen (تفاصيل الحجز) Tests', () {
    testWidgets('renders all booking details cards matching design', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const BookingDetailsScreen(bookingId: 1042)));
      await tester.pumpAndSettle();

      // 1) Verify Header
      expect(find.text('تفاصيل الحجز'), findsOneWidget);
      expect(find.text('حجز رقم #١٠٤٢'), findsOneWidget);

      // 2) Verify StatusBanner
      expect(find.textContaining('عربون مدفوع · متبقي'), findsOneWidget);
      expect(find.text('الفعالية بعد ٢٤ يوماً · موعد سداد المتبقي ٥ ديسمبر'), findsOneWidget);

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
      expect(find.text('حجز آخر لنفس العميل في نفس اليوم: قاعة النخيل'), findsOneWidget);

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
}
