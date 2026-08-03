import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:engineering_design_assistant/src/db/database_path.dart';
import 'package:engineering_design_assistant/src/db/sqlite_brief_repository.dart';
import 'package:engineering_design_assistant/src/export/brief_exporter.dart';
import 'package:engineering_design_assistant/src/mcp/eda_mcp_server.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:engineering_design_assistant/src/store/brief_store.dart';
import 'package:engineering_design_assistant/src/units/unit_engine.dart';

Future<void> main(List<String> arguments) async {
  final runner =
      CommandRunner<void>(
          'eda',
          'Captures engineering requirements and checks units and constraints.',
        )
        ..addCommand(InitCommand())
        ..addCommand(SampleCommand())
        ..addCommand(ValidateCommand())
        ..addCommand(ExportCommand())
        ..addCommand(ImportCommand())
        ..addCommand(UnitsCommand())
        ..addCommand(ServerCommand());

  await runner.run(arguments);
}

String _dbPath(ArgResults results) =>
    results['db'] as String? ?? defaultDatabasePath();

Future<BriefStore> _openStore(String dbPath) async {
  final repository = await SqliteBriefRepository.open(path: dbPath);
  final store = BriefStore(repository: repository);
  await store.init();
  return store;
}

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description => 'Creates an empty brief database.';

  @override
  String get invocation => 'eda init [--db PATH]';

  @override
  Future<void> run() async {
    final store = await _openStore(_dbPath(argResults!));
    await store.close();
    stdout.writeln('Initialized ${_dbPath(argResults!)}.');
  }
}

class SampleCommand extends Command<void> {
  @override
  String get name => 'sample';

  @override
  String get description => 'Loads the sample linear actuator brief.';

  @override
  String get invocation => 'eda sample [--db PATH] [--out PATH]';

  @override
  Future<void> run() async {
    final store = await _openStore(_dbPath(argResults!));
    await store.replaceWith(SampleBrief.build());
    final brief = store.brief;
    await store.close();

    final out = argResults!['out'] as String?;
    if (out != null) {
      await BriefExporter.writeFile(brief, out);
      stdout.writeln('Wrote brief to $out.');
    } else {
      stdout.writeln(
        'Loaded ${brief.requirements.length} requirements, '
        '${brief.constraints.length} constraints, '
        '${brief.assumptions.length} assumptions.',
      );
    }
  }
}

class ValidateCommand extends Command<void> {
  @override
  String get name => 'validate';

  @override
  String get description => 'Runs the constraint and unit checks.';

  @override
  String get invocation => 'eda validate [--db PATH]';

  @override
  Future<void> run() async {
    final store = await _openStore(_dbPath(argResults!));
    final report = store.runValidation();
    await store.close();

    stdout.writeln(
      'Validated ${report.requirementCount} requirements against '
      '${report.constraintCount} constraints.',
    );
    stdout.writeln(
      '${report.errorCount} errors, ${report.warningCount} warnings, '
      '${report.infoCount} notes.',
    );
    stdout.writeln(report.passes ? 'PASS' : 'FAIL');
    for (final issue in report.issues) {
      stdout.writeln(
        '[${issue.severity.wire.toUpperCase()}] ${issue.code} '
        '${issue.entityId ?? ''} ${issue.message}',
      );
    }
    exitCode = report.passes ? 0 : 2;
  }
}

class ExportCommand extends Command<void> {
  @override
  String get name => 'export';

  @override
  String get description => 'Writes the typed design brief handoff to JSON.';

  @override
  String get invocation => 'eda export --out PATH [--db PATH]';

  @override
  Future<void> run() async {
    final out = argResults!['out'] as String?;
    if (out == null || out.isEmpty) {
      throw UsageException('--out is required.', invocation);
    }
    final store = await _openStore(_dbPath(argResults!));
    final brief = store.brief;
    await store.close();
    await BriefExporter.writeFile(brief, out);
    stdout.writeln('Wrote ${brief.requirements.length} requirements to $out.');
  }
}

class ImportCommand extends Command<void> {
  @override
  String get name => 'import';

  @override
  String get description => 'Replaces the brief from a JSON handoff file.';

  @override
  String get invocation => 'eda import --in PATH [--db PATH]';

  @override
  Future<void> run() async {
    final inPath = argResults!['in'] as String?;
    if (inPath == null || inPath.isEmpty) {
      throw UsageException('--in is required.', invocation);
    }
    final text = await File(inPath).readAsString();
    final store = await _openStore(_dbPath(argResults!));
    final brief = await store.importJson(text);
    await store.close();
    stdout.writeln(
      'Imported ${brief.requirements.length} requirements from $inPath.',
    );
  }
}

class UnitsCommand extends Command<void> {
  @override
  String get name => 'units';

  @override
  String get description => 'Converts a value between compatible units.';

  @override
  String get invocation => 'eda units "<VALUE>" "<TO-UNIT>"';

  @override
  Future<void> run() async {
    final args = argResults!.rest;
    if (args.length != 2) {
      throw UsageException('Expected a value and a target unit.', invocation);
    }
    final parsed = const UnitEngine().parse(args[0]);
    if (parsed.quantity == null) {
      stderr.writeln(parsed.error);
      exitCode = 2;
      return;
    }
    final result = const UnitEngine().convert(parsed.quantity!, args[1]);
    if (result.value == null) {
      stderr.writeln(result.error);
      exitCode = 2;
      return;
    }
    stdout.writeln(
      '${parsed.quantity!.value} ${parsed.quantity!.unit} = '
      '${UnitEngine.format(result.value!)} ${args[1]}',
    );
  }
}

class ServerCommand extends Command<void> {
  @override
  String get name => 'server';

  @override
  String get description => 'Runs the MCP server over stdio.';

  @override
  String get invocation => 'eda server [--db PATH]';

  @override
  Future<void> run() async {
    final store = await _openStore(_dbPath(argResults!));
    final server = EdaMcpServer(
      channel: stdioChannel(input: stdin, output: stdout),
      store: store,
    );
    await server.initialized;
    await server.done;
    await store.close();
  }
}
