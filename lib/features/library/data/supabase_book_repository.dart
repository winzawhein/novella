import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/book.dart';
import '../domain/book_repository.dart';

class SupabaseBookRepository implements BookRepository {
  SupabaseBookRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Book>> fetchLibrary() async {
    const fields =
        'id, title, author, description, rating, review_count, cover_path, file_path';
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('books')
          .select('$fields, genre')
          .eq('is_published', true)
          .order('created_at', ascending: false);
    } catch (_) {
      rows = await _client
          .from('books')
          .select(fields)
          .eq('is_published', true)
          .order('created_at', ascending: false);
    }
    return rows.map((row) {
      final coverPath = row['cover_path'] as String?;
      final filePath = row['file_path'] as String?;
      return Book(
        id: row['id'] as String,
        title: row['title'] as String,
        author: row['author'] as String,
        genre: (row['genre'] as String?)?.trim().isNotEmpty == true
            ? (row['genre'] as String).trim()
            : 'Other',
        coverColor: const Color(0xFF0B1133),
        accentColor: const Color(0xFFF1F1F2),
        progress: 0,
        description: row['description'] as String?,
        rating: (row['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
        coverUrl: coverPath == null || coverPath.isEmpty
            ? null
            : _client.storage.from('book-covers').getPublicUrl(coverPath),
        fileUrl: filePath == null || filePath.isEmpty
            ? null
            : _client.storage.from('book-files').getPublicUrl(filePath),
      );
    }).toList();
  }

  @override
  Future<void> saveProgress(String id, double progress) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('reading_progress').upsert({
      'user_id': user.id,
      'book_id': id,
      'progress': progress,
    });
  }
}
