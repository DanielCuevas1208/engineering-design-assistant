import 'package:engineering_design_assistant/src/db/sqlite_brief_repository.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SqliteBriefRepository repository;

  setUp(() async {
    repository = await SqliteBriefRepository.openInMemory();
  });

  tearDown(() async {
    await repository.close();
  });

  group('SqliteBriefRepository', () {
    test('returns an empty brief for a fresh database', () async {
      final brief = await repository.loadBrief();
      expect(brief.requirements, isEmpty);
      expect(brief.constraints, isEmpty);
      expect(brief.assumptions, isEmpty);
      expect(brief.projectName, 'Untitled project');
    });

    test('persists the sample brief', () async {
      final sample = SampleBrief.build();
      await repository.saveBrief(sample);

      final loaded = await repository.loadBrief();
      expect(loaded.projectName, 'Compact linear actuator');
      expect(loaded.requirements.length, 8);
      expect(loaded.constraints.length, 8);
      expect(loaded.assumptions.length, 3);

      final first = loaded.requirements.first;
      expect(first.id, 'REQ-001');
      expect(first.quantity.raw, '100 mm');
      expect(first.category.wire, 'performance');
    });

    test('replaces the stored brief atomically', () async {
      final sample = SampleBrief.build();
      await repository.saveBrief(sample);

      final replacement = SampleBrief.build().copyWith(
        projectName: 'Second project',
        requirements: const [],
        constraints: const [],
        assumptions: const [],
      );
      await repository.saveBrief(replacement);

      final loaded = await repository.loadBrief();
      expect(loaded.projectName, 'Second project');
      expect(loaded.requirements, isEmpty);
    });

    test('round-trips constraint bounds', () async {
      final sample = SampleBrief.build();
      await repository.saveBrief(sample);

      final loaded = await repository.loadBrief();
      final range = loaded.constraints.firstWhere((c) => c.id == 'CON-001');
      expect(range.kind.wire, 'range');
      expect(range.min.raw, '9.5 cm');
      expect(range.max.raw, '105 mm');
    });
  });
}
