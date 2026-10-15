import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/listing.dart';
import '../../shared/providers.dart';

/// Reactive set of the tenant's favorite listing ids.
final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.read(favoritesRepositoryProvider).list();
  }

  Future<void> toggle(String listingId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final current = state.valueOrNull ?? await repo.list();
    if (current.contains(listingId)) {
      await repo.remove(listingId);
    } else {
      await repo.add(listingId);
    }
    state = AsyncData(await repo.list());
  }
}

/// The favorited listings, resolved from the listing repository. Favorites
/// whose listing no longer exists are silently skipped.
final favoriteListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final ids = await ref.watch(favoritesProvider.future);
  if (ids.isEmpty) return [];

  final repo = ref.watch(listingRepositoryProvider);
  final listings = <Listing>[];
  for (final id in ids) {
    try {
      listings.add(await repo.getById(id));
    } catch (_) {
      // Skip favorites whose listing is no longer available.
    }
  }
  return listings;
});
