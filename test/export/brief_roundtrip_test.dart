import 'dart:convert';

import 'package:engineering_design_assistant/src/core/design_brief.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesignBrief JSON', () {
    test('round-trips the sample brief', () {
      final brief = SampleBrief.build();
      final json = brief.toJson();
      final decoded = DesignBrief.fromJson(json);

      expect(decoded.projectName, brief.projectName);
      expect(decoded.projectVersion, brief.projectVersion);
      expect(decoded.purpose, brief.purpose);
      expect(decoded.requirements.length, brief.requirements.length);
      expect(decoded.constraints.length, brief.constraints.length);
      expect(decoded.assumptions.length, brief.assumptions.length);

      final first = decoded.requirements.first;
      expect(first.id, 'REQ-001');
      expect(first.quantity.raw, '100 mm');
      expect(first.category.wire, 'performance');
    });

    test('decodes the canonical JSON document', () {
      const document = '''
      {
        "schema": "engineering-design-assistant/design-brief/1.0",
        "project": {"name": "Demo", "version": "1.0.0", "purpose": "Test."},
        "createdAt": "2026-01-01T00:00:00.000Z",
        "updatedAt": "2026-01-01T00:00:00.000Z",
        "requirements": [
          {
            "id": "REQ-001",
            "statement": "Shall hold 2 kN.",
            "category": "performance",
            "priority": "must",
            "status": "approved",
            "owner": "Drives",
            "rationale": "",
            "quantity": "2 kN"
          }
        ],
        "constraints": [
          {
            "id": "CON-001",
            "requirementId": "REQ-001",
            "description": "Rated load.",
            "kind": "max",
            "severity": "hard",
            "value": "1.8 kN"
          }
        ],
        "assumptions": []
      }
      ''';
      final brief = DesignBrief.fromJson(
        (jsonDecode(document) as Map).cast<String, Object?>(),
      );
      expect(brief.projectName, 'Demo');
      expect(brief.requirements.single.id, 'REQ-001');
      expect(brief.constraints.single.value.raw, '1.8 kN');
    });

    test('rejects an unsupported schema', () {
      expect(
        () => DesignBrief.fromJson(const {'schema': 'wrong/1.0'}),
        throwsFormatException,
      );
    });

    test('rejects a requirement without an id', () {
      expect(
        () => DesignBrief.fromJson({
          'schema': designBriefSchemaId,
          'project': {},
          'requirements': [
            {'statement': 'No id here.'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('keeps entity JSON stable and compact', () {
      final brief = SampleBrief.build();
      final decoded = DesignBrief.fromJson(brief.toJson());
      final reEncoded = DesignBrief.fromJson(decoded.toJson());
      expect(reEncoded.requirements.length, brief.requirements.length);
      expect(reEncoded.constraints.first.kind.wire, 'range');
    });
  });
}
