import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/friendly_error_state.dart';
import '../../../core/widgets/novella_loading_indicator.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/book.dart';
import '../application/reader_content_providers.dart';
import '../application/reader_providers.dart';
import '../domain/book_chapter.dart';
import 'pdf_reader_screen.dart';

/// A distraction-free, page-style reader for text chapters.
/// PDFs keep their native page rendering in [PdfReaderScreen].
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pageController;
  Timer? _controlsTimer;
  bool _showPageControls = true;
  int _currentPage = 0;
  int? _lastRestoredPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentReadingBookIdProvider.notifier).setBook(widget.book.id);
      }
    });
    _restartControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartControlsTimer() {
    _controlsTimer?.cancel();
    if (!_showPageControls && mounted) setState(() => _showPageControls = true);
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showPageControls = false);
    });
  }

  void _goToPage(int page, int totalPages) {
    if (page < 0 || page >= totalPages) return;
    _restartControlsTimer();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page, int totalPages) {
    setState(() => _currentPage = page);
    final progress = (page + 1) / totalPages;
    ref.read(readerProgressProvider.notifier).state = progress;
    ref
        .read(readingProgressByBookProvider.notifier)
        .setProgress(widget.book.id, progress);
    ref.read(readingPageByBookProvider.notifier).setPage(widget.book.id, page);
    ref.read(currentReadingBookIdProvider.notifier).setBook(widget.book.id);
    _restartControlsTimer();
  }

  void _toggleSaved() {
    final savedIds = ref.read(savedBookIdsProvider);
    final wasSaved = savedIds.contains(widget.book.id);
    ref.read(savedBookIdsProvider.notifier).toggle(widget.book.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasSaved ? 'Removed from Saved' : 'Saved for later'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.fileUrl?.toLowerCase().endsWith('.pdf') ?? false) {
      return PdfReaderScreen(book: widget.book);
    }

    final dark = ref.watch(readerDarkModeProvider);
    final color = dark ? Colors.white : const Color(0xFF202126);
    final saved = ref.watch(savedBookIdsProvider).contains(widget.book.id);
    final storedPage =
        ref.watch(readingPageByBookProvider)[widget.book.id] ?? 0;
    final chapter = ref.watch(firstChapterProvider(widget.book.id));

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF171719) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ReaderHeader(
              title: widget.book.title,
              color: color,
              saved: saved,
              onBack: () => Navigator.of(context).pop(),
              onSave: _toggleSaved,
              onAppearance: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const _ReaderControlsSheet(),
              ),
            ),
            Expanded(
              child: chapter.when(
                loading: () =>
                    const NovellaLoadingIndicator(message: 'Opening your book'),
                error: (error, _) => FriendlyErrorState(
                  error: error,
                  resourceName: 'book',
                  dark: dark,
                  onRetry: () =>
                      ref.invalidate(firstChapterProvider(widget.book.id)),
                ),
                data: (item) {
                  if (item == null) {
                    return Center(
                      child: Text(
                        'This book has no chapter content yet.',
                        style: TextStyle(color: color),
                      ),
                    );
                  }
                  final pages = _paginate(item.content);
                  _restoreStoredTextPage(storedPage, pages.length);
                  final safePage = math.min(_currentPage, pages.length - 1);
                  return Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _restartControlsTimer,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: pages.length,
                          onPageChanged: (page) =>
                              _onPageChanged(page, pages.length),
                          itemBuilder: (_, page) => _ReadingPage(
                            chapter: item,
                            body: pages[page],
                            isFirstPage: page == 0,
                            dark: dark,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 18,
                        child: SafeArea(
                          top: false,
                          child: AnimatedSlide(
                            offset: _showPageControls
                                ? Offset.zero
                                : const Offset(0, .42),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: AnimatedOpacity(
                              opacity: _showPageControls ? 1 : 0,
                              duration: const Duration(milliseconds: 190),
                              child: _PageNavigation(
                                currentPage: safePage,
                                totalPages: pages.length,
                                onPrevious: () =>
                                    _goToPage(safePage - 1, pages.length),
                                onNext: () =>
                                    _goToPage(safePage + 1, pages.length),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreStoredTextPage(int storedPage, int totalPages) {
    final target = storedPage.clamp(0, totalPages - 1).toInt();
    if (_lastRestoredPage == target || target == _currentPage) return;
    _lastRestoredPage = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(target);
      setState(() => _currentPage = target);
    });
  }
}

List<String> _paginate(String content) {
  final source = content.trim();
  if (source.isEmpty) return const ['No text was provided for this chapter.'];
  const targetLength = 720;
  if (source.length <= targetLength) return [source];

  final pages = <String>[];
  var start = 0;
  while (start < source.length) {
    var end = math.min(start + targetLength, source.length);
    if (end < source.length) {
      final paragraphBreak = source.lastIndexOf('\n', end);
      final wordBreak = source.lastIndexOf(' ', end);
      final preferredBreak = math.max(paragraphBreak, wordBreak);
      if (preferredBreak > start + targetLength ~/ 2) end = preferredBreak;
    }
    pages.add(source.substring(start, end).trim());
    start = end;
    while (start < source.length && RegExp(r'\s').hasMatch(source[start])) {
      start++;
    }
  }
  return pages.where((page) => page.isNotEmpty).toList();
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.title,
    required this.color,
    required this.saved,
    required this.onBack,
    required this.onSave,
    required this.onAppearance,
  });

  final String title;
  final Color color;
  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onAppearance;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_rounded, color: color),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: saved ? 'Remove from Saved' : 'Save book',
          onPressed: onSave,
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: color,
          ),
        ),
        IconButton(
          tooltip: 'Reading appearance',
          onPressed: onAppearance,
          icon: Icon(Icons.text_fields_rounded, color: color),
        ),
      ],
    ),
  );
}

