import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_screen.dart';

import '../../../core/widgets/app_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/novella_loading_indicator.dart';
import '../../../core/widgets/friendly_error_state.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/book.dart';
import '../../library/presentation/device_library_screen.dart';
import '../../library/presentation/widgets/book_cover.dart';
import '../../reader/presentation/book_detail_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../profile/application/profile_providers.dart';

const _ink = Color(0xFF16171D);
const _muted = Color(0xFF7C7E89);
const _blue = Color(0xFF1477FA);
const _canvas = Color(0xFFFBFBFD);

class MyLibraryScreen extends ConsumerWidget {
  const MyLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final books = library.maybeWhen(
      data: (items) => items,
      orElse: () => const <Book>[],
    );
    final currentId = ref.watch(currentReadingBookIdProvider);
    final current =
        ref.watch(selectedBookProvider) ?? _bookWithId(books, currentId);
    final progressByBook = ref.watch(readingProgressByBookProvider);
    final progress = current == null ? 0.0 : progressByBook[current.id] ?? 0.0;
    return _Frame(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: const _ImportPdfCard(),
          ),
          Expanded(
            child: library.when(
              loading: () => const _Loading(),
              error: (error, _) => FriendlyErrorState(
                error: error,
                onRetry: () => ref.invalidate(libraryProvider),
              ),
              data: (books) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      eyebrow: 'YOUR SPACE',
                      title: 'My library',
                      trailing: _RoundButton(icon: Icons.tune_rounded),
                    ),
                  ),
                  if (current != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                        child: _ContinueCard(book: current, progress: progress),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'Your collection',
                      detail: '${books.length} books',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 132),
                    sliver: SliverList.separated(
                      itemCount: books.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _BookCard(
                        book: books[index],
                        progress: progressByBook[books[index].id],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportPdfCard extends StatelessWidget {
  const _ImportPdfCard();

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Import PDF. Open your device bookshelf',
    child: Material(
      color: const Color(0xFF126DE0),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF154D99), Color(0xFF008CFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x55FFFFFF)),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DeviceLibraryScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your private bookshelf · Up to 5 books',
                        style: TextStyle(
                          color: Color(0xDDFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedBookIdsProvider);
    final library = ref.watch(libraryProvider);
    return _Frame(
      child: library.when(
        loading: () => const _Loading(),
        error: (error, _) => FriendlyErrorState(
          error: error,
          onRetry: () => ref.invalidate(libraryProvider),
        ),
        data: (books) {
          final saved = books
              .where((book) => savedIds.contains(book.id))
              .toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  eyebrow: 'KEEP FOR LATER',
                  title: 'Saved',
                  trailing: _SavedCount(count: saved.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: _SavedSummary(count: saved.length),
                ),
              ),
              if (saved.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SavedEmpty(),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: _SectionTitle(title: 'Reading list', detail: 'Books'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 132),
                  sliver: SliverList.separated(
                    itemCount: saved.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _BookCard(book: saved[index], saved: true),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref
        .watch(libraryProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Book>[]);
    final saved = ref.watch(savedBookIdsProvider).length;
    final currentId = ref.watch(currentReadingBookIdProvider);
    final current =
        ref.watch(selectedBookProvider) ?? _bookWithId(books, currentId);
    final progressByBook = ref.watch(readingProgressByBookProvider);
    final progress = current == null ? 0.0 : progressByBook[current.id] ?? 0.0;
    final profile = ref.watch(readerProfileProvider);
    final signedIn = ref.watch(signedInProvider);
    if (!signedIn) {
      return _Frame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 132),
          children: [
            const Text(
              'Welcome to Novella',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 56,
                      color: _blue,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your next chapter starts here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Browse books as a guest. Create an account or sign in to read and save your favourites.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => requireAccount(context),
                      child: const Text('Create account / Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _Frame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 132),
        children: [
          _Entrance(
            child: _Header(
              eyebrow: signedIn ? 'YOUR ACCOUNT' : 'GUEST PROFILE',
              title: 'Profile',
              trailing: _RoundButton(
                icon: Icons.more_horiz_rounded,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _ProfileSettingsSheet(),
                ),
              ),
            ),
          ),
          _Entrance(
            delay: const Duration(milliseconds: 70),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _ProfileHero(
                  books: books.length,
                  saved: saved,
                  progress: current == null ? 0 : progress,
                  name: profile.name,
                  photoPath: profile.photoPath,
                  account:
                      Supabase.instance.client.auth.currentUser?.email ??
                      Supabase.instance.client.auth.currentUser?.phone ??
                      'Signed in',
                ),
              ],
            ),
          ),
          _Entrance(
            delay: const Duration(milliseconds: 140),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const _SectionTitle(
                  title: 'Reading activity',
                  detail: 'This month',
                ),
                const SizedBox(height: 14),
                _ActivityCard(book: current, progress: progress),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _Entrance(
            delay: const Duration(milliseconds: 210),
            child: const Column(
              children: [
                _SectionTitle(title: 'Preferences', detail: ''),
                SizedBox(height: 10),
                _Preferences(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: _canvas),
    child: SafeArea(child: child),
  );
}

class _Entrance extends StatefulWidget {
  const _Entrance({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, .07), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
      child: widget.child,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.eyebrow,
    required this.title,
    required this.trailing,
  });
  final String eyebrow;
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 36,
                  height: .95,
                  letterSpacing: -1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(width: 48, height: 48, child: Icon(icon, color: _ink)),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.book, required this.progress});
  final Book book;
  final double progress;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF173D80),
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(book: book))),
      child: Ink(
        height: 178 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF173D80), Color(0xFF2368CF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x351477FA),
              blurRadius: 25,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BookCover(book: book, width: 76, framed: false),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTINUE READING',
                    style: TextStyle(
                      color: Color(0xFFDCEBFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1.05,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFF9DDEFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 38,
            ),
          ],
        ),
      ),
    ),
  );
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book, this.saved = false, this.progress});
  final Book book;
  final bool saved;
  final double? progress;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: () => _openDetail(context, book),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: BookCover(book: book, width: 62),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (saved)
              IconButton(
                tooltip: 'Remove from saved',
                onPressed: () {
                  ref.read(savedBookIdsProvider.notifier).remove(book.id);
                },
                icon: const Icon(Icons.bookmark_rounded, color: _blue),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB4B6BE)),
          ],
        ),
      ),
    ),
  );
}

