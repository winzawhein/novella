import 'package:flutter/material.dart';

import '../../auth/auth_screen.dart';

import '../../../core/widgets/glass_action_button.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/library_ad.dart';

import '../../library/application/library_providers.dart';
import '../../library/domain/book.dart';
import '../../library/presentation/widgets/book_cover.dart';
import 'reader_screen.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedBookIdsProvider).contains(book.id);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFBFBFD),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // A dedicated footer keeps the ad outside the scrolling content and
        // below the reading button's separate body area (no overlapping taps).
        bottomNavigationBar: const SafeArea(
          top: false,
          child: Padding(padding: EdgeInsets.only(top: 16), child: LibraryAd()),
        ),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _DetailHero(book: book)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(44, 36, 44, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF303238),
                              child: Icon(
                                Icons.person,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 9),
                            Text(
                              book.author,
                              style: const TextStyle(
                                color: Color(0xFFB0B4BF),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 38),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Color(0xFFFFBF20),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              book.rating > 0
                                  ? book.rating.toStringAsFixed(1)
                                  : 'Not rated',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 18),
                            Text(
                              '${book.reviewCount} reviews',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                        const Text(
                          'Introduction',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8D919A),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          book.description?.isNotEmpty == true
                              ? book.description!
                              : 'No description has been added for this book yet.',
                          style: const TextStyle(
                            color: Color(0xFFB0B4BF),
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 43,
              top: 403,
              child: Material(
                color: const Color(0xFFF46563),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () async {
                    if (!await requireAccount(context) || !context.mounted) {
                      return;
                    }
                    ref.read(savedBookIdsProvider.notifier).toggle(book.id);
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isSaved),
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 44,
              right: 44,
              bottom: 25,
              child: GlassActionButton(
                label: 'Start reading',
                icon: Icons.auto_stories_rounded,
                onPressed: () {
                  ref.read(selectedBookProvider.notifier).state = book;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReaderScreen(book: book),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHero extends ConsumerWidget {
  const _DetailHero({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: 430,
    child: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC4160), Color(0xFFB11066), Color(0xFF5312A8)],
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 22,
          child: _HeroAction(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 48,
          right: 22,
          child: PopupMenuButton<String>(
            tooltip: 'Book options',
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (!await requireAccount(context) || !context.mounted) return;
              if (value == 'save') {
                ref.read(savedBookIdsProvider.notifier).toggle(book.id);
              }
              if (value == 'read') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReaderScreen(book: book),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'save',
                child: Text(
                  ref.read(savedBookIdsProvider).contains(book.id)
                      ? 'Remove from saved'
                      : 'Save book',
                ),
              ),
              const PopupMenuItem(value: 'read', child: Text('Read book')),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Hero(
              tag: 'book-cover-${book.id}',
              child: BookCover(book: book, width: 205, framed: false),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white24,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
    ),
  );
}
