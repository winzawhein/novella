import 'package:flutter/material.dart';

import 'glass_action_button.dart';

bool isConnectionFailure(Object error) {
  final text = error.toString().toLowerCase();
  return [
    'socket',
    'connection refused',
    'failed host lookup',
    'network',
    'timeout',
    'timed out',
    'connection reset',
    'failed to fetch',
  ].any(text.contains);
}

bool _helpVisible = false;
DateTime? _lastAutomaticHelp;

Future<void> showConnectionHelp(
  BuildContext context, {
  bool automatic = false,
}) async {
  if (_helpVisible) return;
  if (automatic &&
      _lastAutomaticHelp != null &&
      DateTime.now().difference(_lastAutomaticHelp!) <
          const Duration(minutes: 2)) {
    return;
  }
  if (automatic) _lastAutomaticHelp = DateTime.now();
  _helpVisible = true;
  try {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF3F7FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.vpn_lock_rounded,
                    color: Color(0xFF1477FA),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'A little help connecting',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Some mobile networks in Myanmar may not reach our service. Check your internet first. If access is blocked, open your VPN app and turn it on, then return to Novella and retry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Novella cannot enable or verify your VPN for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF697588)),
                ),
                const SizedBox(height: 24),
                GlassActionButton(
                  label: 'Got it — I’ll check',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } finally {
    _helpVisible = false;
  }
}
