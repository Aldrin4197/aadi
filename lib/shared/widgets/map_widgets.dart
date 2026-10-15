import 'package:flutter/material.dart';

import '../../core/config/map_config.dart';
import '../../core/theme/app_radius.dart';

/// The teal location marker used on map pickers and previews.
class MapPin extends StatelessWidget {
  const MapPin({super.key});

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

/// Required Mapbox + OpenStreetMap attribution overlay.
class MapAttributionBox extends StatelessWidget {
  const MapAttributionBox({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.extraSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          MapConfig.attribution,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
