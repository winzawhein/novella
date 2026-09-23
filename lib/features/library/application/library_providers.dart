import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_screen.dart';

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
final selectedGenreProvider = StateProvider<String>((ref) => 'All');
final currentReadingBookIdProvider =
    StateNotifierProvider<CurrentReadingBookController, String?>(
      (ref) => CurrentReadingBookController(),
    );
final readingProgressByBookProvider =
    StateNotifierProvider<ReadingProgressController, Map<String, double>>(
      (ref) => ReadingProgressController(),
    );
final readingPageByBookProvider =
    StateNotifierProvider<ReadingPageController, Map<String, int>>(
      (ref) => ReadingPageController(),
    );
final savedBookIdsProvider =
    StateNotifierProvider<SavedBookIdsController, Set<String>>((ref) {
      ref.watch(authStateProvider);
      return SavedBookIdsController(
        Supabase.instance.client.auth.currentUser?.id,
      );
    });

class SavedBookIdsController extends StateNotifier<Set<String>> {
  SavedBookIdsController(this.userId) : super(<String>{}) {
    _restore();
  }

  final String? userId;
  String get _storageKey => 'saved_book_ids_${userId ?? "guest"}';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = preferences.getStringList(_storageKey)?.toSet() ?? <String>{};
  }

  Future<void> toggle(String bookId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous || user.id != userId) return;
    final next = {...state};
    next.contains(bookId) ? next.remove(bookId) : next.add(bookId);
    await _save(next);
  }

  Future<void> remove(String bookId) async {
    if (userId == null || Supabase.instance.client.auth.currentUser?.id != userId) return;
    final next = {...state}..remove(bookId);
    await _save(next);
  }

  Future<void> _save(Set<String> ids) async {
    state = ids;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, ids.toList());
  }
}

class CurrentReadingBookController extends StateNotifier<String?> {
  CurrentReadingBookController() : super(null) {
    _restore();
  }

  static const _storageKey = 'current_reading_book_id';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getString(_storageKey);
  }

  Future<void> setBook(String bookId) async {
    state = bookId;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, bookId);
  }
}

class ReadingProgressController extends StateNotifier<Map<String, double>> {
  ReadingProgressController() : super(<String, double>{}) {
    _restore();
  }

  static const _storageKey = 'reading_progress_by_book';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const <String>[];
    final values = <String, double>{};
    for (final item in stored) {
      final pieces = item.split('|');
      if (pieces.length != 2) continue;
      final progress = double.tryParse(pieces[1]);
      if (progress != null) values[pieces[0]] = progress;
    }
    state = values;
  }

  Future<void> setProgress(String bookId, double progress) async {
    final next = {...state, bookId: progress.clamp(0, 1).toDouble()};
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      next.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
    );
  }
}

class ReadingPageController extends StateNotifier<Map<String, int>> {
  ReadingPageController() : super(<String, int>{}) {
    _restore();
  }

  static const _storageKey = 'reading_page_by_book';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const <String>[];
    final values = <String, int>{};
    for (final item in stored) {
      final pieces = item.split('|');
      if (pieces.length != 2) continue;
      final page = int.tryParse(pieces[1]);
      if (page != null && page >= 0) values[pieces[0]] = page;
    }
    state = values;
  }

  Future<void> setPage(String bookId, int page) async {
    final next = {...state, bookId: page.clamp(0, 1000000)};
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      next.entries.map((entry) => '${entry.key}|${entry.value}').toList(),
    );
  }
}
