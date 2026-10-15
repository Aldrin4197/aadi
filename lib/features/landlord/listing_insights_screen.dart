import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../shared/widgets/app_network_image.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/stat_card.dart';
import '../tenant/listing_detail_screen.dart' show listingByIdProvider;
import 'listing_analytics.dart';

/// Per-listing performance dashboard for the owner.
class ListingInsightsScreen extends ConsumerWidget {
  const ListingInsightsScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingByIdProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Listing insights')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetryView(
          message: 'We couldn\'t load this listing. Please try again.',
          onRetry: () => ref.invalidate(listingByIdProvider(listingId)),
        ),
        data: (listing) {
          final analytics = ref.watch(listingAnalyticsProvider(listingId));
          final photo = listing.photos.isNotEmpty ? listing.photos.first : null;
          final conversion =
              '${(analytics.conversionRate * 100).toStringAsFixed(1)}%';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _ListingHeader(
                    title: listing.title,
                    statusLabel: listing.status.label,
                    photo: photo,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Performance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.visibility_outlined,
                          label: 'Views',
                          value: NumberFormat.decimalPattern(
                            'en_US',
                          ).format(analytics.views),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.favorite_border_rounded,
                          label: 'Interested',
                          value: '${analytics.interested}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.event_note_outlined,
                          label: 'Viewing requests',
                          value: '${analytics.viewingRequests}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Inquiries',
                          value: '${analytics.inquiries}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Views that became requests',
                    value: conversion,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Views, interest and inquiries are indicative sample '
                    'figures. Viewing requests reflect real activity.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact listing identity shown at the top of the insights screen.
class _ListingHeader extends StatelessWidget {
  const _ListingHeader({
    required this.title,
    required this.statusLabel,
    required this.photo,
  });

  final String title;
  final String statusLabel;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: SizedBox(
            width: 64,
            height: 64,
            child: photo == null
                ? ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.home_work_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : AppNetworkImage(url: photo!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
