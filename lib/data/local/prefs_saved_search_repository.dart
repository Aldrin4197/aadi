import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/saved_search.dart';
import '../../domain/repositories/saved_search_repository.dart';

/// [SavedSearchRepository] backed by `shared_preferences`.
///
/// Searches are kept newest-first as a single JSON array under one key.
class PrefsSavedSearchRepository implements SavedSearchRepository {
  static const _key = 'aadi.saved_searches.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<SavedSearch>> list() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(SavedSearch search) async {
    final current = await list();
    final next = [search, ...current.where((s) => s.id != search.id)];
    await _write(next);
  }

  @override
  Future<void> delete(String id) async {
    final current = await list();
    await _write(current.where((s) => s.id != id).toList());
  }

  Future<void> _write(List<SavedSearch> searches) async {
    final encoded = jsonEncode(searches.map((s) => s.toJson()).toList());
    await (await _prefs).setString(_key, encoded);
  }
}