class _SavedCount extends StatelessWidget {
  const _SavedCount({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
    child: Text(
      '$count',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
}

class _SavedSummary extends StatelessWidget {
  const _SavedSummary({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6FF),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundColor: Colors.white,
          child: Icon(Icons.bookmark_added_rounded, color: _blue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            count == 0
                ? 'Start a thoughtful reading list.'
                : '$count ${count == 1 ? 'book is' : 'books are'} waiting for you.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(38, 30, 38, 150),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFE9F3FF), Color(0xFFF8FBFF)],
              ),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 54,
              color: _blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nothing saved yet',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Use the heart on a book to build a reading list you will love.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.55),
          ),
        ],
      ),
    ),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.books,
    required this.saved,
    required this.progress,
    required this.name,
    required this.photoPath,
    required this.account,
  });
  final int books;
  final int saved;
  final double progress;
  final String name;
  final String? photoPath;
  final String account;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF161D37), Color(0xFF273C85)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24111C4D),
          blurRadius: 26,
          offset: Offset(0, 13),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: Color(0xFFE0EAFE),
              backgroundImage: photoPath == null
                  ? null
                  : FileImage(File(photoPath!)),
              child: photoPath == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: Color(0xFF1E5BC9),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    account,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB8C8F0)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.account_circle_outlined, color: Color(0xFF8DB9FF)),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            _DarkStat(value: '$books', label: 'Books'),
            _DarkStat(value: '$saved', label: 'Saved'),
            _DarkStat(value: '${(progress * 100).round()}%', label: 'Progress'),
          ],
        ),
      ],
    ),
  );
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB8C8F0), fontSize: 12),
        ),
      ],
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.book, required this.progress});
  final Book? book;
  final double progress;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_stories_rounded, color: _blue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book == null ? 'Pick a book to begin' : 'Currently reading',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book?.title ?? 'Your progress will appear here.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (book != null)
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w800),
          ),
      ],
    ),
  );
}

class _Preferences extends StatelessWidget {
  const _Preferences();
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: const Column(
      children: [
        _Preference(
          icon: Icons.format_size_rounded,
          title: 'Reading appearance',
          subtitle: 'App text size',
        ),
        Divider(height: 1, indent: 72),
        _Preference(
          icon: Icons.notifications_none_rounded,
          title: 'Reading reminders',
          subtitle: 'Off',
        ),
        Divider(height: 1, indent: 72),
        _Preference(
          icon: Icons.help_outline_rounded,
          title: 'Help and feedback',
          subtitle: 'We are here to help',
        ),
      ],
    ),
  );
}

class _Preference extends StatelessWidget {
  const _Preference({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    onTap: () {
      if (icon == Icons.format_size_rounded) {
        showAppAppearance(context);
      } else if (icon == Icons.notifications_none_rounded) {
        showAppNotice(
          context,
          'Reading reminders',
          'Scheduled phone reminders are not available in this version. No reminder is currently scheduled.',
        );
      } else {
        showAppNotice(
          context,
          'Reading help',
          'Save a book with the bookmark button. Continue reading resumes your last page. Use A− / A+ for PDF zoom, or Text size for app text. If a book fails to load, check your connection and try again.',
        );
      }
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFF0F6FF),
      child: Icon(icon, color: _blue),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
    ),
    subtitle: Text(subtitle, style: const TextStyle(color: _muted)),
    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.detail});
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (detail.isNotEmpty)
          Text(detail, style: const TextStyle(color: _muted, fontSize: 13)),
      ],
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const NovellaLoadingIndicator(message: 'Curating your library');
}

void _openDetail(BuildContext context, Book book) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => BookDetailScreen(book: book)));

Book? _bookWithId(List<Book> books, String? id) {
  if (id == null) return null;
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
}

class _ProfileSettingsSheet extends ConsumerStatefulWidget {
  const _ProfileSettingsSheet();

  @override
  ConsumerState<_ProfileSettingsSheet> createState() =>
      _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends ConsumerState<_ProfileSettingsSheet> {
  late final TextEditingController _nameController;
  bool _choosingPhoto = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(readerProfileProvider).name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    setState(() => _choosingPhoto = true);
    try {
      await ref.read(readerProfileProvider.notifier).choosePhoto();
    } finally {
      if (mounted) setState(() => _choosingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(readerProfileProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit profile',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _choosingPhoto ? null : _choosePhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: const Color(0xFFE0EAFE),
                        backgroundImage: profile.photoPath == null
                            ? null
                            : FileImage(File(profile.photoPath!)),
                        child: profile.photoPath == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: _blue,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: _blue,
                          child: _choosingPhoto
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _choosingPhoto ? null : _choosePhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose profile photo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await ref
                                .read(readerProfileProvider.notifier)
                                .updateName(_nameController.text);
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not save your name. Check your connection and try again.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _blue,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  onPressed: _saving
                      ? null
                      : () async {
                          try {
                            await Supabase.instance.client.auth.signOut(
                              scope: SignOutScope.local,
                            );
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not sign out. Try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
