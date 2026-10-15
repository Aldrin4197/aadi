import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums.dart';
import '../../domain/models/viewing_request.dart';
import '../../shared/providers.dart';
import '../auth/auth_controller.dart';

/// Reactive list of every viewing request stored on-device, newest-first.
///
/// Screens filter this by the signed-in user via [myViewingsProvider] (as a
/// tenant) and [incomingViewingsProvider] (as a landlord).
final viewingsProvider =
    AsyncNotifierProvider<ViewingsNotifier, List<ViewingRequest>>(
      ViewingsNotifier.new,
    );

class ViewingsNotifier extends AsyncNotifier<List<ViewingRequest>> {
  @override
  Future<List<ViewingRequest>> build() {
    return ref.read(viewingRepositoryProvider).list();
  }

  /// Submit a new request and refresh state from storage.
  Future<void> submit(ViewingRequest request) async {
    final repo = ref.read(viewingRepositoryProvider);
    await repo.create(request);
    state = AsyncData(await repo.list());
  }

  /// Landlord confirms the currently proposed/requested time.
  Future<void> confirm(String id) =>
      _mutate(id, (r) => r.copyWith(status: ViewingStatus.confirmed));

  /// Landlord declines the request.
  Future<void> decline(String id) =>
      _mutate(id, (r) => r.copyWith(status: ViewingStatus.declined));

  /// Landlord proposes an alternative time, moving the request back to the
  /// tenant for acceptance.
  Future<void> propose(String id, DateTime proposedAt) => _mutate(
    id,
    (r) =>
        r.copyWith(status: ViewingStatus.rescheduled, proposedAt: proposedAt),
  );

  /// Tenant changes their own requested time, resetting the request to pending
  /// so the landlord reviews the new proposal.
  Future<void> reschedule(String id, DateTime requestedAt) => _mutate(
    id,
    (r) => r.copyWith(
      status: ViewingStatus.pending,
      requestedAt: requestedAt,
      proposedAt: null,
    ),
  );

  /// Tenant accepts the landlord's proposed time, locking it in as confirmed.
  Future<void> acceptProposed(String id) => _mutate(id, (r) {
    final agreed = r.proposedAt ?? r.requestedAt;
    return r.copyWith(
      status: ViewingStatus.confirmed,
      requestedAt: agreed,
      proposedAt: null,
    );
  });

  /// Remove a request entirely (tenant cancels).
  Future<void> cancel(String id) async {
    final repo = ref.read(viewingRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.list());
  }

  Future<void> _mutate(
    String id,
    ViewingRequest Function(ViewingRequest) transform,
  ) async {
    final repo = ref.read(viewingRepositoryProvider);
    final current = state.valueOrNull ?? await repo.list();
    final match = current.where((r) => r.id == id).firstOrNull;
    if (match == null) return;
    await repo.update(transform(match));
    state = AsyncData(await repo.list());
  }
}

/// The signed-in tenant's own requests, newest-first.
final myViewingsProvider = Provider<AsyncValue<List<ViewingRequest>>>((ref) {
  final all = ref.watch(viewingsProvider);
  final me = ref.watch(authControllerProvider).user?.id;
  return all.whenData((list) => list.where((r) => r.tenantId == me).toList());
});

/// Requests addressed to the signed-in landlord (for listings they own).
final incomingViewingsProvider = Provider<AsyncValue<List<ViewingRequest>>>((
  ref,
) {
  final all = ref.watch(viewingsProvider);
  final me = ref.watch(authControllerProvider).user?.id;
  return all.whenData((list) => list.where((r) => r.ownerId == me).toList());
});

/// The signed-in tenant's most recent request for [listingId], if any.
///
/// Used by the listing detail sticky bar to reflect status and prevent
/// duplicate submissions.
final viewingForListingProvider = Provider.family<ViewingRequest?, String>((
  ref,
  listingId,
) {
  final me = ref.watch(authControllerProvider).user?.id;
  final list = ref.watch(viewingsProvider).valueOrNull ?? const [];
  return list
      .where((r) => r.listingId == listingId && r.tenantId == me)
      .firstOrNull;
});

/// A single viewing request by [id], or null when it no longer exists.
///
/// Used by the full-screen request detail page so it reacts to status changes
/// and disappears if the request is cancelled elsewhere.
final viewingByIdProvider = Provider.family<ViewingRequest?, String>((ref, id) {
  final list = ref.watch(viewingsProvider).valueOrNull ?? const [];
  return list.where((r) => r.id == id).firstOrNull;
});
