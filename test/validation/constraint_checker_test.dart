import 'package:engineering_design_assistant/src/core/assumption.dart';
import 'package:engineering_design_assistant/src/core/constraint.dart';
import 'package:engineering_design_assistant/src/core/design_brief.dart';
import 'package:engineering_design_assistant/src/core/enums.dart';
import 'package:engineering_design_assistant/src/core/quantity_text.dart';
import 'package:engineering_design_assistant/src/core/requirement.dart';
import 'package:engineering_design_assistant/src/validation/constraint_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const checker = ConstraintChecker();

  DesignBrief brief({
    List<Requirement> requirements = const [],
    List<Constraint> constraints = const [],
    List<Assumption> assumptions = const [],
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return DesignBrief(
      createdAt: now,
      updatedAt: now,
      requirements: requirements,
      constraints: constraints,
      assumptions: assumptions,
    );
  }

  const loadRequirement = Requirement(
    id: 'REQ-001',
    statement: 'Shall hold 2 kN.',
    quantity: QuantityText('2 kN'),
  );

  group('ConstraintChecker', () {
    test('flags a hard constraint violation', () {
      final report = checker.check(
        brief(
          requirements: const [loadRequirement],
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-001',
              kind: ConstraintKind.max,
              severity: Severity.hard,
              value: QuantityText('1.8 kN'),
            ),
          ],
        ),
      );
      expect(report.passes, isFalse);
      final issue = report.issues.single;
      expect(issue.code, IssueCode.constraintViolation);
      expect(issue.severity, IssueSeverity.error);
      expect(issue.message, contains('REQ-001'));
      expect(issue.message, contains('exceeds the maximum'));
    });

    test('accepts values that meet a soft bound', () {
      final report = checker.check(
        brief(
          requirements: const [loadRequirement],
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-001',
              kind: ConstraintKind.max,
              severity: Severity.soft,
              value: QuantityText('3 kN'),
            ),
          ],
        ),
      );
      expect(report.passes, isTrue);
      expect(report.issues, isEmpty);
    });

    test('checks range bounds with unit conversion', () {
      final report = checker.check(
        brief(
          requirements: const [
            Requirement(
              id: 'REQ-001',
              statement: 'Stroke of 100 mm.',
              quantity: QuantityText('100 mm'),
            ),
          ],
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-001',
              kind: ConstraintKind.range,
              severity: Severity.hard,
              min: QuantityText('9.5 cm'),
              max: QuantityText('105 mm'),
            ),
          ],
        ),
      );
      expect(report.passes, isTrue);
      expect(report.issues, isEmpty);
    });

    test('flags a mismatch of units', () {
      final report = checker.check(
        brief(
          requirements: const [loadRequirement],
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-001',
              kind: ConstraintKind.max,
              severity: Severity.hard,
              value: QuantityText('300 mm'),
            ),
          ],
        ),
      );
      final issue = report.issues.single;
      expect(issue.code, IssueCode.unitMismatch);
      expect(issue.severity, IssueSeverity.error);
    });

    test('flags an unknown unit on the requirement', () {
      final report = checker.check(
        brief(
          requirements: const [
            Requirement(
              id: 'REQ-001',
              statement: 'Noise below 62 dB(A).',
              quantity: QuantityText('62 dB(A)'),
            ),
          ],
        ),
      );
      final issue = report.issues.single;
      expect(issue.code, IssueCode.unknownUnit);
      expect(issue.severity, IssueSeverity.error);
    });

    test('flags a constraint that references a missing requirement', () {
      final report = checker.check(
        brief(
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-999',
              kind: ConstraintKind.max,
              value: QuantityText('1 kN'),
            ),
          ],
        ),
      );
      final issue = report.issues.single;
      expect(issue.code, IssueCode.missingRequirement);
      expect(issue.severity, IssueSeverity.error);
    });

    test('flags a constraint that cannot be checked', () {
      final report = checker.check(
        brief(
          requirements: const [
            Requirement(id: 'REQ-001', statement: 'No value given.'),
          ],
          constraints: const [
            Constraint(
              id: 'CON-001',
              requirementId: 'REQ-001',
              kind: ConstraintKind.max,
              value: QuantityText('1 kN'),
            ),
          ],
        ),
      );
      final issue = report.issues.single;
      expect(issue.code, IssueCode.constraintUncheckable);
      expect(issue.severity, IssueSeverity.warning);
    });

    test('exposes open assumptions', () {
      final report = checker.check(
        brief(
          assumptions: const [
            Assumption(id: 'ASM-001', statement: 'Air is still.'),
            Assumption(
              id: 'ASM-002',
              statement: 'Voltage is stable.',
              status: AssumptionStatus.validated,
            ),
          ],
        ),
      );
      expect(report.openAssumptionCount, 1);
      final issue = report.issues.single;
      expect(issue.code, IssueCode.unresolvedAssumption);
      expect(issue.severity, IssueSeverity.info);
      expect(issue.entityId, 'ASM-001');
    });

    test('flags approved requirements without an owner', () {
      final report = checker.check(
        brief(
          requirements: const [
            Requirement(
              id: 'REQ-001',
              statement: 'Must work.',
              status: RequirementStatus.approved,
            ),
          ],
        ),
      );
      final issue = report.issues.single;
      expect(issue.code, IssueCode.requirementNoOwner);
      expect(issue.severity, IssueSeverity.warning);
    });
  });
}
