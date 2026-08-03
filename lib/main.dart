import 'package:flutter/material.dart';

import 'src/db/database_path.dart';
import 'src/db/sqlite_brief_repository.dart';
import 'src/store/brief_store.dart';
import 'src/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteBriefRepository.open(
    path: defaultDatabasePath(),
  );
  final store = BriefStore(repository: repository);
  await store.init();
  runApp(EdaApp(store: store));
}
