import 'enums.dart';
import 'quantity_text.dart';

/// A checkable condition that bounds the value of one requirement.
class Constraint {
  final String id;
  final String requirementId;
  final String description;
  final ConstraintKind kind;
  final Severity severity;

  /// The single bound used when [kind] is min, max, or equals.
  final QuantityText value;

  /// The lower and upper bounds used when [kind] is range.
  final QuantityText min;
  final QuantityText max;

  const Constraint({
    required this.id,
    required this.requirementId,
    this.description = '',
    this.kind = ConstraintKind.max,
    this.severity = Severity.hard,
    this.value = QuantityText.empty,
    this.min = QuantityText.empty,
    this.max = QuantityText.empty,
  });

  /// The bounds that apply to this constraint, keyed by role.
  Map<String, QuantityText> get bounds {
    switch (kind) {
      case ConstraintKind.range:
        return {'min': min, 'max': max};
      case ConstraintKind.min:
      case ConstraintKind.max:
      case ConstraintKind.equals:
        return {'value': value};
    }
  }

  String get kindLabel {
    switch (kind) {
      case ConstraintKind.min:
        return 'minimum';
      case ConstraintKind.max:
        return 'maximum';
      case ConstraintKind.range:
        return 'range';
      case ConstraintKind.equals:
        return 'equals';
    }
  }

  Constraint copyWith({
    String? requirementId,
    String? description,
    ConstraintKind? kind,
    Severity? severity,
    QuantityText? value,
    QuantityText? min,
    QuantityText? max,
  }) {
    return Constraint(
      id: id,
      requirementId: requirementId ?? this.requirementId,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      severity: severity ?? this.severity,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'requirementId': requirementId,
      'description': description,
      'kind': kind.wire,
      'severity': severity.wire,
      if (kind == ConstraintKind.range) ...{
        if (!min.isEmpty) 'min': min.raw,
        if (!max.isEmpty) 'max': max.raw,
      } else if (!value.isEmpty) ...{
        'value': value.raw,
      },
    };
  }

  factory Constraint.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final requirementId = json['requirementId'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Constraint is missing a valid id.');
    }
    if (requirementId is! String || requirementId.isEmpty) {
      throw const FormatException('Constraint is missing a requirementId.');
    }
    final kind = ConstraintKind.fromWire(json['kind'] as String?);
    QuantityText read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty
          ? QuantityText(value)
          : QuantityText.empty;
    }

    return Constraint(
      id: id,
      requirementId: requirementId,
      description: json['description'] as String? ?? '',
      kind: kind,
      severity: Severity.fromWire(json['severity'] as String?),
      value: read('value'),
      min: read('min'),
      max: read('max'),
    );
  }
}
