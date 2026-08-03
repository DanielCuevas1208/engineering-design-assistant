/// Enum values used across the design brief domain.
///
/// Every enum stores a stable [wire] value for JSON and database storage.
/// Unknown wire values fall back to a safe default so older files still load.
library;

/// Classifies the nature of a requirement.
enum RequirementCategory {
  functional('functional', 'Functional'),
  performance('performance', 'Performance'),
  interface('interface', 'Interface'),
  environmental('environmental', 'Environmental'),
  safety('safety', 'Safety'),
  reliability('reliability', 'Reliability'),
  manufacturing('manufacturing', 'Manufacturing'),
  ergonomics('ergonomics', 'Ergonomics'),
  other('other', 'Other');

  const RequirementCategory(this.wire, this.label);

  /// Stable value used on the wire.
  final String wire;

  /// Human-readable label for the user interface.
  final String label;

  static RequirementCategory fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => other);
}

/// MoSCoW priority of a requirement.
enum Priority {
  must('must', 'Must'),
  should('should', 'Should'),
  could('could', 'Could'),
  wont('wont', 'Won\'t'),
  unassigned('unassigned', 'Unassigned');

  const Priority(this.wire, this.label);

  final String wire;
  final String label;

  static Priority fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => unassigned);
}

/// Lifecycle state of a requirement.
enum RequirementStatus {
  draft('draft', 'Draft'),
  proposed('proposed', 'Proposed'),
  approved('approved', 'Approved'),
  superseded('superseded', 'Superseded'),
  rejected('rejected', 'Rejected');

  const RequirementStatus(this.wire, this.label);

  final String wire;
  final String label;

  static RequirementStatus fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => draft);
}

/// How a constraint bounds its target value.
enum ConstraintKind {
  min('min'),
  max('max'),
  range('range'),
  equals('equals');

  const ConstraintKind(this.wire);

  final String wire;

  static ConstraintKind fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => max);
}

/// Whether a constraint is mandatory or advisory.
enum Severity {
  hard('hard', 'Hard'),
  soft('soft', 'Soft');

  const Severity(this.wire, this.label);

  final String wire;
  final String label;

  static Severity fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => hard);
}

/// Lifecycle state of a recorded assumption.
enum AssumptionStatus {
  open('open', 'Open'),
  validated('validated', 'Validated'),
  superseded('superseded', 'Superseded');

  const AssumptionStatus(this.wire, this.label);

  final String wire;
  final String label;

  static AssumptionStatus fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => open);
}

/// Severity of a validation issue.
enum IssueSeverity {
  error('error'),
  warning('warning'),
  info('info');

  const IssueSeverity(this.wire);

  final String wire;

  static IssueSeverity fromWire(String? wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => info);
}

/// Stable codes that identify the kind of a validation issue.
class IssueCode {
  IssueCode._();

  static const unknownUnit = 'UNKNOWN_UNIT';
  static const unitMismatch = 'UNIT_MISMATCH';
  static const constraintViolation = 'CONSTRAINT_VIOLATION';
  static const missingRequirement = 'MISSING_REQUIREMENT';
  static const constraintUncheckable = 'CONSTRAINT_UNCHECKABLE';
  static const constraintBoundUnparsable = 'CONSTRAINT_BOUND_UNPARSABLE';
  static const unresolvedAssumption = 'UNRESOLVED_ASSUMPTION';
  static const requirementNoOwner = 'REQUIREMENT_NO_OWNER';
}
