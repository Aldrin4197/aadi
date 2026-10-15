import '../enums.dart';

/// A plain user's application to become a verified provider (landlord,
/// vehicle owner, or raketeer) for the matching [AadiService].
class ProviderApplication {
  const ProviderApplication({
    required this.kind,
    required this.status,
    required this.submittedAt,
    this.decidedAt,
    this.documentPaths = const [],
    this.note,
  });

  final ProviderKind kind;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? decidedAt;

  /// Local file paths / URLs of uploaded ID or business documents.
  final List<String> documentPaths;
  final String? note;

  ProviderApplication copyWith({
    VerificationStatus? status,
    DateTime? decidedAt,
  }) {
    return ProviderApplication(
      kind: kind,
      status: status ?? this.status,
      submittedAt: submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
      documentPaths: documentPaths,
      note: note,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'status': status.name,
    'submittedAt': submittedAt.toIso8601String(),
    'decidedAt': decidedAt?.toIso8601String(),
    'documentPaths': documentPaths,
    'note': note,
  };

  factory ProviderApplication.fromJson(Map<String, dynamic> json) {
    return ProviderApplication(
      kind: ProviderKind.values.byName(json['kind'] as String),
      status: VerificationStatus.values.byName(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      decidedAt: (json['decidedAt'] as String?) == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      documentPaths:
          (json['documentPaths'] as List<dynamic>?)?.cast<String>() ??
          const [],
      note: json['note'] as String?,
    );
  }
}
