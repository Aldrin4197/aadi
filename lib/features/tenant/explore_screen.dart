import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/listing_query.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/aadi_app_bar.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/responsive_listing_view.dart';
import 'explore_map.dart';
import 'favorites_controller.dart';
import 'filter_sheet.dart';
import 'location_search_sheet.dart';

/// The active search location + filters for the Explore feed.
final exploreQueryProvider = StateProvider<ListingQuery>((ref) {
  return const ListingQuery(
    lat: AppConstants.fallbackLat,
    lng: AppConstants.fallbackLng,
    radiusKm: AppConstants.exploreRadiusKm,
  );
});

/// Listings matching the current [exploreQueryProvider], across every Aadi
/// service unless a category filter narrows it down.
final exploreListingsProvider = FutureProvider<List<Listing>>((ref) {
  final query = ref.watch(exploreQueryProvider);
  return ref.watch(listingRepositoryProvider).search(query);
});

/// Aadi Spaces home tab: a marketplace-style feed spanning Aadi Spaces, Aadi
/// Haul, and Aadi Raketeer listings, viewable as a map or a list.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _showMap = true;
  bool _locating = false;
  String _locationLabel = 'Manila';

  Future<void> _pickLocation() async {
    final picked = await showLocationSearchSheet(
      context,
      initialQuery: _locationLabel,
    );
    if (picked == null || !mounted) return;
    setState(() => _locationLabel = locationLabel(picked));
    ref
        .read(exploreQueryProvider.notifier)
        .update((q) => q.copyWith(lat: picked.lat, lng: picked.lng));
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final point = await ref.read(locationRepositoryProvider).currentLocation();
      if (!mounted) return;
      setState(() => _locationLabel = locationLabel(point));
      ref
          .read(exploreQueryProvider.notifier)
          .update((q) => q.copyWith(lat: point.lat, lng: point.lng));
    } on AppException catch (e) {
      if (mounted) showAppToast(context, e.message, kind: ToastKind.error);
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Could not get your location.', kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(context, ref.read(exploreQueryProvider));
    if (result != null) {
      ref.read(exploreQueryProvider.notifier).state = result;
    }
  }

  void _setCategory(AadiService? category) {
    ref.read(exploreQueryProvider.notifier).update(
          (q) => q.copyWith(
            category: category,
            clearCategory: category == null,
            clearType: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(exploreQueryProvider);
    final listingsAsync = ref.watch(exploreListingsProvider);
    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AadiAppBar(
        actions: [
          IconButton(
            tooltip: 'Change location',
            icon: const Icon(Icons.location_on_outlined),
            onPressed: _pickLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: query.category == null,
                          onSelected: (_) => _setCategory(null),
                        ),
                        for (final service in AadiService.values) ...[
                          const SizedBox(width: AppSpacing.xs),
                          ChoiceChip(
                            label: Text(service.name),
                            selected: query.category == service,
                            onSelected: (_) => _setCategory(service),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showMap ? 'Show list' : 'Show map',
                  icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_rounded),
                  onPressed: () => setState(() => _showMap = !_showMap),
                ),
                IconButton(
                  tooltip: 'Filters',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilters,
                ),
              ],
            ),
          ),
          Expanded(
            child: _showMap
                ? Stack(
                    children: [
                      ExploreMap(
                        center: LatLng(query.lat, query.lng),
                        listingsAsync: listingsAsync,
                        onTapListing: (l) => context.push(AppRoutes.listingDetail(l.id)),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        top: AppSpacing.sm,
                        child: _LocationChip(
                          label: _locationLabel,
                          onTap: _pickLocation,
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.xxl,
                        child: FloatingActionButton.small(
                          heroTag: 'locate-me',
                          tooltip: 'Use my current location',
                          onPressed: _locating ? null : _useMyLocation,
                          child: _locating
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  )
                : listingsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Could not load listings.\n$e')),
                    data: (listings) {
                      if (listings.isEmpty) {
                        return const Center(child: Text('No listings found nearby.'));
                      }
                      return RefreshIndicator(
                        onRefresh: () async => ref.refresh(exploreListingsProvider.future),
                        child: ResponsiveListingView(
                          listings: listings,
                          favoriteIds: favoriteIds,
                          onTapListing: (l) => context.push(AppRoutes.listingDetail(l.id)),
                          onToggleFavorite: (l) =>
                              ref.read(favoritesProvider.notifier).toggle(l.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(Icons.expand_more_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

