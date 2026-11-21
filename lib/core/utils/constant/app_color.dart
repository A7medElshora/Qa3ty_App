import 'package:flutter/material.dart';

class AppColors {
  // Main palette from design specifications
  static const Color background = Color(0xFFF6F3EC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2B2D5B); // Indigo dark: buttons, dark headers, titles
  static const Color primarySoftText = Color(0xFFB9BBDD); // Secondary text on primary bg
  static const Color gold = Color(0xFFC9A24B);
  static const Color ink = Color(0xFF1B1C2E); // Primary text
  static const Color muted = Color(0xFF6B6F85); // Secondary text
  static const Color line = Color(0xFFE7E3D8); // Dividers and borders

  // Status colors & backgrounds
  static const Color green = Color(0xFF2E9E6B); // Fully paid
  static const Color greenBg = Color(0xFFDDF3E8);

  static const Color amber = Color(0xFFE8A317); // Deposit / remaining
  static const Color amberBg = Color(0xFFFDF3DC);
  static const Color amberText = Color(0xFF9A6A00);

  static const Color red = Color(0xFFD64545); // Overdue / delete
  static const Color redBg = Color(0xFFFBE6E6);

  static const Color purple = Color(0xFF7C5CC4); // Tentative / internal notes
  static const Color purpleBg = Color(0xFFEEE8FA);

  static const Color grey = Color(0xFFC9CCD6); // Available circles border
  static const Color greyBg = Color(0xFFECEDF1);

  static const Color tabInactive = Color(0xFF9094A6);
  static const Color white = Color(0xFFFFFFFF);

  // Card shadow: rgba(26,26,51,0.08) offset (0,4) blur 14
  static const Color cardShadowColor = Color.fromRGBO(26, 26, 51, 0.08);

  static final List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color.fromRGBO(26, 26, 51, 0.08),
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> topBarShadow = [
    const BoxShadow(
      color: Color.fromRGBO(26, 26, 51, 0.06),
      offset: Offset(0, -4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  // Legacy aliases for backward compatibility with template widgets
  static const Color backGroundColor = background;
  static const Color primaryColor = primary;
  static const Color secondaryColor = gold;
  static const Color titleColor = ink;
  static const Color subTitleColor = muted;
  static const Color whiteColor = white;
  static const Color hintColor = tabInactive;
  static const Color containerColor = background;
  static const Color borderColor = line;
  static const Color borderContainerColor = line;
}

// Backward compatibility alias
typedef AppColor = AppColors;
