import 'package:flutter/material.dart';

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

Future<void> showConnectionHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.vpn_lock_rounded, color: Color(0xFF1477FA)),
    title: const Text('Having trouble connecting?'),
    content: const Text(
      'Check your internet connection first. If your network cannot reach Novella’s service, try turning on your VPN, then return to the app and try again.\n\nNovella cannot detect or enable your VPN automatically.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);
