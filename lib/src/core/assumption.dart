import 'enums.dart';

/// A recorded assumption that must hold for the design to be valid.
class Assumption {
  final String id;
  final String statement;
  final String owner;
  final AssumptionStatus status;

  /// The requirement this assumption affects, when known.
  final String? requirementId;
  final String rationale;

  const Assumption({
    required this.id,
    required this.statement,
    this.owner = '',
    this.status = AssumptionStatus.open,
    this.requirementId,
    this.rationale = '',
  });

  Assumption copyWith({
    String? statement,
    String? owner,
    AssumptionStatus? status,
    String? requirementId,
    String? rationale,
  }) {
    return Assumption(
      id: id,
      statement: statement ?? this.statement,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      requirementId: requirementId ?? this.requirementId,
      rationale: rationale ?? this.rationale,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'statement': statement,
      'owner': owner,
      'status': status.wire,
      if (requirementId != null) 'requirementId': requirementId,
      'rationale': rationale,
    };
  }

  factory Assumption.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final statement = json['statement'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Assumption is missing a valid id.');
    }
    if (statement is! String || statement.isEmpty) {
      throw const FormatException('Assumption is missing a statement.');
    }
    return Assumption(
      id: id,
      statement: statement,
      owner: json['owner'] as String? ?? '',
      status: AssumptionStatus.fromWire(json['status'] as String?),
      requirementId: json['requirementId'] as String?,
      rationale: json['rationale'] as String? ?? '',
    );
  }
}
