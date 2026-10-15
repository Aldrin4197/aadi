import '../enums.dart';

/// Query parameters for searching listings. Mirrors the planned
/// `GET /listings` API query string exactly for mock/real parity.
class ListingQuery {
  const ListingQuery({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    this.category,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.availableOnly = true,
  });

  final double lat;
  final double lng;
  final double radiusKm;

  /// Top-level Aadi vertical (Spaces/Haul/Raketeer); null means all.
  final AadiService? category;
  final ListingType? type;
  final double? minPrice;
  final double? maxPrice;
  final bool availableOnly;

  ListingQuery copyWith({
    double? lat,
    double? lng,
    double? radiusKm,
    AadiService? category,
    bool clearCategory = false,
    ListingType? type,
    bool clearType = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? availableOnly,
  }) {
    return ListingQuery(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'radiusKm': radiusKm,
    'category': category?.name,
    'type': type?.name,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'availableOnly': availableOnly,
  };

  factory ListingQuery.fromJson(Map<String, dynamic> json) => ListingQuery(
    lat: json['lat'] as double,
    lng: json['lng'] as double,
    radiusKm: json['radiusKm'] as double,
    category: json['category'] == null
        ? null
        : AadiService.values.byName(json['category'] as String),
    type: json['type'] == null
        ? null
        : ListingType.values.byName(json['type'] as String),
    minPrice: json['minPrice'] as double?,
    maxPrice: json['maxPrice'] as double?,
    availableOnly: json['availableOnly'] as bool? ?? true,
  );
}
