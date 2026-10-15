import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens — subtle tonal shadows (design-system style).
abstract final class AppElevation {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x0F252A31), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x14252A31), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(color: Color(0x1F252A31), blurRadius: 28, offset: Offset(0, 10)),
  ];

  static List<BoxShadow> overlay = [
    BoxShadow(
      color: AppColors.neutral100.withValues(alpha: 0.16),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}
