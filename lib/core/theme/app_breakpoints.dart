import 'package:flutter/widgets.dart';

/// Responsive breakpoints and helpers.
abstract final class AppBreakpoints {
  /// Below this width: single-column phone layout.
  static const double compact = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
}
