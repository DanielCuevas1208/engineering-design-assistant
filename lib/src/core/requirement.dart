import 'enums.dart';
import 'quantity_text.dart';

/// A single captured engineering requirement.
class Requirement {
  final String id;
  final String statement;
  final RequirementCategory category;
  final Priority priority;
  final RequirementStatus status;
  final String owner;
  final String rationale;

  /// An optional measurable target, for example `100 mm`.
  final QuantityText quantity;

  const Requirement({
    required this.id,
    required this.statement,
    this.category = RequirementCategory.functional,
    this.priority = Priority.unassigned,
    this.status = RequirementStatus.draft,
    this.owner = '',
    this.rationale = '',
    this.quantity = QuantityText.empty,
  });

  Requirement copyWith({
    String? statement,
    RequirementCategory? category,
    Priority? priority,
    RequirementStatus? status,
    String? owner,
    String? rationale,
    QuantityText? quantity,
  }) {
    return Requirement(
      id: id,
      statement: statement ?? this.statement,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      rationale: rationale ?? this.rationale,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'statement': statement,
      'category': category.wire,
      'priority': priority.wire,
      'status': status.wire,
      'owner': owner,
      'rationale': rationale,
      if (!quantity.isEmpty) 'quantity': quantity.raw,
    };
  }

  factory Requirement.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final statement = json['statement'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Requirement is missing a valid id.');
    }
    if (statement is! String || statement.isEmpty) {
      throw const FormatException('Requirement is missing a statement.');
    }
    final quantityValue = json['quantity'];
    return Requirement(
      id: id,
      statement: statement,
      category: RequirementCategory.fromWire(json['category'] as String?),
      priority: Priority.fromWire(json['priority'] as String?),
      status: RequirementStatus.fromWire(json['status'] as String?),
      owner: json['owner'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
      quantity: quantityValue is String && quantityValue.trim().isNotEmpty
          ? QuantityText(quantityValue)
          : QuantityText.empty,
    );
  }
}
