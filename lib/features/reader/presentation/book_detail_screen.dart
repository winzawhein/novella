import 'package:flutter/material.dart';

import '../../library/domain/book.dart';
import '../../library/presentation/widgets/book_cover.dart';
import 'reader_screen.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => Scaffold(
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
                        Icon(Icons.star, color: Color(0xFFFFBF20), size: 22),
                        SizedBox(width: 8),
                        Text(
                          book.rating.toStringAsFixed(1),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 18),
                        Text(
                          'Mostly Positive (${book.reviewCount} Reviews)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    const Text(
                      'Introduction',
                      style: TextStyle(fontSize: 16, color: Color(0xFF8D919A)),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      book.description?.isNotEmpty == true ? book.description! : 'No description has been added for this book yet.',
                      style: const TextStyle(color: Color(0xFFB0B4BF), height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          right: 43,
          top: 403,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFF46563),
            child: Icon(Icons.favorite, color: Colors.white, size: 29),
          ),
        ),
        Positioned(
          left: 44,
          right: 44,
          bottom: 25,
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book)),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1477FA),
              minimumSize: const Size.fromHeight(58),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Start reading',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 430,
    child: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
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
        const Positioned(
          top: 48,
          right: 22,
          child: _HeroAction(icon: Icons.more_vert),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: BookCover(book: book, width: 205, framed: false),
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
