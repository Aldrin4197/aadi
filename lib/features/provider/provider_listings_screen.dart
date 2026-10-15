import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/listing_card.dart';
import '../auth/auth_controller.dart';

/// The signed-in user's listings within [category], used by the Vehicle
/// Owner and Raketeer management pages (and by Aadi Spaces' host dashboard).
final providerListingsProvider = FutureProvider.family<List<Listing>, AadiService>(
  (ref, category) async {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const [];
    final all = await ref.watch(listingRepositoryProvider).listingsByOwner(user.id);
    return all.where((l) => l.category == category).toList();
  },
);

/// Manage-your-listings page shared by Aadi Haul (vehicles) and Aadi
/// Raketeer (services): a category-scoped list with create/edit access.
class ProviderListingsScreen extends ConsumerWidget {
  const ProviderListingsScreen({super.key, required this.category});

  final AadiService category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(providerListingsProvider(category));
    final noun = category == AadiService.haul ? 'vehicles' : 'services';

    return Scaffold(
      appBar: AppBar(title: Text('My $noun')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(_newListingRoute(category)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: listingsAsync.when(
        loading: () => const ListingListSkeleton(),
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
              message: 'Tap "Add" to publish your first listing.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(providerListingsProvider(category).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, i) => ListingCard(
                listing: listings[i],
                onTap: () => context.push(AppRoutes.editListing(listings[i].id)),
              ),
            ),
          );
        },
      ),
    );
  }

  String _newListingRoute(AadiService category) => switch (category) {
        AadiService.haul => AppRoutes.newVehicleListing,
        AadiService.raketeer => AppRoutes.newServiceListing,
        AadiService.spaces => AppRoutes.newListing,
      };
}
