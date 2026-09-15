import 'book.dart';

abstract interface class BookRepository {
  Future<List<Book>> fetchLibrary();
  Future<void> saveProgress(String bookId, double progress);
}
