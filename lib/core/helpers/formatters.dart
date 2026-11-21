import 'package:intl/intl.dart';

extension ArabicDigitsExtension on Object? {
  /// Converts English digits 0-9 into Arabic-Indic digits ٠-٩
  String toArabicDigits() {
    if (this == null) return '';
    final str = toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    var result = str;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}

class AppFormatters {
  static final NumberFormat _currencyFormatter = NumberFormat('#,###', 'en');

  /// Converts ASCII comma thousands separator to Arabic thousands mark (٬ U+066C)
  static String _toArabicSeparator(String s) => s.replaceAll(',', '\u066C');

  /// Format money with Arabic thousands separator "٬" and " ج.م"
  /// e.g. 45000 -> "٤٥٬٠٠٠ ج.م"
  static String formatMoney(num amount) {
    final formatted = _currencyFormatter.format(amount);
    return '${_toArabicSeparator(formatted).toArabicDigits()} ج.م';
  }

  /// Format money without currency symbol: e.g. 480000 -> "٤٨٠٬٠٠٠"
  static String formatMoneyOnly(num amount) {
    final formatted = _currencyFormatter.format(amount);
    return _toArabicSeparator(formatted).toArabicDigits();
  }

  /// Day names in Arabic starting from Saturday
  static const List<String> arabicWeekdays = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  /// Short day names for calendar header
  static const List<String> arabicWeekdaysShort = [
    'سبت',
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
  ];

  /// Month names in Arabic
  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Format date to e.g. "الثلاثاء ١٥ ديسمبر ٢٠٢٦"
  static String formatFullDate(DateTime date) {
    // DateTime.weekday: Monday = 1 ... Sunday = 7
    // Mapping: Monday(1)->الاثنين, Tuesday(2)->الثلاثاء, Wednesday(3)->الأربعاء,
    // Thursday(4)->الخميس, Friday(5)->الجمعة, Saturday(6)->السبت, Sunday(7)->الأحد
    final weekdayNames = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = weekdayNames[date.weekday];
    final monthName = arabicMonths[date.month - 1];
    final dayNumber = date.day.toArabicDigits();
    final year = date.year.toArabicDigits();

    return '$dayName $dayNumber $monthName $year';
  }

  /// Format date to "الثلاثاء ١٥ ديسمبر"
  static String formatDayMonth(DateTime date) {
    final weekdayNames = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = weekdayNames[date.weekday];
    final monthName = arabicMonths[date.month - 1];
    final dayNumber = date.day.toArabicDigits();

    return '$dayName $dayNumber $monthName';
  }

  /// Format date to "ديسمبر ٢٠٢٦"
  static String formatMonthYear(DateTime date) {
    final monthName = arabicMonths[date.month - 1];
    final year = date.year.toArabicDigits();
    return '$monthName $year';
  }
}
