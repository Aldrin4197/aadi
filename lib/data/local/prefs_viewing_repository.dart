import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';

/// [ViewingRepository] backed by `shared_preferences`.
///
/// Requests are kept newest-first as a single JSON array under one key so they
/// survive app restarts during the mock phase.
class PrefsViewingRepository implements ViewingRepository {
  static const _key = 'aadi.viewing_requests.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<ViewingRequest>> list() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ViewingRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> create(ViewingRequest request) async {
    final current = await list();
    await _write([request, ...current]);
  }

  @override
  Future<void> update(ViewingRequest request) async {
    final current = await list();
    await _write([
      for (final r in current)
        if (r.id == request.id) request else r,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    final current = await list();
    await _write(current.where((r) => r.id != id).toList());
  }

  Future<void> _write(List<ViewingRequest> requests) async {
    final encoded = jsonEncode(requests.map((r) => r.toJson()).toList());
    await (await _prefs).setString(_key, encoded);
  }
}
