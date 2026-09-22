import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFFFCFCFD),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Notifications',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .9, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0F7FF), Color(0xFFDDEAFF)],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x181477FA),
                          blurRadius: 36,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 58,
                      color: Color(0xFF1477FA),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'A little peace and quiet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No notifications yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF777982)),
                ),
                const SizedBox(height: 28),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF1477FA),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Push notifications and scheduled reminders are not enabled in this version.',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Back to books'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
