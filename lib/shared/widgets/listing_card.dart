import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';

/// Compact card used in feeds and listing lists.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Listing listing;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: Icon(
                    _iconFor(listing.type),
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.isVerified)
                        const Icon(Icons.verified_rounded,
                            color: AppColors.secondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(listing.type.label),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined,
                          size: 16, color: textTheme.bodySmall?.color),
                      Text(
                        listing.location.city ?? '',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${listing.currency}${listing.price.toStringAsFixed(0)} / ${listing.resolvedPriceUnit}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (listing.ratingCount > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.accent),
                            Text(
                              ' ${listing.ratingAverage.toStringAsFixed(1)} '
                              '(${listing.ratingCount})',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        )
                      else
                        Text('New', style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
