import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// A friendly, time-aware welcome. Reused on the tenant Explore feed and the
/// landlord Insights dashboard so both roles get a consistent greeting.
class AadiGreetingHeader extends StatelessWidget {
  const AadiGreetingHeader({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String? name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = _firstNameOf(name);
    final greeting = _greetingForHour(DateTime.now().hour);
    final title = firstName == null ? greeting : '$greeting, $firstName';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps an hour of day (0-23) to a friendly greeting.
String _greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Returns the first word of a name, or null when there is nothing to show.
String? _firstNameOf(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed.split(RegExp(r'\s+')).first;
}
