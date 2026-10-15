import '../enums.dart';
import 'provider_application.dart';
import 'trust_badge.dart';

/// A registered Aadi user.
///
/// Every account is a plain user by default. Applying for and being verified
/// as a [ProviderKind] (landlord, vehicle owner, raketeer) unlocks that
/// vertical's provider tools — see [providerApplications].
///
/// Named `AppUser` to avoid clashing with backend `User` naming and to keep
/// the domain model unambiguous.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.service = AadiService.spaces,
    this.phone,
    this.avatarUrl,
    this.badges = const [],
    this.providerApplications = const [],
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.trustScore = 0,
  });

  final String id;
  final String email;
  final String name;

  /// The service (Spaces/Haul/Raketeer) this account is currently browsing.
  final AadiService service;
  final String? phone;
  final String? avatarUrl;
  final List<TrustBadge> badges;
  final List<ProviderApplication> providerApplications;
  final double ratingAverage;
  final int ratingCount;

  /// Server-computed 0..100. Shown as "New to Aadi" until enough signals exist.
  final int trustScore;

  bool get isNewUser => ratingCount == 0;

  VerificationStatus statusFor(ProviderKind kind) {
    for (final application in providerApplications) {
      if (application.kind == kind) return application.status;
    }
    return VerificationStatus.none;
  }

  bool isVerifiedProvider(ProviderKind kind) =>
      statusFor(kind) == VerificationStatus.verified;

  bool hasPendingApplication(ProviderKind kind) =>
      statusFor(kind) == VerificationStatus.pending;

  /// Convenience used across the Aadi Spaces UI.
  bool get canHostAsLandlord => isVerifiedProvider(ProviderKind.landlord);

  AppUser copyWith({
    String? name,
    AadiService? service,
    String? phone,
    String? avatarUrl,
    List<TrustBadge>? badges,
    List<ProviderApplication>? providerApplications,
    double? ratingAverage,
    int? ratingCount,
    int? trustScore,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      service: service ?? this.service,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      badges: badges ?? this.badges,
      providerApplications: providerApplications ?? this.providerApplications,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}

