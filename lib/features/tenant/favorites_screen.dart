import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/aadi_app_bar.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/responsive_listing_view.dart';
import 'favorites_controller.dart';

/// The tenant's saved (favorited) listings.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(favoriteListingsProvider);
    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: const AadiAppBar(),
      body: listingsAsync.when(
        loading: () => const ListingListSkeleton(),
        error: (_, __) => ErrorRetryView(
          message: 'We couldn\'t load your favorites. Please try again.',
          onRetry: () => ref.invalidate(favoriteListingsProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return const EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message:
                  'Tap the heart on any listing to save it here for later.',
            );
          }
          return ResponsiveListingView(
            listings: listings,
            favoriteIds: favoriteIds,
            onToggleFavorite: (listing) =>
                ref.read(favoritesProvider.notifier).toggle(listing.id),
            onTapListing: (listing) =>
                context.push(AppRoutes.listingDetail(listing.id)),
          );
        },
      ),
    );
  }
}
