import 'package:flutter/material.dart';

/// Quicksand-based type scale for Aadi (design-system typography).
///
/// Quicksand is bundled as a local variable font (see `pubspec.yaml`) so text
/// renders correctly offline and on the first frame — no runtime font fetch.
abstract final class AppTypography {
  static const String fontFamily = 'Quicksand';

  static TextTheme textTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    final t = base.apply(fontFamily: fontFamily);
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
      ),
      displayMedium: t.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displaySmall: t.displaySmall?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: t.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: t.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      bodySmall: t.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Price / figure style with tabular numerals for stable alignment.
  static TextStyle price(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
