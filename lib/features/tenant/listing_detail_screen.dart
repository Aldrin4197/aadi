import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/map_config.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/app_network_image.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/trust.dart';
import '../auth/auth_controller.dart';
import '../landlord/listing_analytics.dart';
import '../viewings/viewing_schedule_sheet.dart';
import '../viewings/viewings_controller.dart';
import 'favorites_controller.dart';

/// Loads a single listing for the detail screen.
final listingByIdProvider = FutureProvider.family<Listing, String>((
  ref,
  id,
) async {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.getById(id);
});

/// Full listing detail: gallery, key facts, description, location, owner,
/// policies, and a sticky contact action.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingByIdProvider(listingId));

    return listingAsync.when(
      loading: () => const _DetailScaffold(child: _DetailSkeleton()),
      error: (_, __) => _DetailScaffold(
        child: ErrorRetryView(
          message:
              'We couldn\'t open this listing. Check your connection and try '
              'again.',
          onRetry: () => ref.invalidate(listingByIdProvider(listingId)),
        ),
      ),
      data: (listing) => _LoadedDetail(listing: listing),
    );
  }
}

/// Simple scaffold with a back button, used for the loading and error states.
class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: child);
  }
}

class _LoadedDetail extends ConsumerWidget {
  const _LoadedDetail({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryHeight = (MediaQuery.sizeOf(context).width * 0.62).clamp(
      220.0,
      340.0,
    );
    final isFav =
        ref.watch(favoritesProvider).valueOrNull?.contains(listing.id) ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: galleryHeight,
            actions: [
              _ScrimIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Share',
                onPressed: () => _share(context),
              ),
              _ScrimIconButton(
                icon: isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFav
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white,
                tooltip: isFav ? 'Remove from favorites' : 'Save to favorites',
                onPressed: () async {
                  await ref.read(favoritesProvider.notifier).toggle(listing.id);
                  if (!context.mounted) return;
                  _notify(
                    context,
                    isFav ? 'Removed from favorites' : 'Added to favorites',
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Gallery(listing: listing),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: _DetailBody(listing: listing),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ViewingBar(listing: listing),
    );
  }

  void _share(BuildContext context) {
    final money = _priceLabel(listing);
    Clipboard.setData(
      ClipboardData(
        text:
            '${listing.title} — $money on Aadi\n'
            '${_locationLabel(listing) ?? listing.type.label}',
      ),
    );
    _notify(context, 'Listing details copied — ready to share.');
  }

  void _notify(BuildContext context, String message) {
    showAppToast(context, message);
  }
}

/// The scrollable content below the gallery, ordered per the design system.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identity: title, location, rating.
        Text(listing.title, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        _LocationLine(listing: listing),
        const SizedBox(height: AppSpacing.xs),
        _RatingLine(listing: listing),
        if (listing.propertyVerification == VerificationStatus.verified ||
            listing.propertyVerification == VerificationStatus.pending) ...[
          const SizedBox(height: AppSpacing.sm),
          PropertyTrustChip(status: listing.propertyVerification),
        ],
        const SizedBox(height: AppSpacing.md),

        // Price + availability.
        _PriceRow(listing: listing),
        const SizedBox(height: AppSpacing.lg),
        _OwnerInsights(listing: listing),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.lg),

        // Key facts.
        _SectionTitle('Key facts'),
        const SizedBox(height: AppSpacing.sm),
        _KeyFacts(listing: listing),

        if (listing.amenities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Amenities'),
          const SizedBox(height: AppSpacing.sm),
          _Amenities(amenities: listing.amenities),
        ],

        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('About this space'),
        const SizedBox(height: AppSpacing.sm),
        Text(listing.description, style: textTheme.bodyLarge),

        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Location'),
        const SizedBox(height: AppSpacing.sm),
        _LocationCard(listing: listing),

        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Hosted by'),
        const SizedBox(height: AppSpacing.sm),
        _OwnerCard(listing: listing),

        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Good to know'),
        const SizedBox(height: AppSpacing.sm),
        const _Policies(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

/// Owner-only performance snapshot. Renders nothing for non-owners so the
/// tenant-facing detail experience is unchanged.
class _OwnerInsights extends ConsumerWidget {
  const _OwnerInsights({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).user?.id;
    if (me == null || me != listing.ownerId) return const SizedBox.shrink();

    final analytics = ref.watch(listingAnalyticsProvider(listing.id));
    final conversion =
        '${(analytics.conversionRate * 100).toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Your listing performance'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.visibility_outlined,
                label: 'Views',
                value: '${analytics.views}',
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
                label: 'Requests',
                value: '${analytics.viewingRequests}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up_rounded,
                label: 'Conversion',
                value: conversion,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.listingInsights(listing.id)),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('View full insights'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = _locationLabel(listing) ?? listing.type.label;
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (listing.ratingCount == 0) {
      return Text('New listing', style: textTheme.bodyMedium);
    }

    return Row(
      children: [
        Icon(Icons.star_rounded, size: 18, color: scheme.secondary),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          listing.ratingAverage.toStringAsFixed(1),
          style: textTheme.titleSmall,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text('(${listing.ratingCount} reviews)', style: textTheme.bodyMedium),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _priceLabel(listing),
                style: textTheme.headlineMedium?.copyWith(
                  color: scheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text('/ month', style: textTheme.bodyMedium),
            ],
          ),
        ),
        _AvailabilityChip(listing: listing),
      ],
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = listing.isAvailable;
    final color = available ? scheme.secondary : scheme.error;
    final label = listing.status.label;

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
          Icon(
            available
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            available ? 'Available' : label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _KeyFacts extends StatelessWidget {
  const _KeyFacts({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FactChip(icon: Icons.home_work_outlined, label: listing.type.label),
      ],
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final amenity in amenities)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: scheme.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(amenity, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final center = LatLng(listing.location.lat, listing.location.lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(Icons.location_on_outlined, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _locationLabel(listing) ?? 'Approximate area',
                style: textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.tileUrlTemplate(brightness),
                      tileDimension: MapConfig.tileDimension,
                      zoomOffset: MapConfig.zoomOffset,
                      userAgentPackageName: MapConfig.userAgentPackageName,
                      maxZoom: 20,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 40,
                          height: 40,
                          child: const _LocationPin(),
                        ),
                      ],
                    ),
                  ],
                ),
                const Positioned(
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xxs,
                  child: _MapAttribution(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        MapConfig.attribution,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.black87),
      ),
    );
  }
}

class _OwnerCard extends ConsumerWidget {
  const _OwnerCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final owner = ref.watch(userByIdProvider(listing.ownerId)).valueOrNull;
    final initial = listing.ownerName.isNotEmpty
        ? listing.ownerName.characters.first.toUpperCase()
        : '?';
    final isVerifiedLandlord = owner?.canHostAsLandlord ?? false;

    return InkWell(
      onTap: () => context.push(AppRoutes.userProfile(listing.ownerId)),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.ownerName, style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            isVerifiedLandlord
                                ? Icons.verified_user_outlined
                                : Icons.person_outline_rounded,
                            size: 16,
                            color: isVerifiedLandlord
                                ? scheme.secondary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            isVerifiedLandlord ? 'Verified landlord' : 'Owner',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (owner != null && !owner.isNewUser)
                  TrustScoreChip(
                    score: owner.trustScore,
                    isNew: owner.isNewUser,
                  ),
              ],
            ),
            if (owner != null && owner.ratingCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              RatingLabel(
                average: owner.ratingAverage,
                count: owner.ratingCount,
                dense: true,
              ),
            ],
            if (owner != null && owner.badges.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              TrustBadgeList(badges: owner.badges),
            ],
          ],
        ),
      ),
    );
  }
}

