import '../models/app_user.dart';

/// Contract for reading public user profiles (trust signals: badges, rating,
/// trust score). Maps to `GET /users/{id}` on the real API.
///
/// Display-only in Phase A — the app never computes trust, it only shows what
/// the backend/admin workflow has granted.
abstract interface class UserRepository {
  Future<AppUser?> getById(String id);
}
