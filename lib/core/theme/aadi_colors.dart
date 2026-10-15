import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Small semantic color set for trust/verification UI, derived from the
/// brand palette plus the active [ColorScheme] so it adapts to light/dark.
class AadiColors {
  const AadiColors({
    required this.verified,
    required this.warning,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.outlineDefault,
  });

  final Color verified;
  final Color warning;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color outlineDefault;

  static AadiColors of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AadiColors(
      verified: AppColors.teal,
      warning: AppColors.orange,
      surfaceSecondary: scheme.surfaceContainerHighest,
      surfaceTertiary: AppColors.teal95,
      outlineDefault: scheme.outlineVariant,
    );
  }
}

extension AadiColorsX on BuildContext {
  AadiColors get aadiColors => AadiColors.of(this);
}
