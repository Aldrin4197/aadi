import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/favorites_repository.dart';

/// [FavoritesRepository] backed by `shared_preferences` (a string-list of ids).
class PrefsFavoritesRepository implements FavoritesRepository {
  static const _key = 'aadi.favorites.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Set<String>> list() async {
    return (await _prefs).getStringList(_key)?.toSet() ?? <String>{};
  }

  @override
  Future<void> add(String listingId) async {
    final ids = await list();
    ids.add(listingId);
    await (await _prefs).setStringList(_key, ids.toList());
  }

  @override
  Future<void> remove(String listingId) async {
    final ids = await list();
    ids.remove(listingId);
    await (await _prefs).setStringList(_key, ids.toList());
  }
}
