import 'package:flutter/material.dart';

import '../../core/theme/aadi_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/trust_badge.dart';

/// Icon for a verification badge type.
IconData badgeIcon(BadgeType type) => switch (type) {
  BadgeType.emailVerified => Icons.mark_email_read_outlined,
  BadgeType.phoneVerified => Icons.phone_iphone_rounded,
  BadgeType.idVerified => Icons.badge_outlined,
  BadgeType.landlordVerified => Icons.verified_user_outlined,
  BadgeType.propertyVerified => Icons.home_work_outlined,
  BadgeType.reliableTenant => Icons.handshake_outlined,
  BadgeType.responsive => Icons.bolt_outlined,
};

/// Icon for a verification status.
IconData verificationIcon(VerificationStatus status) => switch (status) {
  VerificationStatus.verified => Icons.verified_rounded,
  VerificationStatus.pending => Icons.hourglass_bottom_rounded,
  VerificationStatus.rejected => Icons.gpp_bad_outlined,
  VerificationStatus.none => Icons.shield_outlined,
};

/// Server-computed reputation, shown as a tonal chip. Displays "New to Aadi"
/// until the account has enough signals.
class TrustScoreChip extends StatelessWidget {
  const TrustScoreChip({super.key, required this.score, required this.isNew});

  final int score;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final aadi = context.aadiColors;
    if (isNew) {
      return _TrustPill(
        icon: Icons.spa_outlined,
        label: 'New to Aadi',
        foreground: Theme.of(context).colorScheme.onSurfaceVariant,
        background: aadi.surfaceSecondary,
        border: aadi.outlineDefault,
      );
    }
    return _TrustPill(
      icon: Icons.shield_rounded,
      label: 'Trust score $score',
      foreground: aadi.verified,
      background: aadi.surfaceTertiary,
    );
  }
}

/// Consistent star rating display. Shows "New" when there are no reviews yet.
class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.average,
    required this.count,
    this.dense = false,
  });

  final double average;
  final int count;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (count == 0) {
      return Text(
        'New',
        style: dense ? textTheme.bodySmall : textTheme.bodyMedium,
      );
    }
    final iconSize = dense ? 16.0 : 20.0;
    return Semantics(
      label: '${average.toStringAsFixed(1)} out of 5, $count reviews',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: iconSize, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            average.toStringAsFixed(1),
            style: dense ? textTheme.bodySmall : textTheme.titleSmall,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text('($count)', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A single verification badge as a tonal chip. Verified badges use the brand
/// "verified" color; pending badges are muted and suffixed with "· pending".
class VerificationBadgeChip extends StatelessWidget {
  const VerificationBadgeChip({super.key, required this.badge});

  final TrustBadge badge;

  @override
  Widget build(BuildContext context) {
    final aadi = context.aadiColors;
    final verified = badge.isVerified;
    final pending = badge.status == VerificationStatus.pending;
    final foreground = verified
        ? aadi.verified
        : (pending
              ? aadi.warning
              : Theme.of(context).colorScheme.onSurfaceVariant);

    return _TrustPill(
      icon: verified ? Icons.check_circle_rounded : badgeIcon(badge.type),
      label: pending ? '${badge.type.shortLabel} · pending' : badge.type.label,
      foreground: foreground,
      background: verified ? aadi.surfaceTertiary : aadi.surfaceSecondary,
      border: verified ? null : aadi.outlineDefault,
    );
  }
}

/// A wrap of verification badges, skipping ungranted/rejected ones. Renders
/// [emptyText] (when provided) if there are no badges to show.
class TrustBadgeList extends StatelessWidget {
  const TrustBadgeList({super.key, required this.badges, this.emptyText});

  final List<TrustBadge> badges;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final visible = badges
        .where(
          (b) =>
              b.status == VerificationStatus.verified ||
              b.status == VerificationStatus.pending,
        )
        .toList();

    if (visible.isEmpty) {
      final text = emptyText;
      if (text == null) return const SizedBox.shrink();
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final badge in visible) VerificationBadgeChip(badge: badge),
      ],
    );
  }
}

/// Per-listing property verification chip. Renders nothing when the property is
/// unverified so absence, not a negative label, communicates "not verified".
class PropertyTrustChip extends StatelessWidget {
  const PropertyTrustChip({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final aadi = context.aadiColors;
    switch (status) {
      case VerificationStatus.verified:
        return _TrustPill(
          icon: Icons.verified_rounded,
          label: 'Verified property',
          foreground: aadi.verified,
          background: aadi.surfaceTertiary,
        );
      case VerificationStatus.pending:
        return _TrustPill(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Verification pending',
          foreground: aadi.warning,
          background: aadi.surfaceSecondary,
          border: aadi.outlineDefault,
        );
      case VerificationStatus.none:
      case VerificationStatus.rejected:
        return const SizedBox.shrink();
    }
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.border,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
