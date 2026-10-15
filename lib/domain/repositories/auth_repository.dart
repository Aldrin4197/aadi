import '../enums.dart';
import '../models/auth_session.dart';

/// Contract for authentication. Implemented by a mock now, a real API later.
abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
    required AadiService service,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}
