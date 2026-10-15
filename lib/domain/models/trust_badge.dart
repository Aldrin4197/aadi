import '../enums.dart';

/// A verification badge granted (server-side / admin) to a user or listing.
///
/// Named `TrustBadge` to avoid clashing with Flutter's Material `Badge` widget.
class TrustBadge {
  const TrustBadge({
    required this.type,
    required this.status,
    this.grantedAt,
  });

  final BadgeType type;
  final VerificationStatus status;
  final DateTime? grantedAt;

  bool get isVerified => status == VerificationStatus.verified;
}
