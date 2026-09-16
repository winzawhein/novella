import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/novella_loading_indicator.dart';
import '../../../core/widgets/friendly_error_state.dart';
import '../application/reader_providers.dart';
import '../application/reader_content_providers.dart';
import '../../library/domain/book.dart';
import 'pdf_reader_screen.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (book.fileUrl?.toLowerCase().endsWith('.pdf') ?? false) {
      return PdfReaderScreen(book: book);
    }
    final dark = ref.watch(readerDarkModeProvider);
    final fontScale = ref.watch(readerFontScaleProvider);
    final color = dark ? Colors.white : Colors.black;
    final chapter = ref.watch(firstChapterProvider(book.id));
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF171719) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: color),
                  ),
                  Expanded(
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reading settings',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _ReaderControlsSheet(),
                    ),
                    icon: Icon(Icons.text_fields, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Expanded(
                child: chapter.when(
                  loading: () => const NovellaLoadingIndicator(
                    message: 'Opening your book',
                  ),
                  error: (error, _) => FriendlyErrorState(
                    error: error,
                    resourceName: 'book',
                    dark: dark,
                    onRetry: () =>
                        ref.invalidate(firstChapterProvider(book.id)),
                  ),
                  data: (item) {
                    if (item == null)
                      return Center(
                        child: Text(
                          'This book has no chapter content yet.',
                          style: TextStyle(color: color),
                        ),
                      );
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${item.number}',
                            style: TextStyle(
                              color: color.withValues(alpha: .45),
                              fontSize: 15 * fontScale,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: color,
                                  fontSize: 31 * fontScale,
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            item.content,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: color.withValues(alpha: .78),
                                  fontSize: 19 * fontScale,
                                  height: 1.72,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              LinearProgressIndicator(value: ref.watch(readerProgressProvider)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
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
