import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTextStyles {
  static const String fontFamily = 'Cairo';
  static const double baseHeight = 1.4;

  // display: 28 / w700 / Primary (عنوان "قاعاتي")
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: baseHeight,
  );

  // screenTitle: 20 / w700 / Ink
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  // cardTitle: 18 / w700 / Ink
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  // sectionTitle: 15-16 / w700 / Ink
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  static const TextStyle sectionTitle15 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  // body: 13-14 / w500-w600
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: baseHeight,
  );

  static const TextStyle body13 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: baseHeight,
  );

  // muted: 12 / w400 / Muted
  static const TextStyle muted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: baseHeight,
  );

  static const TextStyle muted13 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: baseHeight,
  );

  // caption: 10-11 / w400-w500
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: baseHeight,
  );

  static const TextStyle caption10 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: baseHeight,
  );

  // button: 14 / w700
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: baseHeight,
  );

  // chip: 11-12 / w700
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  static const TextStyle chip11 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: baseHeight,
  );

  // bigAmount: 16 / w700 (أرقام ملخص الشهر)
  static const TextStyle bigAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: baseHeight,
  );

  // Legacy styles for backward compatibility
  static const TextStyle font13_400Weight = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle font15_500Weight = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static InputBorder borderDone() {
    return OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    );
  }

  static InputBorder borderFocuse() {
    return OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      borderRadius: BorderRadius.circular(14),
    );
  }

  static InputBorder borderError(BuildContext context) {
    return OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      borderRadius: BorderRadius.circular(14),
    );
  }
}

// Backward compatibility alias
typedef AppStyle = AppTextStyles;
