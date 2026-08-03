import '../core/assumption.dart';
import '../core/constraint.dart';
import '../core/design_brief.dart';
import '../core/enums.dart';
import '../core/quantity_text.dart';
import '../core/requirement.dart';

/// A small, realistic brief for a compact linear actuator.
///
/// The data is intentionally imperfect: it contains one hard violation, one
/// unknown unit, one uncheckable constraint, and two open assumptions. This
/// demonstrates what the validator finds and exposes.
class SampleBrief {
  SampleBrief._();

  static DesignBrief build() {
    final now = DateTime.utc(2026, 1, 15, 12, 0, 0);
    return DesignBrief(
      projectName: 'Compact linear actuator',
      projectVersion: '0.1.0',
      purpose: 'Automated valve positioner for a laboratory test rig.',
      createdAt: now,
      updatedAt: now,
      requirements: const [
        Requirement(
          id: 'REQ-001',
          statement: 'The mechanism shall provide a linear stroke of 100 mm.',
          category: RequirementCategory.performance,
          priority: Priority.must,
          status: RequirementStatus.approved,
          owner: 'Drives',
          rationale: 'Covers the full valve travel plus margin.',
          quantity: QuantityText('100 mm'),
        ),
        Requirement(
          id: 'REQ-002',
          statement: 'The actuator shall hold a stall load of 2 kN.',
          category: RequirementCategory.performance,
          priority: Priority.must,
          status: RequirementStatus.approved,
          owner: 'Drives',
          rationale: 'Worst-case friction in the packed gland.',
          quantity: QuantityText('2 kN'),
        ),
        Requirement(
          id: 'REQ-003',
          statement: 'The actuator shall reach a feed speed of 60 mm/s.',
          category: RequirementCategory.performance,
          priority: Priority.should,
          status: RequirementStatus.proposed,
          owner: 'Drives',
          quantity: QuantityText('60 mm/s'),
        ),
        Requirement(
          id: 'REQ-004',
          statement: 'The actuator shall operate at 50 °C ambient.',
          category: RequirementCategory.environmental,
          priority: Priority.must,
          status: RequirementStatus.approved,
          owner: 'Thermal',
          rationale: 'Derates the motor windings.',
          quantity: QuantityText('50 °C'),
        ),
        Requirement(
          id: 'REQ-005',
          statement: 'The enclosure shall fit within 400 mm.',
          category: RequirementCategory.interface,
          priority: Priority.must,
          status: RequirementStatus.approved,
          owner: 'Packaging',
          quantity: QuantityText('400 mm'),
        ),
        Requirement(
          id: 'REQ-006',
          statement: 'The actuator shall emit no more than 62 dB(A).',
          category: RequirementCategory.safety,
          priority: Priority.should,
          status: RequirementStatus.proposed,
          owner: 'Acoustics',
          quantity: QuantityText('62 dB(A)'),
        ),
        Requirement(
          id: 'REQ-007',
          statement:
              'The actuator shall use a Type II anodized finish on all '
              'exposed aluminum.',
          category: RequirementCategory.manufacturing,
          priority: Priority.should,
          status: RequirementStatus.proposed,
          owner: 'Materials',
        ),
        Requirement(
          id: 'REQ-008',
          statement: 'The actuator shall sustain a duty cycle of 30 %.',
          category: RequirementCategory.reliability,
          priority: Priority.must,
          status: RequirementStatus.approved,
          owner: 'Reliability',
          quantity: QuantityText('30 %'),
        ),
      ],
      constraints: const [
        Constraint(
          id: 'CON-001',
          requirementId: 'REQ-001',
          description: 'Stroke tolerance band.',
          kind: ConstraintKind.range,
          severity: Severity.hard,
          min: QuantityText('9.5 cm'),
          max: QuantityText('105 mm'),
        ),
        Constraint(
          id: 'CON-002',
          requirementId: 'REQ-002',
          description: 'Rated stall load.',
          kind: ConstraintKind.max,
          severity: Severity.hard,
          value: QuantityText('1.8 kN'),
        ),
        Constraint(
          id: 'CON-003',
          requirementId: 'REQ-003',
          description: 'Maximum feed speed.',
          kind: ConstraintKind.max,
          severity: Severity.soft,
          value: QuantityText('75 mm/s'),
        ),
        Constraint(
          id: 'CON-004',
          requirementId: 'REQ-004',
          description: 'Maximum ambient temperature.',
          kind: ConstraintKind.max,
          severity: Severity.hard,
          value: QuantityText('50 °C'),
        ),
        Constraint(
          id: 'CON-005',
          requirementId: 'REQ-005',
          description: 'Maximum enclosure length.',
          kind: ConstraintKind.max,
          severity: Severity.hard,
          value: QuantityText('420 mm'),
        ),
        Constraint(
          id: 'CON-006',
          requirementId: 'REQ-008',
          description: 'Maximum sustained duty cycle.',
          kind: ConstraintKind.max,
          severity: Severity.hard,
          value: QuantityText('35 %'),
        ),
        Constraint(
          id: 'CON-007',
          requirementId: 'REQ-007',
          description: 'Minimum finish thickness.',
          kind: ConstraintKind.min,
          severity: Severity.hard,
          value: QuantityText('500 g'),
        ),
        Constraint(
          id: 'CON-008',
          requirementId: 'REQ-001',
          description: 'Stroke shall not bottom out.',
          kind: ConstraintKind.min,
          severity: Severity.hard,
          value: QuantityText('5 cm'),
        ),
      ],
      assumptions: const [
        Assumption(
          id: 'ASM-001',
          statement: 'Ambient air is still and dry; natural convection only.',
          owner: 'Thermal',
          status: AssumptionStatus.open,
          requirementId: 'REQ-004',
          rationale: 'Affects the motor derating curve.',
        ),
        Assumption(
          id: 'ASM-002',
          statement: 'Supply voltage stays within ±5% of nominal.',
          owner: 'Electrical',
          status: AssumptionStatus.open,
          rationale: 'Limits stall torque variation.',
        ),
        Assumption(
          id: 'ASM-003',
          statement: 'Coupling backlash is below 0.1 mm.',
          owner: 'Drives',
          status: AssumptionStatus.validated,
          rationale: 'Confirmed by the vendor datasheet.',
        ),
      ],
    );
  }
}