class _ReadingPage extends ConsumerWidget {
  const _ReadingPage({
    required this.chapter,
    required this.body,
    required this.isFirstPage,
    required this.dark,
  });

  final BookChapter chapter;
  final String body;
  final bool isFirstPage;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readerFontScaleProvider);
    final color = dark ? Colors.white : const Color(0xFF202126);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Text(
              'Chapter ${chapter.number}',
              style: TextStyle(
                color: color.withValues(alpha: .45),
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              chapter.title,
              style: TextStyle(
                color: color,
                fontSize: 31 * scale,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            body,
            style: TextStyle(
              color: color.withValues(alpha: .88),
              fontSize: 19 * scale,
              height: 1.76,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageNavigation extends StatelessWidget {
  const _PageNavigation({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _PageButton(
        icon: Icons.arrow_back_rounded,
        enabled: currentPage > 0,
        onPressed: onPrevious,
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xEEFFFFFF),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          '${currentPage + 1} of $totalPages',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      _PageButton(
        icon: Icons.arrow_forward_rounded,
        enabled: currentPage < totalPages - 1,
        onPressed: onNext,
      ),
    ],
  );
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 180),
    opacity: enabled ? 1 : 0,
    child: IgnorePointer(
      ignoring: !enabled,
      child: Material(
        color: const Color(0xFF22BBC8),
        shape: const CircleBorder(),
        elevation: 5,
        shadowColor: const Color(0x5522BBC8),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 62,
            height: 62,
            child: Icon(icon, color: Colors.white, size: 31),
          ),
        ),
      ),
    ),
  );
}

class _ReaderControlsSheet extends ConsumerWidget {
  const _ReaderControlsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readerFontScaleProvider);
    final dark = ref.watch(readerDarkModeProvider);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF252529) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? Colors.white24 : const Color(0xFFDDE0E7),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  'Reading appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : const Color(0xFF17181D),
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () =>
                      ref.read(readerDarkModeProvider.notifier).state = !dark,
                  icon: Icon(
                    dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? Colors.white12 : const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Smaller text',
                    onPressed: scale <= .8
                        ? null
                        : () =>
                              ref.read(readerFontScaleProvider.notifier).state =
                                  (scale - .1).clamp(.8, 1.4),
                    icon: const Text(
                      'A−',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: scale,
                      min: .8,
                      max: 1.4,
                      divisions: 6,
                      label: '${(scale * 100).round()}%',
                      onChanged: (value) =>
                          ref.read(readerFontScaleProvider.notifier).state =
                              value,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Larger text',
                    onPressed: scale >= 1.4
                        ? null
                        : () =>
                              ref.read(readerFontScaleProvider.notifier).state =
                                  (scale + .1).clamp(.8, 1.4),
                    icon: const Text(
                      'A+',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Preview text size',
              style: TextStyle(
                fontSize: 16 * scale,
                color: dark ? Colors.white70 : const Color(0xFF565A65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
