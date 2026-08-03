import 'package:engineering_design_assistant/src/core/enums.dart';
import 'package:engineering_design_assistant/src/core/quantity_text.dart';
import 'package:engineering_design_assistant/src/db/in_memory_brief_repository.dart';
import 'package:engineering_design_assistant/src/store/brief_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BriefStore store;

  setUp(() {
    store = BriefStore(repository: InMemoryBriefRepository());
  });

  tearDown(() async {
    await store.close();
  });

  group('BriefStore', () {
    test('initializes from the repository', () async {
      await store.init();
      expect(store.loaded, isTrue);
      expect(store.brief.requirements, isEmpty);
    });

    test('assigns sequential ids', () async {
      await store.init();
      final first = await store.addRequirement(
        statement: 'First.',
        priority: Priority.must,
      );
      final second = await store.addRequirement(statement: 'Second.');
      expect(first.id, 'REQ-001');
      expect(second.id, 'REQ-002');
    });

    test('persists mutations to the repository', () async {
      await store.init();
      await store.addRequirement(statement: 'A requirement.');
      final reloaded = await store.repository.loadBrief();
      expect(reloaded.requirements.single.statement, 'A requirement.');
    });

    test('updates and removes requirements', () async {
      await store.init();
      final requirement = await store.addRequirement(
        statement: 'Old text.',
        quantity: const QuantityText('10 mm'),
      );
      await store.updateRequirement(
        requirement.copyWith(
          statement: 'New text.',
          status: RequirementStatus.approved,
        ),
      );
      var updated = store.brief.requirementById(requirement.id)!;
      expect(updated.statement, 'New text.');
      expect(updated.status, RequirementStatus.approved);

      await store.removeRequirement(requirement.id);
      expect(store.brief.requirementById(requirement.id), isNull);
    });

    test('removes dependent constraints and assumptions', () async {
      await store.init();
      final requirement = await store.addRequirement(
        statement: 'Parent.',
        quantity: const QuantityText('100 mm'),
      );
      await store.addConstraint(requirementId: requirement.id);
      await store.addAssumption(
        statement: 'Depends on parent.',
        requirementId: requirement.id,
      );
      await store.removeRequirement(requirement.id);
      expect(store.constraintCount, 0);
      expect(store.assumptionCount, 0);
    });

    test('tracks open assumptions', () async {
      await store.init();
      await store.addAssumption(statement: 'First.');
      await store.addAssumption(statement: 'Second.');
      await store.addAssumption(statement: 'Done.');
      final resolved = store.brief.assumptions.last;
      await store.updateAssumption(
        resolved.copyWith(status: AssumptionStatus.validated),
      );
      expect(store.openAssumptionCount, 2);
    });

    test('stores the last validation report', () async {
      await store.init();
      await store.addRequirement(statement: 'Anything.');
      final report = store.runValidation();
      expect(report.requirementCount, 1);
      expect(store.validation, same(report));
    });

    test('exports JSON and imports it back', () async {
      await store.init();
      await store.addRequirement(statement: 'One.');
      final exported = store.exportJson(includeValidation: false);
      expect(exported, contains('design-brief/1.0'));
      expect(exported, isNot(contains('validation')));

      final fresh = BriefStore(repository: InMemoryBriefRepository());
      await fresh.init();
      await fresh.importJson(exported);
      expect(fresh.requirementCount, 1);
      expect(fresh.brief.requirements.single.statement, 'One.');
      await fresh.close();
    });

    test('rejects malformed import', () async {
      await store.init();
      expect(() => store.importJson('not json'), throwsFormatException);
    });
  });
}
