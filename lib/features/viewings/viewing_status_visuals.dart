import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';

/// Shared icon + accent color for a viewing status.
(IconData, Color) viewingStatusVisual(
  ViewingStatus status,
  ColorScheme scheme,
) => switch (status) {
  ViewingStatus.pending => (Icons.schedule_rounded, AppColors.accent),
  ViewingStatus.confirmed => (Icons.check_circle_rounded, AppColors.primary),
  ViewingStatus.rescheduled => (Icons.update_rounded, AppColors.accent),
  ViewingStatus.declined => (Icons.cancel_rounded, scheme.error),
};

/// Rounded status avatar used on request rows and detail headers.
class ViewingStatusAvatar extends StatelessWidget {
  const ViewingStatusAvatar({super.key, required this.status, this.size = 48});

  final ViewingStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = viewingStatusVisual(
      status,
      Theme.of(context).colorScheme,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(icon, color: color),
    );
  }
}

/// Small icon + label pill communicating a request's status. Distinguished by
/// icon and text (never color alone).
class ViewingStatusChip extends StatelessWidget {
  const ViewingStatusChip({super.key, required this.status});

  final ViewingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = viewingStatusVisual(status, scheme);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
