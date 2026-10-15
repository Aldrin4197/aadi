import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/map_config.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../shared/widgets/app_network_image.dart';

/// Map view of the explore feed: Mapbox raster tiles with a marker per listing
/// and a compact preview card for the selected one.
class ExploreMap extends StatefulWidget {
  const ExploreMap({
    super.key,
    required this.center,
    required this.listingsAsync,
    required this.onTapListing,
  });

  final LatLng center;
  final AsyncValue<List<Listing>> listingsAsync;
  final ValueChanged<Listing> onTapListing;

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap> {
  final _controller = MapController();
  String? _selectedId;

  @override
  void didUpdateWidget(ExploreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recenter when the tenant picks a new search location.
    if (widget.center != oldWidget.center) {
      _selectedId = null;
      _controller.move(widget.center, _controller.camera.zoom);
    }
  }

  void _select(Listing listing) {
    setState(() => _selectedId = listing.id);
    _controller.move(
      LatLng(listing.location.lat, listing.location.lng),
      _controller.camera.zoom,
    );
  }

  /// Moves the selection to the neighbouring listing and follows it on the map.
  void _stepSelection(int delta, List<Listing> listings) {
    if (listings.isEmpty) return;
    final current = listings.indexWhere((l) => l.id == _selectedId);
    final next = (current + delta).clamp(0, listings.length - 1);
    if (next != current) _select(listings[next]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final listings = widget.listingsAsync.valueOrNull ?? const <Listing>[];
    final selected = _selectedId == null
        ? null
        : listings.where((l) => l.id == _selectedId).firstOrNull;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (_, _) => setState(() => _selectedId = null),
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
                  point: widget.center,
                  width: 26,
                  height: 26,
                  child: const _CenterMarker(),
                ),
                for (final listing in listings)
                  Marker(
                    point: LatLng(listing.location.lat, listing.location.lng),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedId = listing.id),
                      child: _ListingMarker(
                        selected: listing.id == _selectedId,
                        icon: _iconFor(listing.type),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (widget.listingsAsync.isLoading)
          const Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(child: _MapChip(label: 'Finding listings…')),
          )
        else if (widget.listingsAsync.hasError)
          const Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(child: _MapChip(label: 'Couldn\'t load listings')),
          )
        else if (listings.isEmpty)
          const Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Center(child: _MapChip(label: 'No listings in this area')),
          ),
        Positioned(
          right: AppSpacing.xs,
          bottom: AppSpacing.xs,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.extraSmall),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                MapConfig.attribution,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (selected != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (listings.length > 1) ...[
                  _MapNavBar(
                    position:
                        listings.indexWhere((l) => l.id == selected.id) + 1,
                    total: listings.length,
                    onPrevious:
                        listings.indexWhere((l) => l.id == selected.id) > 0
                        ? () => _stepSelection(-1, listings)
                        : null,
                    onNext:
                        listings.indexWhere((l) => l.id == selected.id) <
                            listings.length - 1
                        ? () => _stepSelection(1, listings)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _MapListingCard(
                  listing: selected,
                  onTap: () => widget.onTapListing(selected),
                  onClose: () => setState(() => _selectedId = null),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

IconData _iconFor(ListingType type) => switch (type) {
  ListingType.bedspace => Icons.single_bed_outlined,
  ListingType.boardingHouse => Icons.meeting_room_outlined,
  ListingType.apartment => Icons.apartment_rounded,
  ListingType.house => Icons.house_outlined,
  ListingType.commercial => Icons.storefront_outlined,
  ListingType.multicab => Icons.airport_shuttle_outlined,
  ListingType.van => Icons.directions_bus_filled_outlined,
  ListingType.jeepney => Icons.directions_bus_outlined,
  ListingType.truck => Icons.local_shipping_outlined,
  ListingType.homeCleaning => Icons.cleaning_services_outlined,
  ListingType.repairService => Icons.build_outlined,
  ListingType.tutoringService => Icons.school_outlined,
  ListingType.eventsStaffing => Icons.groups_outlined,
};

/// The current search location.
class _CenterMarker extends StatelessWidget {
  const _CenterMarker();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            border: Border.all(color: scheme.surface, width: 2),
          ),
        ),
      ),
    );
  }
}

/// A tappable listing pin; enlarges and fills when selected.
class _ListingMarker extends StatelessWidget {
  const _ListingMarker({required this.selected, required this.icon});

  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : scheme.surface,
        border: Border.all(color: scheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: selected ? 22 : 18,
        color: selected ? scheme.onPrimary : scheme.primary,
      ),
    );
  }
}

/// A small status pill floated over the map.
class _MapChip extends StatelessWidget {
  const _MapChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 1,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

/// Prev/next controls to step through listings without hunting for pins.
class _MapNavBar extends StatelessWidget {
  const _MapNavBar({
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int position;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MapNavButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous space',
          onPressed: onPrevious,
        ),
        _MapCounter(position: position, total: total),
        _MapNavButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next space',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _MapNavButton extends StatelessWidget {
  const _MapNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Material(
      elevation: enabled ? 2 : 0,
      color: scheme.surface.withValues(alpha: enabled ? 1 : 0.6),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 28,
        color: enabled
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _MapCounter extends StatelessWidget {
  const _MapCounter({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 1,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '$position of $total',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

/// Compact preview shown when a map marker is selected.
class _MapListingCard extends StatelessWidget {
  const _MapListingCard({
    required this.listing,
    required this.onTap,
    required this.onClose,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final price = NumberFormat('#,##0', 'en_US').format(listing.price);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              _Thumb(listing: listing),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        listing.location.city ?? 'Nearby',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${listing.currency}$price',
                              style: textTheme.titleSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' /mo',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Dismiss',
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 100.0;
    if (listing.photos.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: scheme.surfaceContainerHighest,
        child: Icon(_iconFor(listing.type), color: scheme.onSurfaceVariant),
      );
    }
    return AppNetworkImage(
      url: listing.photos.first,
      width: size,
      height: size,
      placeholder: (_) => Container(
        width: size,
        height: size,
        color: scheme.surfaceContainerHighest,
      ),
      error: (_) => Container(
        width: size,
        height: size,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
