import 'package:flutter/material.dart';

import 'connection_help.dart';

class FriendlyErrorState extends StatefulWidget {
  const FriendlyErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.resourceName = 'library',
    this.dark = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final String resourceName;
  final bool dark;

  @override
  State<FriendlyErrorState> createState() => _FriendlyErrorStateState();
}

class _FriendlyErrorStateState extends State<FriendlyErrorState> {
  Object get error => widget.error;
  VoidCallback get onRetry => widget.onRetry;
  String get resourceName => widget.resourceName;
  bool get dark => widget.dark;

  @override
  void initState() {
    super.initState();
    _offerHelp();
  }

  @override
  void didUpdateWidget(covariant FriendlyErrorState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isConnectionFailure(oldWidget.error)) _offerHelp();
  }

  void _offerHelp() {
    if (!isConnectionFailure(error)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        showConnectionHelp(context, automatic: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _messageFor(error, resourceName);
    final textColor = dark ? Colors.white : const Color(0xFF1B1D24);
    final detailColor = dark ? Colors.white70 : const Color(0xFF737784);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 38),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: dark ? Colors.white12 : const Color(0xFFF0F6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF1477FA),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message.detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: detailColor, height: 1.5),
            ),
            if (isConnectionFailure(error))
              TextButton.icon(
                onPressed: () => showConnectionHelp(context),
                icon: const Icon(Icons.vpn_lock_rounded),
                label: const Text('Connection / VPN help'),
              ),
            const SizedBox(height: 21),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1477FA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 13,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_ErrorMessage _messageFor(Object error, String resourceName) {
  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('connection refused') ||
      text.contains('network')) {
    return _ErrorMessage(
      'Can’t connect right now',
      'Check your internet connection, then try loading your $resourceName again.',
    );
  }
  if (text.contains('timeout')) {
    return _ErrorMessage(
      'This is taking too long',
      'The $resourceName is taking longer than expected. Please try again.',
    );
  }
  if (text.contains('permission') ||
      text.contains('unauthorized') ||
      text.contains('401') ||
      text.contains('403')) {
    return _ErrorMessage(
      'Access needed',
      'Please sign in again to view your $resourceName.',
    );
  }
  return _ErrorMessage(
    'Couldn’t load $resourceName',
    'Something went wrong. Please try again in a moment.',
  );
}

class _ErrorMessage {
  const _ErrorMessage(this.title, this.detail);
  final String title;
  final String detail;
}
