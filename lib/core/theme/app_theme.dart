import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF121212);
  static const blue = Color(0xFF1477FA);
  static const canvas = Color(0xFFFCFCFD);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SoftPageTransition(),
        TargetPlatform.iOS: _SoftPageTransition(),
      },
    ),
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: canvas),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.55,
        color: Color(0xFF50515A),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: Color(0xFF777982),
      ),
    ),
  );
}

class _SoftPageTransition extends PageTransitionsBuilder {
  const _SoftPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: const Offset(.045, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
