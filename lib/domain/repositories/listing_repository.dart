import '../models/listing.dart';
import '../models/listing_query.dart';

/// Contract for listing data. Implemented by a mock now, a real API later.
///
/// The eventual offline-first implementation will read from SQLite (drift)
/// and use the remote source only to refresh the cache.
abstract interface class ListingRepository {
  Future<List<Listing>> search(ListingQuery query);

  Future<Listing> getById(String id);

  Future<List<Listing>> listingsByOwner(String ownerId);

  Future<Listing> create(Listing listing);

  Future<Listing> update(Listing listing);

  Future<void> delete(String id);
}
