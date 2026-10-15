import '../enums.dart';
import 'geo_point.dart';

/// A rentable space listed by a landlord.
class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.location,
    this.currency = '₱',
    String? priceUnit,
    this.photos = const [],
    this.amenities = const [],
    this.status = ListingStatus.active,
    this.propertyVerification = VerificationStatus.none,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    required this.createdAt,
  }) : priceUnit = priceUnit ?? '';

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final ListingType type;
  final double price;
  final String currency;

  /// What the price is quoted per (e.g. "mo", "day", "job"). Falls back to
  /// [ListingType.defaultPriceUnit] when not set explicitly.
  final String priceUnit;
  final GeoPoint location;
  final List<String> photos;
  final List<String> amenities;
  final ListingStatus status;
  final VerificationStatus propertyVerification;
  final double ratingAverage;
  final int ratingCount;
  final DateTime createdAt;

  bool get isAvailable => status == ListingStatus.active;
  bool get isVerified => propertyVerification == VerificationStatus.verified;

  /// Category this offering belongs to (Spaces/Haul/Raketeer).
  AadiService get category => type.category;

  /// The unit to display next to the price, e.g. "/ mo", "/ day", "/ job".
  String get resolvedPriceUnit =>
      priceUnit.isEmpty ? type.defaultPriceUnit : priceUnit;

  Listing copyWith({
    String? title,
    String? description,
    ListingType? type,
    double? price,
    GeoPoint? location,
    List<String>? photos,
    List<String>? amenities,
    ListingStatus? status,
  }) {
    return Listing(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      currency: currency,
      priceUnit: priceUnit,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      amenities: amenities ?? this.amenities,
      status: status ?? this.status,
      propertyVerification: propertyVerification,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      createdAt: createdAt,
    );
  }
}
