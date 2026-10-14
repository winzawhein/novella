import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/novella_app.dart';
import 'core/config/app_config.dart';
import 'core/widgets/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _Startup()));
}

class _Startup extends StatefulWidget {
  const _Startup();
  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late final Future<void> _ready = _initialize();
  Future<void> _initialize() async {
    AppConfig.validate();
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child:
          snapshot.connectionState == ConnectionState.done && !snapshot.hasError
          ? const NovellaApp(key: ValueKey('ready'))
          : MaterialApp(
              key: const ValueKey('startup'),
              debugShowCheckedModeBanner: false,
              home: StartupScreen(failed: snapshot.hasError),
            ),
    ),
  );
}
