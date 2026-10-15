import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env/app_env.dart';
import '../data/local/prefs_favorites_repository.dart';
import '../data/local/prefs_saved_search_repository.dart';
import '../data/local/prefs_viewing_repository.dart';
import '../data/location/nominatim_location_repository.dart';
import '../data/mock/mock_auth_repository.dart';
import '../data/mock/mock_listing_repository.dart';
import '../data/mock/mock_user_repository.dart';
import '../domain/enums.dart';
import '../domain/models/app_user.dart';
import '../domain/models/listing.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/repositories/listing_repository.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/repositories/saved_search_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/viewing_repository.dart';

/// Active environment.
final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.current);

/// Selected bottom-nav tab for [TenantShell] (Aadi Spaces). Exposed here so
/// screens embedded as tabs (e.g. the Landlord dashboard) can send the user
/// back to Explore without a route to pop.
final tenantShellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Overridden in `main()` once `SharedPreferences.getInstance()` resolves.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

/// Repository providers. These are the single swap point between mock and the
/// real API: when [AppEnv.useMockData] is false, return the remote impls here.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  if (env.useMockData) return MockAuthRepository();
  // TODO(remote): return ApiAuthRepository(dio) when the backend is ready.
  return MockAuthRepository();
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  if (env.useMockData) return MockListingRepository();
  // TODO(remote): return ApiListingRepository(dio) when the backend is ready.
  return MockListingRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  // TODO(remote): return ApiUserRepository(dio) when the backend is ready.
  return MockUserRepository();
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  // TODO(remote): return ApiFavoritesRepository(dio) when the backend is ready.
  return PrefsFavoritesRepository();
});

final savedSearchRepositoryProvider = Provider<SavedSearchRepository>((ref) {
  // TODO(remote): return ApiSavedSearchRepository(dio) when the backend is ready.
  return PrefsSavedSearchRepository();
});

final viewingRepositoryProvider = Provider<ViewingRepository>((ref) {
  // TODO(remote): return ApiViewingRepository(dio) when the backend is ready.
  return PrefsViewingRepository();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return NominatimLocationRepository();
});

/// A single user by id, used by public profile cards and owner previews.
final userByIdProvider = FutureProvider.family<AppUser?, String>((ref, id) {
  return ref.watch(userRepositoryProvider).getById(id);
});

/// A provider's currently active listings, used on their public profile.
final activeListingsByOwnerProvider = FutureProvider.family<List<Listing>, String>(
  (ref, ownerId) async {
    final all = await ref.watch(listingRepositoryProvider).listingsByOwner(ownerId);
    return all.where((l) => l.status == ListingStatus.active).toList();
  },
);

