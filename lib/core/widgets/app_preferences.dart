import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appFontProvider = StateNotifierProvider<AppFontController, double>(
  (ref) => AppFontController(),
);

class AppFontController extends StateNotifier<double> {
  AppFontController() : super(1) {
    _restore();
  }
  bool _changed = false;
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted && !_changed) {
      state = (prefs.getDouble('app_font_scale') ?? 1).clamp(.85, 1.25);
    }
  }

  Future<void> update(double value) async {
    _changed = true;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_font_scale', value);
  }
}

void showAppAppearance(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final scale = ref.watch(appFontProvider);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Text size', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'Adjust text across Novella. PDF pages keep their original layout; use A− / A+ to zoom.',
              ),
              Slider(
                value: scale,
                min: .85,
                max: 1.25,
                divisions: 8,
                label: '${(scale * 100).round()}%',
                onChanged: (value) =>
                    ref.read(appFontProvider.notifier).update(value),
              ),
              Text('Preview · ${(scale * 100).round()}%'),
              TextButton(
                onPressed: () => ref.read(appFontProvider.notifier).update(1),
                child: const Text('Reset to default'),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

void showAppNotice(BuildContext context, String title, String message) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
