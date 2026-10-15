import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/map_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/geo_point.dart';
import '../../shared/widgets/map_widgets.dart';
import '../tenant/location_search_sheet.dart';

/// Full-screen property location picker modelled on the tenant Map View:
/// search a place to recenter the map, then tap to drop the exact pin.
/// Pops the chosen [GeoPoint] (pin coordinates + resolved city/area).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final GeoPoint? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = MapController();
  late LatLng _pin;
  String? _city;
  String? _region;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _pin = LatLng(
      i?.lat ?? AppConstants.fallbackLat,
      i?.lng ?? AppConstants.fallbackLng,
    );
    _city = i?.city;
    _region = i?.address;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final place = await showLocationSearchSheet(context);
    if (place == null || !mounted) return;
    setState(() {
      _pin = LatLng(place.lat, place.lng);
      _city = place.city;
      _region = place.address;
    });
    _controller.move(_pin, 15);
  }

  void _confirm() {
    Navigator.of(context).pop(
      GeoPoint(
        lat: _pin.latitude,
        lng: _pin.longitude,
        city: _city,
        address: _region,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final label = _city == null
        ? 'Search for your city or area'
        : locationLabel(
            GeoPoint(
              lat: _pin.latitude,
              lng: _pin.longitude,
              city: _city,
              address: _region,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set property location'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _pin,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, point) => setState(() => _pin = point),
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
                    point: _pin,
                    width: 40,
                    height: 40,
                    child: const MapPin(),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _SearchBar(label: label, onTap: _search),
          ),
          const Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: Center(
              child: _HintChip(text: 'Tap the map to set the exact spot'),
            ),
          ),
          const Positioned(
            right: AppSpacing.xs,
            bottom: AppSpacing.xs,
            child: MapAttributionBox(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pin at ${_pin.latitude.toStringAsFixed(5)}, '
              '${_pin.longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Use this location'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable pill that opens the place-search sheet, mirroring the tenant map.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.text});

  final String text;

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
        child: Text(text, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}
