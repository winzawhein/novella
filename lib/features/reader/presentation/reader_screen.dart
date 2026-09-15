import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/novella_loading_indicator.dart';
import '../application/reader_providers.dart';
import '../application/reader_content_providers.dart';
import '../../library/domain/book.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(readerDarkModeProvider);
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
                    onPressed: () =>
                        ref.read(readerDarkModeProvider.notifier).state = !dark,
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
                  error: (_, __) => Center(
                    child: Text(
                      'Unable to load this book.',
                      style: TextStyle(color: color),
                    ),
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
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(color: color),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            item.content,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: color.withValues(alpha: .78)),
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
