import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import '../application/library_providers.dart';
import '../data/device_books.dart';
import '../domain/book.dart';
import '../../../core/widgets/library_ad.dart';

class DeviceLibraryScreen extends StatelessWidget {
  const DeviceLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const AccountGate(child: _DeviceLibrary());
}

class _DeviceLibrary extends ConsumerStatefulWidget {
  const _DeviceLibrary();
  @override
  ConsumerState<_DeviceLibrary> createState() => _DeviceLibraryState();
}

class _DeviceLibraryState extends ConsumerState<_DeviceLibrary> {
  late final store = DeviceBooks(Supabase.instance.client.auth.currentUser!.id);
  late Future<List<Book>> books = store.list();
  bool busy = false;
  Future<void> refresh() async {
    final next = store.list();
    setState(() => books = next);
    await next;
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError ? error.message.toString() : 'Could not update your PDFs. Check storage space and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(readingProgressByBookProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('On this device')),
      bottomNavigationBar: const SafeArea(child: LibraryAd()),
      body: FutureBuilder<List<Book>>(
        future: books,
        builder: (context, snapshot) {
          final items = snapshot.data ?? <Book>[];
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF154D99), Color(0xFF008CFF)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.file_open_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your private bookshelf',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${items.length} / ${DeviceBooks.limit} books • PDF up to 100 MB',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Stored only on this phone, not uploaded. Uninstalling the app removes these copies.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed:
                            busy ||
                                !snapshot.hasData ||
                                items.length >= DeviceBooks.limit
                            ? null
                            : () => run(store.importPdf),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(busy ? 'Importing…' : 'Import PDF'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (snapshot.hasError)
                  TextButton(
                    onPressed: refresh,
                    child: const Text('Could not load local books. Retry'),
                  )
                else if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Bring a PDF from your Files app to start reading.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final book in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFF1477FA),
                        ),
                        title: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${((progress[book.id] ?? 0) * 100).round()}% read • Local PDF',
                        ),
                        onTap: busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReaderScreen(book: book),
                                ),
                              ),
                        trailing: IconButton(
                          tooltip: 'Remove local copy',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Remove imported book?',
                                      ),
                                      content: const Text(
                                        'Only the app’s copy is removed. Your original PDF stays in your device storage.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && mounted) {
                                    await run(() => store.remove(book));
                                  }
                                },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
