import 'dart:convert';

import 'package:dart_mcp/client.dart';
import 'package:engineering_design_assistant/src/core/design_brief.dart';
import 'package:engineering_design_assistant/src/db/in_memory_brief_repository.dart';
import 'package:engineering_design_assistant/src/mcp/eda_mcp_server.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:engineering_design_assistant/src/store/brief_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';

void main() {
  late EdaMcpServer server;
  late BriefStore store;
  late MCPClient client;
  late ServerConnection connection;
  late StreamChannelController<String> controller;

  setUp(() async {
    store = BriefStore(repository: InMemoryBriefRepository(SampleBrief.build()));
    await store.init();

    controller = StreamChannelController<String>();
    server = EdaMcpServer(channel: controller.local, store: store);

    client = MCPClient(Implementation(name: 'test-client', version: '0.1.0'));
    connection = client.connectServer(controller.remote);
    await connection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    connection.notifyInitialized();
  });

  tearDown(() async {
    await client.shutdown();
    await controller.local.sink.close();
    await store.close();
  });

  String textOf(CallToolResult result) {
    final content = result.content.single;
    if (content.isText) {
      return (content as TextContent).text;
    }
    fail('Expected a text result but got ${content.type}');
  }

  Future<Map<String, Object?>> call(String name, [Map<String, Object?> args = const {}]) async {
    final result = await connection.callTool(CallToolRequest(name: name, arguments: args));
    if (result.isError == true) {
      fail('Tool $name failed: ${textOf(result)}');
    }
    return (jsonDecode(textOf(result)) as Map).cast<String, Object?>();
  }

  group('EdaMcpServer', () {
    test('exposes the expected tools', () async {
      final result = await connection.listTools(ListToolsRequest());
      final names = {for (final tool in result.tools) tool.name};
      expect(
        names,
        containsAll([
          'get_status',
          'list_requirements',
          'add_requirement',
          'update_requirement',
          'delete_requirement',
          'list_constraints',
          'add_constraint',
          'convert_quantity',
          'validate_brief',
          'export_brief',
          'add_assumption',
          'list_assumptions',
        ]),
      );
    });

    test('reports the store status', () async {
      final status = await call('get_status');
      expect(status['tool'], 'engineering-design-assistant');
      expect(status['schema'], designBriefSchemaId);
      expect((status['counts'] as Map)['requirements'], 8);
      expect((status['counts'] as Map)['openAssumptions'], 2);
    });

    test('adds a requirement', () async {
      final added = await call('add_requirement', {
        'statement': 'Shall fit in the envelope.',
        'category': 'interface',
        'priority': 'must',
        'value': '400 mm',
      });
      expect(added['id'], 'REQ-009');
      expect(added['quantity'], '400 mm');
      expect(added['category'], 'interface');
    });

    test('adds and lists a constraint', () async {
      await call('add_constraint', {
        'requirementId': 'REQ-002',
        'kind': 'max',
        'severity': 'soft',
        'value': '1.9 kN',
      });
      final constraints = await call('list_constraints', {'requirementId': 'REQ-002'});
      expect((constraints['items'] as List).length, 1);
    });

    test('converts quantities', () async {
      final result = await call('convert_quantity', {'value': '2.5 kN', 'to': 'N'});
      expect(result['value'], closeTo(2500, 1e-6));
    });

    test('rejects an incompatible conversion', () async {
      final result = await connection.callTool(
        CallToolRequest(name: 'convert_quantity', arguments: {'value': '2 kN', 'to': 'mm'}),
      );
      expect(result.isError, isTrue);
    });

    test('validates the brief', () async {
      final report = await call('validate_brief');
      expect(report['passes'], isFalse);
      expect(report['errorCount'], 2);
      expect(report['issues'], hasLength(5));
    });

    test('exports the typed handoff', () async {
      final exported = await call('export_brief');
      expect(exported['schema'], designBriefSchemaId);
      final requirements = exported['requirements'] as List;
      expect(requirements, hasLength(8));
    });

    test('tracks assumptions and their status', () async {
      final added = await call('add_assumption', {
        'statement': 'The bench is level.',
        'requirementId': 'REQ-005',
      });
      final id = added['id'] as String;
      await call('update_assumption_status', {'id': id, 'status': 'validated'});
      final assumptions = await call('list_assumptions', {'status': 'validated'});
      expect(
        (assumptions['items'] as List).any(
          (item) => (item as Map)['id'] == id,
        ),
        isTrue,
      );
    });
  });
}
