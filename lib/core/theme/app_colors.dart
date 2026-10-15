import 'package:flutter/material.dart';

/// Aadi brand palette (from DESIGN.md). Teal leads; orange is the single
/// accent — keep the palette restricted to teal, orange, and neutrals.
class AppColors {
  AppColors._();

  // Teal (primary)
  static const Color teal = Color(0xFF1FA6A0);
  static const Color tealDark = Color(0xFF0B3A38);
  static const Color teal80 = Color(0xFF8FD9D5);
  static const Color teal90 = Color(0xFFC4ECEA);
  static const Color teal95 = Color(0xFFE3F6F4);

  // Orange (accent)
  static const Color orange = Color(0xFFF59E42);
  static const Color orangeDeep = Color(0xFFD9822B);
  static const Color orange90 = Color(0xFFFCE6CE);
  static const Color orange95 = Color(0xFFFDF3E9);

  // Neutrals
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral10 = Color(0xFFF7F8FA);
  static const Color neutral20 = Color(0xFFEDF0F4);
  static const Color neutral30 = Color(0xFFDDE2E9);
  static const Color neutral60 = Color(0xFF7D8794);
  static const Color neutral80 = Color(0xFF4A525E);
  static const Color neutral100 = Color(0xFF252A31);

  // Aliases used throughout the app.
  static const Color primary = teal;
  static const Color secondary = orange;
  static const Color accent = orange;
  static const Color surface = neutral10;
  static const Color textDark = neutral100;
  static const Color success = teal;
  static const Color danger = orangeDeep;
}
