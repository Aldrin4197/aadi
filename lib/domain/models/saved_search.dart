import 'listing_query.dart';

/// A named [ListingQuery] the tenant stored to re-run later.
///
/// Persisted locally in Phase A; the R12 API swap will sync these through
/// `/me/saved-searches`.
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.label,
    required this.query,
    required this.createdAt,
  });

  final String id;
  final String label;
  final ListingQuery query;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'query': query.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
    id: json['id'] as String,
    label: json['label'] as String,
    query: ListingQuery.fromJson(json['query'] as Map<String, dynamic>),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
