import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves the default database file location.
///
/// The `EDA_DB` environment variable takes priority. Otherwise the file lives
/// in the user's application data directory.
String defaultDatabasePath() {
  final env = Platform.environment['EDA_DB'];
  if (env != null && env.trim().isNotEmpty) {
    return env;
  }
  final base = Platform.isWindows
      ? Platform.environment['APPDATA'] ?? Platform.environment['TEMP'] ?? '.'
      : Platform.environment['HOME'] ?? '.';
  return p.join(base, 'engineering-design-assistant', 'brief.db');
}
