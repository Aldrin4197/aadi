import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/result.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/geo_point.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/app_toast.dart';

/// Live place matches for [query] from OpenStreetMap Nominatim. Empty for
/// queries shorter than 2 chars. Keystrokes are debounced so we stay within
/// Nominatim's usage policy; if the query changes during the wait, this
/// provider is disposed and the request is skipped.
final placeSearchProvider = FutureProvider.autoDispose
    .family<List<GeoPoint>, String>((ref, query) async {
      final q = query.trim();
      if (q.length < 2) return const [];
      var disposed = false;
      ref.onDispose(() => disposed = true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (disposed) return const [];
      final repo = ref.watch(locationRepositoryProvider);
      return repo.searchPlaces(q);
    });

/// A readable label for a resolved location, e.g. "Makati, Metro Manila".
String locationLabel(GeoPoint g) {
  final city = g.city;
  if (city == null || city.isEmpty) return 'Selected location';
  final region = g.address;
  if (region == null || region.isEmpty || region == city) return city;
  return '$city, $region';
}

/// Opens the location picker and resolves to the chosen place, or null if the
/// tenant dismissed it without selecting one. Pass [initialQuery] to pre-fill
/// and immediately search the field (e.g. a city already typed on a form).
Future<GeoPoint?> showLocationSearchSheet(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showModalBottomSheet<GeoPoint>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _LocationSearchSheet(initialQuery: initialQuery),
  );
}

class _LocationSearchSheet extends ConsumerStatefulWidget {
  const _LocationSearchSheet({this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<_LocationSearchSheet> createState() =>
      _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<_LocationSearchSheet> {
  late final TextEditingController _controller;
  late String _query;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final location = await ref
          .read(locationRepositoryProvider)
          .currentLocation();
      if (mounted) Navigator.of(context).pop(location);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      showAppToast(context, e.message, kind: ToastKind.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      showAppToast(
        context,
        'Could not get your location.',
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set location', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _CurrentLocationTile(
            loading: _locating,
            onTap: _locating ? null : _useCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              labelText: 'Search location',
              hintText: 'e.g. Catbalogan City, Cebu City',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Clear',
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _Results(
              query: _query,
              onSelect: (place) => Navigator.of(context).pop(place),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationTile extends StatelessWidget {
  const _CurrentLocationTile({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.my_location_rounded, color: scheme.primary),
        title: const Text('Use my current location'),
        subtitle: Text(loading ? 'Locating…' : 'Find spaces near you'),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onSelect});

  final String query;
  final ValueChanged<GeoPoint> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().length < 2) {
      return _Hint(
        icon: Icons.travel_explore_rounded,
        message: 'Type at least 2 letters to search places.',
      );
    }

    final resultsAsync = ref.watch(placeSearchProvider(query));
    return resultsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => _Hint(
        icon: Icons.error_outline_rounded,
        message: 'Search failed. Check your connection and try again.',
      ),
      data: (places) {
        if (places.isEmpty) {
          return _Hint(
            icon: Icons.search_off_rounded,
            message: 'No places match "$query".',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              leading: const Icon(Icons.location_city_rounded),
              title: Text(place.city ?? 'Unknown'),
              subtitle: place.address == null ? null : Text(place.address!),
              onTap: () => onSelect(place),
            );
          },
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
