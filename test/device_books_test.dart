import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:novella/features/library/data/device_books.dart';

void main() {
  late Directory folder;
  late Database db;
  late DeviceBooks store;
  setUp(() async {
    sqfliteFfiInit();
    folder = await Directory.systemTemp.createTemp('novella-import-test-');
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE books (id TEXT PRIMARY KEY, owner TEXT NOT NULL, title TEXT NOT NULL, path TEXT NOT NULL, bytes INTEGER NOT NULL)',
    );
    store = DeviceBooks(
      'reader-a',
      database: Future.value(db),
      importDirectory: folder,
    );
  });
  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });
  Stream<List<int>> pdf() => Stream.value('%PDF-1.4\nfixture'.codeUnits);
  test(
    'imports metadata and file, restores list and isolates accounts',
    () async {
      await store.importStream('My book.PDF', pdf());
      final books = await store.list();
      expect(books.single.title, 'My book');
      expect(await File(books.single.localPath!).exists(), isTrue);
      final reopened = DeviceBooks(
        'reader-a',
        database: Future.value(db),
        importDirectory: folder,
      );
      expect((await reopened.list()).single.id, books.single.id);
      final other = DeviceBooks(
        'reader-b',
        database: Future.value(db),
        importDirectory: folder,
      );
      expect(await other.list(), isEmpty);
      await other.remove(books.single);
      expect(await store.list(), hasLength(1));
    },
  );
  test('rejects sixth book and cleans rejected copy', () async {
    for (var i = 0; i < 5; i++) {
      await store.importStream('$i.pdf', pdf());
    }
    await expectLater(store.importStream('six.pdf', pdf()), throwsStateError);
    expect(await store.list(), hasLength(5));
    expect(await folder.list().length, 5);
    await store.remove((await store.list()).first);
    await store.importStream('replacement.pdf', pdf());
    expect(await store.list(), hasLength(5));
  });
  test('rejects non-PDF and rolls back interrupted copy', () async {
    await expectLater(
      store.importStream('fake.pdf', Stream.value('not a pdf'.codeUnits)),
      throwsStateError,
    );
    await expectLater(
      store.importStream(
        'broken.pdf',
        Stream.error(const FileSystemException('read failed')),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.list(), isEmpty);
    expect(await folder.list().length, 0);
  });
  test('rejects oversized files without retaining a row or copy', () async {
    final chunk = Uint8List(1024 * 1024);
    final content = Stream<List<int>>.fromIterable(List.filled(101, chunk));
    await expectLater(
      store.importStream('large.pdf', content),
      throwsStateError,
    );
    expect(await store.list(), isEmpty);
    expect(await folder.list().length, 0);
  });
  test('removing imported copy preserves the original file', () async {
    final source = File('${folder.path}/original.pdf');
    await source.writeAsString('%PDF-1.4\noriginal');
    await store.importStream('original.pdf', source.openRead());
    final book = (await store.list()).single;
    await store.remove(book);
    expect(await source.exists(), isTrue);
    expect(await File(book.localPath!).exists(), isFalse);
    expect(await store.list(), isEmpty);
  });
}
