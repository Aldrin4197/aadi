import 'dart:math' as math;

import '../../core/error/result.dart';
import '../../domain/models/listing.dart';
import '../../domain/models/listing_query.dart';
import '../../domain/repositories/listing_repository.dart';
import 'mock_data.dart';

/// In-memory mock of [ListingRepository] with simulated latency and simple
/// distance/price/type filtering that mirrors the planned API behavior.
class MockListingRepository implements ListingRepository {
  MockListingRepository() : _listings = [...MockData.listings()];

  static const _latency = Duration(milliseconds: 600);
  final List<Listing> _listings;

  @override
  Future<List<Listing>> search(ListingQuery query) async {
    await Future<void>.delayed(_latency);
    final results = _listings.where((l) {
      if (query.availableOnly && !l.isAvailable) return false;
      if (query.category != null && l.category != query.category) return false;
      if (query.type != null && l.type != query.type) return false;
      if (query.minPrice != null && l.price < query.minPrice!) return false;
      if (query.maxPrice != null && l.price > query.maxPrice!) return false;
      final distance = _distanceKm(query.lat, query.lng, l.location.lat, l.location.lng);
      return distance <= query.radiusKm;
    }).toList()
      ..sort((a, b) {
        final da = _distanceKm(query.lat, query.lng, a.location.lat, a.location.lng);
        final db = _distanceKm(query.lat, query.lng, b.location.lat, b.location.lng);
        return da.compareTo(db);
      });
    return results;
  }

  @override
  Future<Listing> getById(String id) async {
    await Future<void>.delayed(_latency);
    final match = _listings.where((l) => l.id == id).firstOrNull;
    if (match == null) {
      throw const AppException('Listing not found.');
    }
    return match;
  }

  @override
  Future<List<Listing>> listingsByOwner(String ownerId) async {
    await Future<void>.delayed(_latency);
    return _listings.where((l) => l.ownerId == ownerId).toList();
  }

  @override
  Future<Listing> create(Listing listing) async {
    await Future<void>.delayed(_latency);
    _listings.add(listing);
    return listing;
  }

  @override
  Future<Listing> update(Listing listing) async {
    await Future<void>.delayed(_latency);
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index == -1) throw const AppException('Listing not found.');
    _listings[index] = listing;
    return listing;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(_latency);
    _listings.removeWhere((l) => l.id == id);
  }

  /// Haversine distance in kilometers.
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);
}
