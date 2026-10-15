import '../models/viewing_request.dart';

/// Read/write access to the tenant's viewing requests.
///
/// Phase A stores these on-device; the R12 swap points this at an API-backed
/// implementation without changing callers.
abstract class ViewingRepository {
  /// All requests, newest-first. Callers filter by tenant or owner.
  Future<List<ViewingRequest>> list();

  /// Persist a brand-new request.
  Future<void> create(ViewingRequest request);

  /// Replace an existing request (matched by id).
  Future<void> update(ViewingRequest request);

  /// Remove a request by id.
  Future<void> delete(String id);
}
