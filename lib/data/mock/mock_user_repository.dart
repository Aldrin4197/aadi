import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import 'mock_data.dart';

/// In-memory mock of [UserRepository] backed by the seed users. Simulates a
/// short latency so profile loading states render like the real API will.
class MockUserRepository implements UserRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<AppUser?> getById(String id) async {
    await Future<void>.delayed(_latency);
    for (final user in MockData.users()) {
      if (user.id == id) return user;
    }
    return null;
  }
}
