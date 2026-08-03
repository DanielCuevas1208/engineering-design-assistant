import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/design_brief.dart';
import '../db/database_path.dart';
import '../export/brief_exporter.dart';
import '../store/brief_store.dart';

/// Builds the default export path for the current project.
String defaultExportPath(DesignBrief brief) {
  final base = p.dirname(defaultDatabasePath());
  final stamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final name = brief.projectName.toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  return p.join(base, 'exports', '$name-$stamp.json');
}

/// Writes the brief handoff to disk and returns the created file.
Future<File> writeBriefExport(BriefStore store, {String? path}) async {
  final target = path ?? defaultExportPath(store.brief);
  return BriefExporter.writeFile(store.brief, target);
}
