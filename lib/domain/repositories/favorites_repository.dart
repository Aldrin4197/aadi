/// Stores the tenant's favorite listing ids. Local now, API-backed after R12.
abstract interface class FavoritesRepository {
  Future<Set<String>> list();

  Future<void> add(String listingId);

  Future<void> remove(String listingId);
}
