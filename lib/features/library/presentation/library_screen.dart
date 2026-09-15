import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reader/presentation/book_detail_screen.dart';
import '../application/library_providers.dart';
import '../domain/book.dart';
import 'widgets/book_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Unable to load library')),
      data: (books) => Stack(
        children: [
          const Positioned(top: 302, left: 112, child: _BlueGlow()),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _HomeHeader(onScan: () {}),
              _GenrePicker(),
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 25, 28, 16),
                child: Text(
                  '“Self-Help” Genre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 275,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  scrollDirection: Axis.horizontal,
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => BookTile(
                    book: books[index],
                    onTap: () => _openBook(context, ref, books[index]),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 10, 28, 180),
                child: Text(
                  'Trending now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9D9DA2),
                  ),
                ),
              ),
            ],
          ),
          if (!keyboardOpen)
            const Positioned(right: 24, bottom: 118, child: _ContinueReading()),
        ],
      ),
    );
  }

  void _openBook(BuildContext context, WidgetRef ref, Book book) {
    ref.read(selectedBookProvider.notifier).state = book;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onScan});
  final VoidCallback onScan;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE4E5E8),
                child: Icon(Icons.person, color: Colors.black87),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onScan,
                icon: const Icon(Icons.document_scanner_outlined),
              ),
            ],
          ),
          const SizedBox(height: 31),
          const Text(
            'Hello, Timmy!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search books',
              filled: true,
              fillColor: Color(0xFFF4F4F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GenrePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedGenreProvider);
    const genres = [
      ('▣', 'Novel'),
      ('⚡', 'Self-Help'),
      ('🔮', 'Fantasy'),
      ('🖊', 'True Crime'),
      ('♟', 'Science Fiction Fantasy'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Genre',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              final active = genre.$2 == selected;
              return ChoiceChip(
                label: Text('${genre.$1}  ${genre.$2}'),
                selected: active,
                onSelected: (_) =>
                    ref.read(selectedGenreProvider.notifier).state = genre.$2,
                selectedColor: const Color(0xFF1477FA),
                backgroundColor: const Color(0xFFF5F5F6),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: active ? Colors.white : const Color(0xFF4E5059),
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading();
  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: Colors.transparent,
      child: Container(
        height: 59,
        padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1477FA),
          borderRadius: BorderRadius.circular(31),
          boxShadow: const [
            BoxShadow(
              color: Color(0x401477FA),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.play_arrow_rounded, color: Color(0xFF1477FA)),
            ),
            SizedBox(width: 11),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue reading',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Upside Down Chap. 4',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BlueGlow extends StatelessWidget {
  const _BlueGlow();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 160,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x553B9BFF), Color(0x003B9BFF)],
        ),
      ),
    ),
  );
}
