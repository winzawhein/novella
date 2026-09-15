import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/presentation/library_screen.dart';
import '../application/navigation_provider.dart';
import 'reader_collection_screens.dart';
import 'widgets/floating_navigation.dart';

class LibraryShell extends ConsumerWidget {
  const LibraryShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.035, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(index), child: _tabFor(index)),
          ),
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
    1 => const MyLibraryScreen(),
    2 => const SavedScreen(),
    _ => const ProfileScreen(),
  };
}
