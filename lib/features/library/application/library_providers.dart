import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_book_repository.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => SupabaseBookRepository(Supabase.instance.client),
);
final libraryProvider = FutureProvider<List<Book>>(
  (ref) => ref.watch(bookRepositoryProvider).fetchLibrary(),
);
final selectedBookProvider = StateProvider<Book?>((ref) => null);
final selectedGenreProvider = StateProvider<String>((ref) => 'Self-Help');
