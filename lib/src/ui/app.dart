import 'package:flutter/material.dart';

import '../store/brief_store.dart';
import 'app_shell.dart';

/// The Engineering Design Assistant application root.
class EdaApp extends StatelessWidget {
  const EdaApp({super.key, required this.store});

  final BriefStore store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B5E9A);
    return MaterialApp(
      title: 'Engineering Design Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
      ),
      home: AppShell(store: store),
    );
  }
}
