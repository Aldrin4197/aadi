import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/listing.dart';
import 'listing_card.dart';

/// Renders listings as a single column on phones and a two-column grid on
/// wider surfaces (>= 600px), per the Aadi responsive guidance.
class ResponsiveListingView extends StatelessWidget {
  const ResponsiveListingView({
    super.key,
    required this.listings,
    this.onTapListing,
    this.favoriteIds,
    this.onToggleFavorite,
  });

  final List<Listing> listings;
  final void Function(Listing listing)? onTapListing;

  /// When provided, cards show a favorite control reflecting these ids.
  final Set<String>? favoriteIds;
  final void Function(Listing listing)? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= AppBreakpoints.compact
        ? AppSpacing.lg
        : AppSpacing.md;

    if (width < AppBreakpoints.compact) {
      return ListView.builder(
        padding: EdgeInsets.all(horizontalPadding),
        itemCount: listings.length,
        itemBuilder: (context, i) => _card(listings[i]),
      );
    }

    final columns = width >= 900 ? 3 : 2;
    return GridView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: listings.length,
      itemBuilder: (context, i) => _card(listings[i]),
    );
  }

  Widget _card(Listing listing) {
    return ListingCard(
      listing: listing,
      onTap: () => onTapListing?.call(listing),
      isFavorite: favoriteIds?.contains(listing.id) ?? false,
      onFavoriteToggle: onToggleFavorite == null
          ? null
          : () => onToggleFavorite!(listing),
    );
  }
}
