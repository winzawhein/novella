import 'package:flutter/material.dart';

class TabPlaceholderScreen extends StatelessWidget {
  const TabPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });
  final String title;
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 54),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFF1F4FA),
                  child: Icon(icon, size: 46, color: const Color(0xFF1477FA)),
                ),
                const SizedBox(height: 22),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
