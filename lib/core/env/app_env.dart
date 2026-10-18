/// Build flavor / environment configuration.
///
/// The app starts in [dev] with mock data. Swapping to a real backend later
/// only requires flipping [useMockData] and setting [apiBaseUrl].
library;

import 'package:flutter/foundation.dart';

import '../../domain/enums.dart';
import '../../domain/models/app_user.dart';

enum AppFlavor { dev, staging, prod }

class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.useMockData,
    this.bypassProviderVerification = false,
    this.bypassAuthentication = false,
  });

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool useMockData;

  /// Dev-only escape hatch: skips the verified-provider check so Landlord,
  /// Vehicle Owner, and Raketeer management pages are reachable without
  /// waiting on an admin approval.
  final bool bypassProviderVerification;

  /// Only enables a local screen-inspection identity in non-release builds.
  final bool bypassAuthentication;
  bool get allowGuestInspection => !kReleaseMode && bypassAuthentication;

  static const AppEnv dev = AppEnv(
    flavor: AppFlavor.dev,
    apiBaseUrl: 'https://api.dev.aadi.app',
    useMockData: true,
    bypassProviderVerification: true,
    bypassAuthentication: true,
  );

  static const AppEnv staging = AppEnv(
    flavor: AppFlavor.staging,
    apiBaseUrl: 'https://api.staging.aadi.app',
    useMockData: false,
  );

  static const AppEnv prod = AppEnv(
    flavor: AppFlavor.prod,
    apiBaseUrl: 'https://api.aadi.app',
    useMockData: false,
  );

  /// Active environment for this build. Change here (or via build flavors later).
  static const AppEnv current = dev;

  /// Whether [kind]'s management pages should be reachable for [user].
  bool isProviderUnlocked(AppUser? user, ProviderKind kind) {
    if (bypassProviderVerification) return true;
    return user?.isVerifiedProvider(kind) ?? false;
  }
}

