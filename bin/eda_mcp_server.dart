import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:engineering_design_assistant/src/db/database_path.dart';
import 'package:engineering_design_assistant/src/db/sqlite_brief_repository.dart';
import 'package:engineering_design_assistant/src/mcp/eda_mcp_server.dart';
import 'package:engineering_design_assistant/src/store/brief_store.dart';

/// Starts the Engineering Design Assistant MCP server over stdio.
///
/// Configure it in an MCP client with the command:
///   dart run bin/eda_mcp_server.dart
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'db',
      help: 'SQLite database path.',
      defaultsTo: defaultDatabasePath(),
    );
  final results = parser.parse(arguments);

  final repository = await SqliteBriefRepository.open(
    path: results['db'] as String,
  );
  final store = BriefStore(repository: repository);
  await store.init();

  final server = EdaMcpServer(
    channel: stdioChannel(input: stdin, output: stdout),
    store: store,
  );
  await server.initialized;
  await server.done;
  await store.close();
}
