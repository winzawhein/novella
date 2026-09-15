import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/presentation/library_screen.dart';
import '../application/navigation_provider.dart';
import 'widgets/floating_navigation.dart';
import 'tab_placeholder_screen.dart';

class LibraryShell extends ConsumerWidget {
  const LibraryShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: Stack(
        children: [
          _tabFor(index),
          if (!keyboardOpen)
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigation(
              index: index,
              onSelected: (value) =>
                  ref.read(navigationIndexProvider.notifier).state = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabFor(int index) => switch (index) {
    0 => const LibraryScreen(),
    1 => const TabPlaceholderScreen(
      title: 'My library',
      icon: Icons.auto_stories_rounded,
      message: 'Your reading collection will appear here.',
    ),
    2 => const TabPlaceholderScreen(
      title: 'Saved',
      icon: Icons.bookmark_border_rounded,
      message: 'Books and highlights you save will live here.',
    ),
    _ => const TabPlaceholderScreen(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      message: 'Your reading activity and settings are here.',
    ),
  };
}
