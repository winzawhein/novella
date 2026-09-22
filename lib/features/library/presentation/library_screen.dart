import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../notifications/presentation/notifications_screen.dart';

import '../../../core/widgets/novella_loading_indicator.dart';
import '../../../core/widgets/friendly_error_state.dart';
import '../../reader/presentation/book_detail_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../profile/application/profile_providers.dart';
import '../application/library_providers.dart';
import '../domain/book.dart';
import 'widgets/book_tile.dart';

final _searchQuery = StateProvider.autoDispose<String>((ref) => '');
final _searchFocused = StateProvider.autoDispose<bool>((ref) => false);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    final query = ref.watch(_searchQuery).trim().toLowerCase();
    final profile = ref.watch(readerProfileProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searchFocused = ref.watch(_searchFocused);
    return library.when(
      loading: () => const NovellaLoadingIndicator(),
      error: (error, _) => FriendlyErrorState(
        error: error,
        onRetry: () => ref.invalidate(libraryProvider),
      ),
      data: (books) {
        final genres = <String>{
          'All',
          ...books.map((book) => book.genre),
        }.toList();
        final visibleBooks = books
            .where(
              (book) =>
                  (selectedGenre == 'All' || book.genre == selectedGenre) &&
                  '${book.title} ${book.author} ${book.genre}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
        return Stack(
          children: [
            const Positioned(top: 302, left: 112, child: _BlueGlow()),
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _HomeHeader(
                  profileName: profile.name,
                  photoPath: profile.photoPath,
                  onSearch: (value) =>
                      ref.read(_searchQuery.notifier).state = value,
                ),
                _GenrePicker(genres: genres),
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 25, 28, 16),
                  child: Text(
                    selectedGenre == 'All'
                        ? 'All books'
                        : '$selectedGenre books',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (visibleBooks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'No books found. Try a different title or author.',
                    ),
                  ),
                SizedBox(
                  height: 275,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleBooks.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) => BookTile(
                      book: visibleBooks[index],
                      onTap: () => _openBook(context, ref, visibleBooks[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
            if (!keyboardOpen && query.isEmpty && !searchFocused)
              Positioned(
                right: 24,
                bottom: 90 + MediaQuery.paddingOf(context).bottom,
                child: _ContinueReading(books: books),
              ),
          ],
        );
      },
    );
  }

  void _openBook(BuildContext context, WidgetRef ref, Book book) {
    ref.read(selectedBookProvider.notifier).state = book;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}

class _HomeHeader extends ConsumerStatefulWidget {
  const _HomeHeader({
    required this.profileName,
    this.photoPath,
    required this.onSearch,
  });
  final ValueChanged<String> onSearch;
  final String profileName;
  final String? photoPath;

  @override
  ConsumerState<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<_HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE4E5E8),
                backgroundImage: widget.photoPath == null
                    ? null
                    : FileImage(File(widget.photoPath!)),
                child: widget.photoPath == null
                    ? const Icon(Icons.person, color: Colors.black87)
                    : null,
              ),
              const Spacer(),
              _ScanButton(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 31),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, .18),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: Text(
                'Hello, ${widget.profileName}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Focus(
            onFocusChange: (focused) =>
                ref.read(_searchFocused.notifier).state = focused,
            child: TextField(
              onChanged: widget.onSearch,
              decoration: const InputDecoration(
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
          ),
        ],
      ),
    ),
  );
}

class _GenrePicker extends ConsumerWidget {
  const _GenrePicker({required this.genres});
  final List<String> genres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedGenreProvider);
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
              final active = genre == selected;
              return ChoiceChip(
                label: Text(genre),
                selected: active,
                onSelected: (_) =>
                    ref.read(selectedGenreProvider.notifier).state = genre,
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

class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(
      begin: 1,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
    child: Material(
      color: const Color(0xFFEAF1FF),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1477FA),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    height: 5,
                    width: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1477FA).withValues(alpha: .8),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x661477FA), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ContinueReading extends ConsumerWidget {
  const _ContinueReading({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBook = ref.watch(selectedBookProvider);
    final currentId = ref.watch(currentReadingBookIdProvider);
    final storedBook = _bookWithId(books, currentId);
    final book =
        selectedBook ?? storedBook ?? (books.isEmpty ? null : books.first);
    if (book == null) return const SizedBox.shrink();

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            ref.read(selectedBookProvider.notifier).state = book;
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book)),
            );
          },
          child: Ink(
            height: 50,
            padding: const EdgeInsets.fromLTRB(7, 6, 14, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1477FA),
              borderRadius: BorderRadius.circular(31),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x401477FA),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF1477FA),
                  ),
                ),
                const SizedBox(width: 11),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue reading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 124,
                      child: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Book? _bookWithId(List<Book> books, String? id) {
  if (id == null) return null;
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
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
