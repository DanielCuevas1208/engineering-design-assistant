import '../core/constraint.dart';
import '../core/design_brief.dart';
import '../core/enums.dart';
import '../core/requirement.dart';
import '../core/validation.dart';
import '../units/quantity_parser.dart';
import '../units/unit_engine.dart';

/// Checks a design brief and produces a validation report.
class ConstraintChecker {
  final UnitEngine engine;

  const ConstraintChecker({this.engine = const UnitEngine()});

  ValidationReport check(DesignBrief brief) {
    final issues = <ValidationIssue>[];
    final now = DateTime.now().toUtc();

    for (final requirement in brief.requirements) {
      _checkRequirement(requirement, issues);
    }
    for (final constraint in brief.constraints) {
      _checkConstraint(brief, constraint, issues);
    }
    for (final assumption in brief.assumptions) {
      if (assumption.status == AssumptionStatus.open) {
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.info,
            code: IssueCode.unresolvedAssumption,
            message: 'Assumption ${assumption.id} is still open.',
            entityId: assumption.id,
            detail: assumption.statement,
          ),
        );
      }
    }

    return ValidationReport(
      generatedAt: now,
      requirementCount: brief.requirements.length,
      constraintCount: brief.constraints.length,
      assumptionCount: brief.assumptions.length,
      openAssumptionCount: brief.openAssumptionCount,
      issues: issues,
    );
  }

  void _checkRequirement(
    Requirement requirement,
    List<ValidationIssue> issues,
  ) {
    if (requirement.quantity.isEmpty) return;
    final result = engine.parse(requirement.quantity.raw);
    if (result.quantity == null) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          code: IssueCode.unknownUnit,
          message:
              'Requirement ${requirement.id} has an unrecognized quantity '
              "'${requirement.quantity.raw}'.",
          entityId: requirement.id,
          detail: result.error,
        ),
      );
    }
    if (requirement.owner.trim().isEmpty &&
        requirement.status == RequirementStatus.approved) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.warning,
          code: IssueCode.requirementNoOwner,
          message:
              'Requirement ${requirement.id} is approved but has no owner.',
          entityId: requirement.id,
        ),
      );
    }
  }

  void _checkConstraint(
    DesignBrief brief,
    Constraint constraint,
    List<ValidationIssue> issues,
  ) {
    final requirement = brief.requirementById(constraint.requirementId);
    if (requirement == null) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          code: IssueCode.missingRequirement,
          message:
              'Constraint ${constraint.id} refers to missing requirement '
              '${constraint.requirementId}.',
          entityId: constraint.id,
        ),
      );
      return;
    }
    if (requirement.quantity.isEmpty) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.warning,
          code: IssueCode.constraintUncheckable,
          message:
              'Constraint ${constraint.id} cannot be checked. Requirement '
              '${requirement.id} has no declared value.',
          entityId: constraint.id,
          detail: requirement.statement,
        ),
      );
      return;
    }
    final quantityResult = engine.parse(requirement.quantity.raw);
    if (quantityResult.quantity == null) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.warning,
          code: IssueCode.constraintUncheckable,
          message:
              'Constraint ${constraint.id} cannot be checked. Requirement '
              '${requirement.id} has an unrecognized quantity.',
          entityId: constraint.id,
          detail: requirement.quantity.raw,
        ),
      );
      return;
    }
    final quantity = quantityResult.quantity!;

    for (final entry in constraint.bounds.entries) {
      final boundText = entry.value;
      if (boundText.isEmpty) continue;
      final boundResult = engine.parse(boundText.raw);
      if (boundResult.quantity == null) {
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.warning,
            code: IssueCode.constraintBoundUnparsable,
            message:
                'Constraint ${constraint.id} has an unrecognized '
                "${entry.key} bound '${boundText.raw}'.",
            entityId: constraint.id,
            detail: boundResult.error,
          ),
        );
        continue;
      }
      final bound = boundResult.quantity!;
      if (!engine.areCompatible(quantity, bound)) {
        issues.add(
          ValidationIssue(
            severity: IssueSeverity.error,
            code: IssueCode.unitMismatch,
            message:
                'Requirement ${requirement.id} is ${quantity.unit} '
                '(${quantity.dimension.siLabel}) but constraint '
                '${constraint.id} bounds it in ${bound.unit} '
                '(${bound.dimension.siLabel}).',
            entityId: constraint.id,
            detail: requirement.id,
          ),
        );
        continue;
      }
      final violation = _violation(
        constraint.kind,
        entry.key,
        quantity.siValue,
        bound,
      );
      if (violation != null) {
        issues.add(
          ValidationIssue(
            severity: constraint.severity == Severity.hard
                ? IssueSeverity.error
                : IssueSeverity.warning,
            code: IssueCode.constraintViolation,
            message:
                'Requirement ${requirement.id} is ${engine.describe(quantity)} '
                'but $violation (${constraint.id}).',
            entityId: constraint.id,
            detail: constraint.description.isEmpty
                ? requirement.statement
                : constraint.description,
          ),
        );
      }
    }
  }

  /// Returns a description of the violation, or null when the value passes.
  String? _violation(
    ConstraintKind kind,
    String role,
    double value,
    Quantity bound,
  ) {
    final boundValue = bound.siValue;
    switch (kind) {
      case ConstraintKind.min:
        return value < boundValue
            ? 'violates the minimum of ${bound.unit}'
            : null;
      case ConstraintKind.max:
        return value > boundValue
            ? 'exceeds the maximum of ${bound.unit}'
            : null;
      case ConstraintKind.equals:
        return !_closeTo(value, boundValue)
            ? 'differs from the required value of ${bound.unit}'
            : null;
      case ConstraintKind.range:
        if (role == 'min') {
          return value < boundValue
              ? 'falls below the range minimum of ${bound.unit}'
              : null;
        }
        return value > boundValue
            ? 'exceeds the range maximum of ${bound.unit}'
            : null;
    }
  }

  bool _closeTo(double a, double b, {double epsilon = 1e-9}) =>
      (a - b).abs() <= epsilon * (a.abs() + b.abs());
}
