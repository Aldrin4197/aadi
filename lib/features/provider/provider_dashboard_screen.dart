import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/stat_card.dart';
import 'provider_listings_screen.dart';

/// Management home for a verified Vehicle Owner (Aadi Haul) or Raketeer
/// (Aadi Raketeer): a quick pulse on their listings plus quick actions.
class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key, required this.category});

  final AadiService category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noun = category == AadiService.haul ? 'vehicles' : 'services';
    final listingsAsync = ref.watch(providerListingsProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.spacesHome),
        ),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorRetryView(
          message: 'We couldn\'t load your $noun. Please try again.',
          onRetry: () => ref.invalidate(providerListingsProvider(category)),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyStateView(
              icon: category == AadiService.haul
                  ? Icons.local_shipping_outlined
                  : Icons.handyman_outlined,
              title: 'No $noun yet',
              message:
                  'Publish your first listing to start managing it here.',
              actionLabel: _addLabel(category),
              onAction: () => context.push(_newListingRoute(category)),
            );
          }

          final active = listings
              .where((l) => l.status == ListingStatus.active)
              .length;
          final drafts = listings
              .where((l) => l.status == ListingStatus.draft)
              .length;
          final avgPrice =
              listings.map((l) => l.price).reduce((a, b) => a + b) /
              listings.length;
          final avgPriceLabel =
              '${listings.first.currency}'
              '${NumberFormat('#,##0', 'en_US').format(avgPrice)}';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: category == AadiService.haul
                              ? Icons.local_shipping_rounded
                              : Icons.handyman_rounded,
                          label: 'Active $noun',
                          value: '$active',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          icon: Icons.edit_note_rounded,
                          label: 'Drafts',
                          value: '$drafts',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Average price',
                    value: avgPriceLabel,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.push(_managementRoute(category)),
                    icon: const Icon(Icons.list_alt_rounded),
                    label: Text('Manage $noun'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => context.push(_newListingRoute(category)),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_addLabel(category)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _addLabel(AadiService category) =>
      category == AadiService.haul ? 'Add vehicle' : 'Add service';

  static String _newListingRoute(AadiService category) => switch (category) {
    AadiService.haul => AppRoutes.newVehicleListing,
    AadiService.raketeer => AppRoutes.newServiceListing,
    AadiService.spaces => AppRoutes.newListing,
  };

  static String _managementRoute(AadiService category) => switch (category) {
    AadiService.haul => AppRoutes.vehicleListings,
    AadiService.raketeer => AppRoutes.serviceListings,
    AadiService.spaces => AppRoutes.newListing,
  };
}
