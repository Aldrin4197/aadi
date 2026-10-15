import '../models/saved_search.dart';

/// Stores the tenant's saved searches. Local now, API-backed after R12.
abstract interface class SavedSearchRepository {
  Future<List<SavedSearch>> list();

  Future<void> save(SavedSearch search);

  Future<void> delete(String id);
}
