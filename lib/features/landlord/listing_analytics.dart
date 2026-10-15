import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewings/viewings_controller.dart';

/// Performance numbers for a single listing.
///
/// In this mock-first build there is no real analytics pipeline, so demand
/// signals (views, saves, inquiries) are generated deterministically from the
/// listing id — the same listing always shows the same numbers. The viewing
/// request count, however, is the *real* number of requests for that listing.
class ListingAnalytics {
  const ListingAnalytics({
    required this.views,
    required this.interested,
    required this.viewingRequests,
    required this.inquiries,
  });

  /// Total profile views.
  final int views;

  /// People who saved / favorited the listing.
  final int interested;

  /// Real viewing requests received for this listing.
  final int viewingRequests;

  /// Direct messages / inquiries from tenants.
  final int inquiries;

  /// Share of views that turned into a viewing request (0.0 - 1.0).
  double get conversionRate =>
      views == 0 ? 0 : (viewingRequests / views).clamp(0.0, 1.0);
}

/// Deterministic pseudo-random integer in [min, max] derived from [id].
int _seeded(String id, int salt, int min, int max) {
  final hash = (id.hashCode ^ (salt * 0x9E3779B1)).abs();
  return min + (hash % (max - min + 1));
}

/// Mock analytics for a listing, keyed by listing id.
///
/// Watches [viewingsProvider] so the request count stays in sync with real
/// bookings while the remaining demand signals stay stable per listing.
final listingAnalyticsProvider = Provider.family<ListingAnalytics, String>((
  ref,
  listingId,
) {
  final requests = ref.watch(viewingsProvider).valueOrNull ?? const [];
  final requestCount = requests.where((r) => r.listingId == listingId).length;

  final views = _seeded(listingId, 1, 48, 940);
  final savePercent = _seeded(listingId, 2, 6, 22);
  final interested = ((views * savePercent) ~/ 100).clamp(0, views);
  final inquiries = _seeded(listingId, 3, 1, 46);

  return ListingAnalytics(
    views: views,
    interested: interested,
    viewingRequests: requestCount,
    inquiries: inquiries,
  );
});
