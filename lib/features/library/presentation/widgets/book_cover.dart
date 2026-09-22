import 'package:flutter/material.dart';

import '../../domain/book.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 142,
    this.showTitle = true,
    this.framed = true,
  });
  final Book book;
  final double width;
  final bool showTitle;
  final bool framed;
  @override
  Widget build(BuildContext context) {
    final art = book.coverUrl == null
        ? _CoverArt(book: book, width: framed ? width * .68 : width)
        : ClipRRect(
            borderRadius: BorderRadius.circular(framed ? 5 : 10),
            child: Image.network(
              book.coverUrl!,
              width: framed ? width * .68 : width,
              height: (framed ? width * .68 : width) * 1.42,
              fit: BoxFit.cover,
            ),
          );
    return framed
        ? Container(
            width: width,
            height: width * 1.36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                const Positioned(top: 11, right: 11, child: _RatingBadge()),
                Center(child: art),
              ],
            ),
          )
        : art;
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Color(0xFFFFC542), size: 10),
        SizedBox(width: 2),
        Text('4.9', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _CoverArt extends StatelessWidget {
  const _CoverArt({required this.book, required this.width});
  final Book book;
  final double width;
  @override
  Widget build(BuildContext context) {
    final essential = book.id == 'life' || book.id == 'essential';
    return Container(
      width: width,
      height: width * 1.42,
      decoration: BoxDecoration(
        color: essential ? const Color(0xFF0B1133) : const Color(0xFFF3EBD9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          if (essential) ...[
            Positioned(
              left: -width * .1,
              top: width * .28,
              child: _Blob(color: const Color(0xFFFF6A55), size: width * .8),
            ),
            Positioned(
              right: -width * .25,
              bottom: -width * .2,
              child: _Blob(color: const Color(0xFF2638D9), size: width),
            ),
            Positioned(
              right: -width * .15,
              bottom: -width * .2,
              child: _Blob(color: const Color(0xFF61D6DD), size: width * .55),
            ),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                essential ? 'Essential\nThings' : 'Make\nEveryday\nBetter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: essential ? Colors.white : Colors.black,
                  fontSize: width * .15,
                  height: .94,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 9,
            left: 8,
            child: Text(
              essential ? 'Pannacota Fugo' : 'A Better You',
              style: TextStyle(
                color: essential ? Colors.white70 : Colors.black54,
                fontSize: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * .45),
    ),
  );
}
