import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/listing.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/listing_card.dart';
import '../auth/auth_controller.dart';

/// Loads listings owned by the current landlord.
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final repo = ref.watch(listingRepositoryProvider);
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const [];
  return repo.listingsByOwner(user.id);
});

/// Landlord home tab: manage your listings.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load listings.\n$e')),
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(
              child: Text('You have no listings yet.\nTap "Add" to create one.',
                  textAlign: TextAlign.center),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myListingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, i) => ListingCard(listing: listings[i]),
            ),
          );
        },
      ),
    );
  }
}
