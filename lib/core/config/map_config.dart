import 'dart:ui' show Brightness;

/// Map tile provider configuration.
///
/// Uses Mapbox raster tiles via `flutter_map`. The access token is a public
/// (`pk.`) token that ships in the client by design; override it per build with
/// `--dart-define=MAPBOX_TOKEN=pk.xxx`. Restrict the token by URL in the Mapbox
/// dashboard and keep its scopes read-only.
class MapConfig {
  const MapConfig._();

  static const String mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');

  /// Minimal Mapbox base styles (no bold colored roads) that still surface
  /// major landmark labels, tracking the active theme. Swap these ids to
  /// restyle both maps at once (any classic style works, including a custom
  /// `username/styleId` from Studio).
  static const String lightStyleId = 'mapbox/light-v11';
  static const String darkStyleId = 'mapbox/dark-v11';

  static const String userAgentPackageName = 'com.aadi';

  /// Required attribution for Mapbox + OpenStreetMap data.
  static const String attribution = '© Mapbox © OpenStreetMap';

  static const int tileDimension = 512;

  static const double zoomOffset = -1;

  static String styleIdFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkStyleId : lightStyleId;

  /// 512px retina tile URL for the given [brightness]; pair with
  /// [tileDimension] and [zoomOffset] on the layer.
  static String tileUrlTemplate(Brightness brightness) =>
      'https://api.mapbox.com/styles/v1/${styleIdFor(brightness)}'
      '/tiles/512/{z}/{x}/{y}@2x?access_token=$mapboxToken';
}
