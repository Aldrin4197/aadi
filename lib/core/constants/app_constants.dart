/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Aadi';
  static const String tagline = 'Your next space is here.';

  /// Default search radius (km) for the tenant explore feed.
  static const double defaultRadiusKm = 5.0;

  /// Fallback map center (Manila) used before a location is resolved.
  static const double fallbackLat = 14.5995;
  static const double fallbackLng = 120.9842;

  /// Default radius for the Explore feed and the filter sheet's reset state.
  static const double exploreRadiusKm = 5.0;

  /// Upper bound for the price range filter (₱).
  static const double priceFilterMax = 50000.0;

  /// Bounds for the search-radius filter (km).
  static const double radiusFilterMin = 1.0;
  static const double radiusFilterMax = 25.0;
}
