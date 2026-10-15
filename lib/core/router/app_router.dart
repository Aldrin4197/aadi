import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/landlord/listing_form_screen.dart';
import '../../features/landlord/listing_insights_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/service_selection_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/public_profile_screen.dart';
import '../../features/provider/provider_application_screen.dart';
import '../../features/provider/provider_listings_screen.dart';
import '../../features/service_home/coming_soon_service_shell.dart';
import '../../features/tenant/listing_detail_screen.dart';
import '../../features/tenant/tenant_shell.dart';
import '../../features/viewings/viewing_detail_screen.dart';
import '../../features/viewings/viewing_requests_screen.dart';
import '../env/app_env.dart';
import 'app_routes.dart';

/// Builds the app router once and uses the [AuthController] as the redirect
/// source of truth (also as `refreshListenable`).
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final onAuthFlow = AppRoutes.unauthenticated.contains(target);

      if (!loggedIn) {
        return onAuthFlow ? null : AppRoutes.onboarding;
      }

      // Signed in: land on the service the account is currently browsing.
      if (onAuthFlow) return AppRoutes.serviceHome(auth.user!.service);

      // Guard provider-only management pages until that role is verified.
      final kind = AppRoutes.providerKindFor(target);
      if (kind != null && !AppEnv.current.isProviderUnlocked(auth.user, kind)) {
        return AppRoutes.serviceHome(auth.user!.service);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServiceSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) =>
            AuthScreen(initialIsRegister: state.extra as bool? ?? true),
      ),
      GoRoute(
        path: AppRoutes.spacesHome,
        builder: (context, state) => const TenantShell(),
      ),
      GoRoute(
        path: AppRoutes.haulHome,
        builder: (context, state) => const ComingSoonServiceShell(
          service: AadiService.haul,
          providerKind: ProviderKind.vehicleOwner,
        ),
      ),
      GoRoute(
        path: AppRoutes.raketeerHome,
        builder: (context, state) => const ComingSoonServiceShell(
          service: AadiService.raketeer,
          providerKind: ProviderKind.raketeer,
        ),
      ),
      GoRoute(
        path: AppRoutes.providerApplyPattern,
        builder: (context, state) => ProviderApplicationScreen(
          kind: ProviderKind.values.byName(state.pathParameters['kind']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.listingPattern,
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.newListing,
        builder: (context, state) => const ListingFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.newVehicleListing,
        builder: (context, state) =>
            const ListingFormScreen(category: AadiService.haul),
      ),
      GoRoute(
        path: AppRoutes.newServiceListing,
        builder: (context, state) =>
            const ListingFormScreen(category: AadiService.raketeer),
      ),
      GoRoute(
        path: AppRoutes.vehicleListings,
        builder: (context, state) =>
            const ProviderListingsScreen(category: AadiService.haul),
      ),
      GoRoute(
        path: AppRoutes.serviceListings,
        builder: (context, state) =>
            const ProviderListingsScreen(category: AadiService.raketeer),
      ),
      GoRoute(
        path: AppRoutes.editListingPattern,
        builder: (context, state) =>
            ListingFormScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.listingInsightsPattern,
        builder: (context, state) =>
            ListingInsightsScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.userProfilePattern,
        builder: (context, state) =>
            PublicProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.myViewings,
        builder: (context, state) =>
            const ViewingRequestsScreen(asLandlord: false),
      ),
      GoRoute(
        path: AppRoutes.viewingDetailPattern,
        builder: (context, state) =>
            ViewingDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

