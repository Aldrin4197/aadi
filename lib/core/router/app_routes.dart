import '../../domain/enums.dart';

/// Centralized route paths.
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String services = '/services';
  static const String auth = '/auth';

  static const String spacesHome = '/spaces';
  static const String haulHome = '/haul';
  static const String raketeerHome = '/raketeer';

  /// Generalized "become a provider" flow (Landlord, Vehicle Owner, Raketeer).
  static const String providerApplyPattern = '/provider/:kind/apply';
  static String providerApply(ProviderKind kind) =>
      '/provider/${kind.name}/apply';

  /// Listing detail. [listingPattern] is the go_router path template;
  /// [listingDetail] builds a concrete path for navigation.
  static const String listingPattern = '/listing/:id';
  static String listingDetail(String id) => '/listing/$id';

  /// Create/edit wizard, shared by Spaces, Haul, and Raketeer.
  static const String newListing = '/listings/new';
  static const String newVehicleListing = '/haul/listings/new';
  static const String newServiceListing = '/raketeer/listings/new';
  static const String editListingPattern = '/listings/:id/edit';
  static String editListing(String id) => '/listings/$id/edit';

  /// Manage-your-listings pages for Aadi Haul and Aadi Raketeer providers.
  static const String vehicleListings = '/haul/listings';
  static const String serviceListings = '/raketeer/listings';

  /// Per-listing performance / analytics.
  static const String listingInsightsPattern = '/listings/:id/insights';
  static String listingInsights(String id) => '/listings/$id/insights';

  /// Public, viewable profile for any user (host or tenant).
  static const String userProfilePattern = '/user/:id';
  static String userProfile(String id) => '/user/$id';

  /// The signed-in user's own viewing requests (Aadi Spaces).
  static const String myViewings = '/viewings';

  /// A single viewing request in full detail.
  static const String viewingDetailPattern = '/viewings/:id';
  static String viewingDetail(String id) => '/viewings/$id';

  /// Notifications inbox.
  static const String notifications = '/notifications';

  static const Set<String> unauthenticated = {onboarding, welcome, services, auth};

  /// Home route for [service], used after sign-in and from the profile tab's
  /// service switcher.
  static String serviceHome(AadiService service) => switch (service) {
    AadiService.spaces => spacesHome,
    AadiService.haul => haulHome,
    AadiService.raketeer => raketeerHome,
  };

  /// Provider-only management routes, keyed by the [ProviderKind] required to
  /// open them — guarded in addition to the client-side gates already shown
  /// in the Host tab / service home shells.
  static ProviderKind? providerKindFor(String location) {
    if (location == newListing) return ProviderKind.landlord;
    if (location.startsWith('/listings/')) {
      if (location.endsWith('/edit') || location.endsWith('/insights')) {
        return ProviderKind.landlord;
      }
    }
    if (location == newVehicleListing || location == vehicleListings) {
      return ProviderKind.vehicleOwner;
    }
    if (location == newServiceListing || location == serviceListings) {
      return ProviderKind.raketeer;
    }
    return null;
  }
}

