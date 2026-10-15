import '../models/geo_point.dart';

/// Device location + place lookup. GPS is a device capability (always the same
/// implementation); place search is curated in Phase A and swaps to a geocoding
/// API at R12.
abstract interface class LocationRepository {
  /// Resolves the device's current position, requesting permission if needed.
  ///
  /// Throws [AppException] when location services are off or permission is
  /// denied, with a user-safe message.
  Future<GeoPoint> currentLocation();

  /// Returns curated places whose city or region matches [query].
  Future<List<GeoPoint>> searchPlaces(String query);
}