class _Policies extends StatelessWidget {
  const _Policies();

  static const _items = [
    (Icons.badge_outlined, 'Valid ID required at move-in'),
    (Icons.payments_outlined, 'Advance & deposit set by owner'),
    (Icons.event_outlined, 'Viewing & move-in arranged with owner'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, text) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(text, style: textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Sticky bottom bar with the price and the primary viewing action.
///
/// The action reflects the tenant's current request status for this listing so
/// it can double as a status pill and prevent duplicate submissions.
class _ViewingBar extends StatelessWidget {
  const _ViewingBar({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 0,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _priceLabel(listing),
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text('per month', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (listing.isAvailable)
                    _ScheduleOrStatusButton(listing: listing)
                  else
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Unavailable'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders either a "Schedule viewing" CTA or a status pill that opens the
/// manage sheet, based on the tenant's active request for this listing.
class _ScheduleOrStatusButton extends ConsumerWidget {
  const _ScheduleOrStatusButton({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(viewingForListingProvider(listing.id));
    final active =
        (existing != null && existing.status != ViewingStatus.declined)
        ? existing
        : null;

    if (active == null) {
      return FilledButton.icon(
        onPressed: () => showScheduleViewingSheet(context, listing),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Schedule viewing'),
      );
    }

    final (IconData icon, String label) = switch (active.status) {
      ViewingStatus.pending => (
        Icons.hourglass_top_rounded,
        'Viewing requested',
      ),
      ViewingStatus.confirmed => (
        Icons.event_available_rounded,
        'Viewing confirmed',
      ),
      ViewingStatus.rescheduled => (Icons.update_rounded, 'New time proposed'),
      ViewingStatus.declined => (
        Icons.event_available_outlined,
        'Schedule viewing',
      ),
    };

    return FilledButton.tonalIcon(
      onPressed: () => _openStatusSheet(context, active),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  void _openStatusSheet(BuildContext context, ViewingRequest request) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ViewingStatusSheet(request: request),
    );
  }
}

/// Compact manage sheet shown when tapping an active request's status pill.
class _ViewingStatusSheet extends ConsumerWidget {
  const _ViewingStatusSheet({required this.request});

  final ViewingRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rescheduled = request.status == ViewingStatus.rescheduled;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your viewing', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              switch (request.status) {
                ViewingStatus.pending =>
                  'Waiting for ${request.ownerName} to confirm your time.',
                ViewingStatus.confirmed =>
                  'Confirmed with ${request.ownerName}. See you there!',
                ViewingStatus.rescheduled =>
                  '${request.ownerName} proposed a new time. Accept it or '
                      'cancel.',
                ViewingStatus.declined =>
                  '${request.ownerName} declined this request.',
              },
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    viewingDateFormat.format(request.effectiveAt),
                    style: textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (rescheduled)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(viewingsProvider.notifier)
                        .acceptProposed(request.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    showAppToast(
                      context,
                      'New time accepted.',
                      kind: ToastKind.success,
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept new time'),
                ),
              ),
            if (rescheduled) const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.myViewings),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Manage in My viewings'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(viewingsProvider.notifier).cancel(request.id);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  showAppToast(context, 'Viewing request removed.');
                },
                icon: const Icon(Icons.close_rounded),
                label: Text(
                  request.status == ViewingStatus.confirmed
                      ? 'Cancel viewing'
                      : 'Cancel request',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo carousel with reserved dimensions and a type-based placeholder.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.listing});

  final Listing listing;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.listing.photos;
    if (photos.isEmpty) {
      return _GalleryPlaceholder(type: widget.listing.type);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => AppNetworkImage(
            url: photos[i],
            placeholder: (_) => _GalleryPlaceholder(type: widget.listing.type),
            error: (_) => _GalleryPlaceholder(type: widget.listing.type),
          ),
        ),
        if (photos.length > 1)
          PositionedDirectional(
            bottom: AppSpacing.sm,
            start: 0,
            end: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: i == _page ? 1 : 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  const _GalleryPlaceholder({required this.type});

  final ListingType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          _iconFor(type),
          size: 72,
          color: scheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _iconFor(ListingType type) => switch (type) {
    ListingType.bedspace => Icons.single_bed_rounded,
    ListingType.boardingHouse => Icons.meeting_room_rounded,
    ListingType.apartment => Icons.apartment_rounded,
    ListingType.house => Icons.house_rounded,
    ListingType.commercial => Icons.storefront_rounded,
    ListingType.multicab => Icons.airport_shuttle_rounded,
    ListingType.van => Icons.directions_bus_filled_rounded,
    ListingType.jeepney => Icons.directions_bus_rounded,
    ListingType.truck => Icons.local_shipping_rounded,
    ListingType.homeCleaning => Icons.cleaning_services_rounded,
    ListingType.repairService => Icons.build_rounded,
    ListingType.tutoringService => Icons.school_rounded,
    ListingType.eventsStaffing => Icons.groups_rounded,
  };
}

/// A round, scrimmed icon button for legibility over gallery imagery.
class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }
}

/// Skeleton shown while the listing loads.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.06);
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        bar(240, 22),
        bar(160, 14),
        const SizedBox(height: AppSpacing.md),
        bar(120, 26),
        const SizedBox(height: AppSpacing.md),
        bar(double.infinity, 14),
        bar(double.infinity, 14),
        bar(220, 14),
      ],
    );
  }
}

String _priceLabel(Listing listing) {
  final formatted = NumberFormat('#,##0', 'en_US').format(listing.price);
  return '${listing.currency}$formatted';
}

String? _locationLabel(Listing listing) {
  final address = listing.location.address;
  final city = listing.location.city;
  if (address != null && city != null) return '$address, $city';
  return address ?? city;
}
