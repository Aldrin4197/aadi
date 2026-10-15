import '../../core/error/result.dart';
import '../../domain/enums.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/provider_application.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory mock of [AuthRepository]. Always "succeeds" but simulates latency
/// so loading/error UI states can be built correctly from the start.
class MockAuthRepository implements AuthRepository {
  static const _latency = Duration(milliseconds: 700);

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
    required AadiService service,
  }) async {
    await Future<void>.delayed(_latency);
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const AppException('Email and password are required.');
    }
    final user = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      name: name.trim().isEmpty ? email.split('@').first : name.trim(),
      service: service,
      trustScore: 0,
    );
    return _sessionFor(user);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const AppException('Please enter your email and password.');
    }
    // Mock convenience: an email prefix seeds a pre-verified provider
    // application so the host/vehicle-owner/raketeer tools can be demoed
    // without going through the apply flow every time.
    final lower = email.toLowerCase();
    final (service, applications) = switch (lower) {
      // Mock/admin convenience: this account is verified across every
      // provider role so all management pages are reachable for testing.
      'admin@aadi.test' => (
        AadiService.spaces,
        [for (final kind in ProviderKind.values) _verifiedApplication(kind)],
      ),
      _ when lower.startsWith('demo') => (
        AadiService.haul,
        [
          _verifiedApplication(ProviderKind.vehicleOwner),
          _verifiedApplication(ProviderKind.raketeer),
        ],
      ),
      _ when lower.startsWith('landlord') => (
        AadiService.spaces,
        [_verifiedApplication(ProviderKind.landlord)],
      ),
      _ when lower.startsWith('haul') || lower.startsWith('vehicle') => (
        AadiService.haul,
        [_verifiedApplication(ProviderKind.vehicleOwner)],
      ),
      _ when lower.startsWith('raketeer') => (
        AadiService.raketeer,
        [_verifiedApplication(ProviderKind.raketeer)],
      ),
      _ => (AadiService.spaces, const <ProviderApplication>[]),
    };
    final user = AppUser(
      id: 'u_${email.hashCode}',
      email: email.trim(),
      name: email.split('@').first,
      service: service,
      providerApplications: applications,
      trustScore: 42,
    );
    return _sessionFor(user);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  ProviderApplication _verifiedApplication(ProviderKind kind) {
    final submitted = DateTime.now().subtract(const Duration(days: 30));
    return ProviderApplication(
      kind: kind,
      status: VerificationStatus.verified,
      submittedAt: submitted,
      decidedAt: submitted.add(const Duration(days: 2)),
    );
  }

  AuthSession _sessionFor(AppUser user) => AuthSession(
        accessToken: 'mock-access-${user.id}',
        refreshToken: 'mock-refresh-${user.id}',
        user: user,
      );
}

