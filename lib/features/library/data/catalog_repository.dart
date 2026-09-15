import 'package:flutter/material.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';

class CatalogRepository implements BookRepository {
  @override
  Future<List<Book>> fetchLibrary() async => const [
    Book(
      id: 'life',
      title: 'Life, Love and Other Inequalities',
      author: 'Argentina Ryder',
      genre: 'Fiction',
      coverColor: Color(0xFF08A9A3),
      accentColor: Color(0xFFDCF7F4),
      progress: .32,
    ),
    Book(
      id: 'fast',
      title: 'The Fastest Way to Fall',
      author: 'Denise Williams',
      genre: 'Romance',
      coverColor: Color(0xFFFFC20A),
      accentColor: Color(0xFFFFE7F7),
      progress: 0,
    ),
    Book(
      id: 'mission',
      title: 'The Mission',
      author: 'Jason Hewitt',
      genre: 'Mystery',
      coverColor: Color(0xFFF21B26),
      accentColor: Color(0xFFFFE1E2),
      progress: .64,
    ),
    Book(
      id: 'essential',
      title: 'Essential Things',
      author: 'Enrico Pucci',
      genre: 'Self-help',
      coverColor: Color(0xFFE13D62),
      accentColor: Color(0xFFE7E0FF),
      progress: .38,
    ),
  ];
  @override
  Future<void> saveProgress(String bookId, double progress) async {}
}
