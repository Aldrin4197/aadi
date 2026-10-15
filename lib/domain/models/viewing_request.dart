import '../enums.dart';

/// A tenant's request to view a listing in person at a proposed date and time.
///
/// The tenant proposes [requestedAt]. The landlord can confirm it, decline it,
/// or propose an alternative via [proposedAt]. [effectiveAt] is the time the
/// two parties are currently converging on (the landlord's proposal when set,
/// otherwise the tenant's original request).
///
/// Persisted locally in Phase A; the R12 API swap will move these behind
/// `/me/viewings`.
class ViewingRequest {
  const ViewingRequest({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.ownerName,
    required this.requestedAt,
    required this.status,
    required this.createdAt,
    this.proposedAt,
    this.note,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String ownerName;

  /// The date and time the tenant asked to visit.
  final DateTime requestedAt;

  /// An alternative time proposed by the landlord, if any.
  final DateTime? proposedAt;

  final ViewingStatus status;
  final String? note;
  final DateTime createdAt;

  /// The time both parties are currently converging on.
  DateTime get effectiveAt => proposedAt ?? requestedAt;

  /// Whether the request is still open (neither confirmed nor declined).
  bool get isOpen =>
      status == ViewingStatus.pending || status == ViewingStatus.rescheduled;

  ViewingRequest copyWith({
    ViewingStatus? status,
    DateTime? requestedAt,
    Object? proposedAt = _sentinel,
    Object? note = _sentinel,
  }) {
    return ViewingRequest(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      ownerId: ownerId,
      ownerName: ownerName,
      requestedAt: requestedAt ?? this.requestedAt,
      proposedAt: proposedAt == _sentinel
          ? this.proposedAt
          : proposedAt as DateTime?,
      status: status ?? this.status,
      note: note == _sentinel ? this.note : note as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'listingTitle': listingTitle,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'requestedAt': requestedAt.toIso8601String(),
    'proposedAt': proposedAt?.toIso8601String(),
    'status': status.name,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ViewingRequest.fromJson(Map<String, dynamic> json) => ViewingRequest(
    id: json['id'] as String,
    listingId: json['listingId'] as String,
    listingTitle: json['listingTitle'] as String,
    tenantId: json['tenantId'] as String,
    tenantName: json['tenantName'] as String,
    ownerId: json['ownerId'] as String,
    ownerName: json['ownerName'] as String,
    requestedAt: DateTime.parse(json['requestedAt'] as String),
    proposedAt: (json['proposedAt'] as String?) == null
        ? null
        : DateTime.parse(json['proposedAt'] as String),
    status: ViewingStatus.values.byName(json['status'] as String),
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

const Object _sentinel = Object();
