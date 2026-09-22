import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_preferences.dart';

import '../core/theme/app_theme.dart';
import '../features/shell/presentation/library_shell.dart';

class NovellaApp extends ConsumerWidget {
  const NovellaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Novella',
    theme: AppTheme.light,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.canvas,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.canvas,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) *
                ref.watch(appFontProvider),
          ),
        ),
        child: child!,
      ),
    ),
    home: const LibraryShell(),
  );
}
