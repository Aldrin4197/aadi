import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/saved_search.dart';
import '../../shared/providers.dart';

/// Reactive list of the tenant's saved searches (newest first).
final savedSearchesProvider =
    AsyncNotifierProvider<SavedSearchesNotifier, List<SavedSearch>>(
      SavedSearchesNotifier.new,
    );

class SavedSearchesNotifier extends AsyncNotifier<List<SavedSearch>> {
  @override
  Future<List<SavedSearch>> build() {
    return ref.read(savedSearchRepositoryProvider).list();
  }

  Future<void> save(SavedSearch search) async {
    final repo = ref.read(savedSearchRepositoryProvider);
    await repo.save(search);
    state = AsyncData(await repo.list());
  }

  Future<void> remove(String id) async {
    final repo = ref.read(savedSearchRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.list());
  }
}
