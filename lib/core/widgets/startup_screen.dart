import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'novella_loading_indicator.dart';

/// Shown while real initialization runs, without an artificial startup delay.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.failed = false});
  final bool failed;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: const Color(0xFFFCFCFD),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFE4EFFF), Color(0xFFFCFCFD)],
            radius: .8,
            center: Alignment(0, -.25),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!failed)
                    const NovellaLoadingIndicator()
                  else
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: Color(0xFF1477FA),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Novella',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Color(0xFF14284C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    failed
                        ? 'We couldn’t start your library'
                        : 'A new chapter awaits',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF61718A),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (!failed)
                    const SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        color: Color(0xFF1477FA),
                        backgroundColor: Color(0xFFDDEAFF),
                      ),
                    )
                  else
                    const Text(
                      'Check your connection and restart the app. If this continues, contact support.',
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
