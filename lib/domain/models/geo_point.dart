/// A geographic point with optional resolved address details.
class GeoPoint {
  const GeoPoint({
    required this.lat,
    required this.lng,
    this.address,
    this.city,
  });

  final double lat;
  final double lng;
  final String? address;
  final String? city;

  GeoPoint copyWith({double? lat, double? lng, String? address, String? city}) {
    return GeoPoint(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      city: city ?? this.city,
    );
  }
}
