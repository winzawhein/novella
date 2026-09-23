import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/book.dart';

class DeviceBooks {
  DeviceBooks(this.owner, {Future<Database>? database, this.importDirectory})
    : _overrideDatabase = database;
  final String owner;
  final Future<Database>? _overrideDatabase;
  final Directory? importDirectory;
  static const limit = 5;
  static const maxBytes = 100 * 1024 * 1024;
  static Future<Database>? _database;
  Future<Database> get database => _overrideDatabase ?? (_database ??= _open());
  static Future<Database> _open() async => openDatabase(
    '${await getDatabasesPath()}/device_books.db',
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE books (id TEXT PRIMARY KEY, owner TEXT NOT NULL, title TEXT NOT NULL, path TEXT NOT NULL, bytes INTEGER NOT NULL)',
    ),
  );
  Future<List<Book>> list() async {
    final rows = await (await database).query(
      'books',
      where: 'owner = ?',
      whereArgs: [owner],
      orderBy: 'id DESC',
    );
    return rows
        .map(
          (row) => Book(
            id: row['id'] as String,
            title: row['title'] as String,
            author: 'On this device',
            genre: 'Imported PDF',
            coverColor: const Color(0xFFE3EEFF),
            accentColor: const Color(0xFF1477FA),
            progress: 0,
            localPath: row['path'] as String,
          ),
        )
        .toList();
  }

  Future<void> importPdf() async {
    if ((await list()).length >= limit) {
      throw StateError(
        'Your five slots are full. Remove an imported book first.',
      );
    }
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null) return;
    await importStream(picked.name, picked.readAsByteStream());
  }

  Future<void> importStream(String name, Stream<List<int>> content) async {
    final folder =
        await (importDirectory ??
                Directory(
                  '${(await getApplicationDocumentsDirectory()).path}/imports',
                ))
            .create(recursive: true);
    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final target = File('${folder.path}/$id.pdf');
    var committed = false;
    try {
      final sink = target.openWrite();
      var bytes = 0;
      try {
        await for (final chunk in content) {
          bytes += chunk.length;
          if (bytes > maxBytes) {
            throw StateError('Choose a PDF smaller than 100 MB.');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final handle = await target.open();
      late List<int> header;
      try {
        header = await handle.read(5);
      } finally {
        await handle.close();
      }
      if (String.fromCharCodes(header) != '%PDF-') {
        throw StateError('This file is not a valid PDF.');
      }
      await (await database).transaction((txn) async {
        final count =
            Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM books WHERE owner = ?', [
                owner,
              ]),
            ) ??
            0;
        if (count >= limit) throw StateError('Your five slots are full.');
        await txn.insert('books', {
          'id': id,
          'owner': owner,
          'title': name.replaceFirst(
            RegExp(r'\.pdf$', caseSensitive: false),
            '',
          ),
          'path': target.path,
          'bytes': bytes,
        });
      });
      committed = true;
    } finally {
      if (!committed && await target.exists()) await target.delete();
    }
  }

  Future<void> remove(Book book) async {
    // Only remove an app-owned copy resolved from this account's database row.
    final db = await database;
    final rows = await db.query(
      'books',
      where: 'id = ? AND owner = ?',
      whereArgs: [book.id, owner],
    );
    if (rows.isEmpty) return;
    final file = File(rows.single['path'] as String);
    if (await file.exists()) await file.delete();
    await db.delete(
      'books',
      where: 'id = ? AND owner = ?',
      whereArgs: [book.id, owner],
    );
  }
}
