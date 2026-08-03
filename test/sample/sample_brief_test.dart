import 'package:engineering_design_assistant/src/core/enums.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:engineering_design_assistant/src/validation/constraint_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const checker = ConstraintChecker();

  group('SampleBrief', () {
    test('contains the expected entities', () {
      final brief = SampleBrief.build();
      expect(brief.requirements.length, 8);
      expect(brief.constraints.length, 8);
      expect(brief.assumptions.length, 3);
      expect(brief.openAssumptionCount, 2);
    });

    test('validates to a deterministic report', () {
      final report = checker.check(SampleBrief.build());

      expect(report.errorCount, 2);
      expect(report.warningCount, 1);
      expect(report.infoCount, 2);
      expect(report.passes, isFalse);
    });

    test('flags the stall load violation', () {
      final report = checker.check(SampleBrief.build());
      final violation = report.issues.firstWhere(
        (issue) => issue.code == IssueCode.constraintViolation,
      );
      expect(violation.entityId, 'CON-002');
      expect(violation.message, contains('REQ-002'));
      expect(violation.message, contains('exceeds the maximum'));
    });

    test('flags the unrecognized noise unit', () {
      final report = checker.check(SampleBrief.build());
      final unitIssue = report.issues.firstWhere(
        (issue) => issue.code == IssueCode.unknownUnit,
      );
      expect(unitIssue.entityId, 'REQ-006');
      expect(unitIssue.detail, contains('dB'));
    });

    test('exposes both open assumptions', () {
      final report = checker.check(SampleBrief.build());
      final assumptions = report.issues
          .where((issue) => issue.code == IssueCode.unresolvedAssumption)
          .toList();
      expect(assumptions.map((issue) => issue.entityId), containsAll(['ASM-001', 'ASM-002']));
    });
  });
}
