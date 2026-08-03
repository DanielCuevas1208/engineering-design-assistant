import 'dart:convert';
import 'dart:io';

import '../core/design_brief.dart';

/// Writes the typed design brief handoff to disk.
class BriefExporter {
  BriefExporter._();

  /// Serializes the brief as a pretty-printed JSON string.
  static String toJsonString(DesignBrief brief) =>
      const JsonEncoder.withIndent('  ').convert(brief.toJson());

  /// Writes the brief JSON to [path], creating parent directories.
  static Future<File> writeFile(DesignBrief brief, String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(toJsonString(brief));
    return file;
  }
}
