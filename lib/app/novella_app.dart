import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/presentation/library_shell.dart';

class NovellaApp extends StatelessWidget {
  const NovellaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Novella',
    theme: AppTheme.light,
    home: const LibraryShell(),
  );
}
