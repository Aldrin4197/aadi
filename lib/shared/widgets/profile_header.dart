import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Centered identity header shared by the self and public profile screens so
/// both roles present the same layout and type scale.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.roleIcon,
    this.roleHighlighted = false,
    this.secondary,
  });

  final String name;
  final String roleLabel;
  final IconData roleIcon;

  /// Tints the role icon with the brand color (e.g. verified landlord).
  final bool roleHighlighted;

  /// Optional secondary line under the name, e.g. the email on your own profile.
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final roleColor = roleHighlighted
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(name, style: textTheme.titleLarge, textAlign: TextAlign.center),
        if (secondary != null && secondary!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            secondary!,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcon, size: 16, color: roleColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                roleLabel,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
