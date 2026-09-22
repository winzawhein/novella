import 'package:flutter/material.dart';

import '../../domain/book.dart';
import 'book_cover.dart';

class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 142,
    height: 252,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'book-cover-${book.id}',
            child: BookCover(book: book),
          ),
          const SizedBox(height: 9),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
