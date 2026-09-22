import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/widgets/friendly_error_state.dart';
import '../../../core/widgets/novella_loading_indicator.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/book.dart';
import 'curl_pdf_view.dart';

/// An immersive PDF reader styled after the compact Apple Books controls.
class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late Future<File> _pdfFile = _downloadPdf();
  PDFViewController? _controller;
  final _curlKey = GlobalKey<CurlPdfViewState>();
  Timer? _controlsTimer;
  String? _viewerError;
  bool _ready = false;
  bool _showChrome = true;
  int _page = 0;
  int _pages = 0;
  int? _lastRestoredPage;
  int? _scrubPage;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentReadingBookIdProvider.notifier).setBook(widget.book.id);
      }
    });
    _revealChrome();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    super.dispose();
  }

  void _revealChrome() {
    _controlsTimer?.cancel();
    if (!_showChrome && mounted) setState(() => _showChrome = true);
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showChrome = false);
    });
  }

  Future<File> _downloadPdf() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${directory.path}/pdf-cache');
    if (!await cacheDirectory.exists()) await cacheDirectory.create();
    final file = File('${cacheDirectory.path}/novella-${widget.book.id}.pdf');
    if (await file.exists() && await file.length() > 0) return file;

    final response = await http.get(Uri.parse(widget.book.fileUrl!));
    if (response.statusCode != 200) {
      throw HttpException(
        'PDF download failed with status ${response.statusCode}.',
      );
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  void _retry() {
    setState(() {
      _viewerError = null;
      _ready = false;
      _pdfFile = _downloadPdf();
    });
  }

  Future<void> _goToPage(int page) async {
    if (page < 0 || page >= _pages) return;
    _revealChrome();
    if (Platform.isAndroid) {
      await _curlKey.currentState?.goToPage(page);
      return;
    }
    await _controller?.setPage(page);
  }

  Future<void> _changeZoom(double amount) async {
    if (Platform.isAndroid) {
      setState(() => _zoom = (_zoom + amount).clamp(1.0, 4.0));
      _curlKey.currentState?.setZoom(_zoom);
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    final nextZoom = (_zoom + amount).clamp(1.0, 4.0).toDouble();
    final applied = await controller.setScale(nextZoom);
    if (mounted && applied) setState(() => _zoom = nextZoom);
  }

  Future<void> _resetZoom() async {
    if (Platform.isAndroid) {
      setState(() => _zoom = 1);
      _curlKey.currentState?.setZoom(1);
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    final applied = await controller.setScale(1);
    if (mounted && applied) setState(() => _zoom = 1);
  }

  void _toggleSaved() {
    final saved = ref.read(savedBookIdsProvider).contains(widget.book.id);
    ref.read(savedBookIdsProvider.notifier).toggle(widget.book.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Removed from Saved' : 'Saved for later'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restoreStoredPdfPage() {
    if (_pages == 0 || _controller == null) return;
    final storedPage = ref.read(readingPageByBookProvider)[widget.book.id] ?? 0;
    final target = storedPage.clamp(0, _pages - 1).toInt();
    if (target == 0 || _lastRestoredPage == target || target == _page) return;
    _lastRestoredPage = target;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final applied = await _controller?.setPage(target);
      if (mounted && applied == true) setState(() => _page = target);
    });
  }

  void _recordPage(int page) {
    setState(() {
      _page = page;
      _scrubPage = null;
    });
    final progress = _pages == 0 ? 0.0 : (page + 1) / _pages;
    ref
        .read(readingProgressByBookProvider.notifier)
        .setProgress(widget.book.id, progress);
    ref.read(readingPageByBookProvider.notifier).setPage(widget.book.id, page);
    ref.read(currentReadingBookIdProvider.notifier).setBook(widget.book.id);
    _revealChrome();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedBookIdsProvider).contains(widget.book.id);
    final displayPage = _scrubPage ?? _page;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FutureBuilder<File>(
            future: _pdfFile,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return FriendlyErrorState(
                  error: snapshot.error!,
                  resourceName: 'PDF',
                  onRetry: _retry,
                );
              }
              if (!snapshot.hasData) {
                return const NovellaLoadingIndicator(
                  message: 'Preparing your PDF',
                );
              }
              if (_viewerError != null) {
                return FriendlyErrorState(
                  error: _viewerError!,
                  resourceName: 'PDF',
                  onRetry: _retry,
                );
              }

              return Stack(
                children: [
                  if (Platform.isAndroid)
                    Positioned.fill(
                      top: 76,
                      bottom: 90,
                      child: CurlPdfView(
                        key: _curlKey,
                        path: snapshot.data!.path,
                        bookId: widget.book.id,
                        onTouch: _revealChrome,
                        onError: (error) {
                          if (mounted) {
                            setState(() => _viewerError = error.toString());
                          }
                        },
                        onPage: (page, count) {
                          if (!mounted) return;
                          _pages = count;
                          _ready = true;
                          _recordPage(page);
                        },
                      ),
                    )
                  else
                    PDFView(
                      filePath: snapshot.data!.path,
                      swipeHorizontal: true,
                      onViewCreated: (controller) {
                        _controller = controller;
                        _restoreStoredPdfPage();
                      },
                      onRender: (pages) {
                        setState(() {
                          _pages = pages ?? 0;
                          _ready = true;
                        });
                        _restoreStoredPdfPage();
                      },
                      onPageChanged: (page, _) => _recordPage(page ?? 0),
                    ),
                  _AppleChrome(
                    imageForPage: (page) =>
                        _curlKey.currentState?.imageForPage(page),
                    visible: _showChrome,
                    saved: saved,
                    page: displayPage,
                    totalPages: _pages,
                    zoom: _zoom,
                    onBack: () => Navigator.of(context).pop(),
                    onContents: _showContents,
                    onSave: _toggleSaved,
                    onSmaller: _zoom <= 1 ? null : () => _changeZoom(-.25),
                    onReset: _zoom == 1 ? null : _resetZoom,
                    onLarger: _zoom >= 4 ? null : () => _changeZoom(.25),
                    onScrub: (value) {
                      setState(() => _scrubPage = value.round());
                      _revealChrome();
                    },
                    onScrubEnd: (value) => _goToPage(value.round()),
                    onThumbnailTap: _goToPage,
                  ),
                  if (!_ready)
                    const NovellaLoadingIndicator(message: 'Opening your PDF'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showContents() {
    _revealChrome();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF202124),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(
                  Icons.first_page_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'First page',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _goToPage(0);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.last_page_rounded,
                  color: Colors.white,
                ),
                title: const Text(
                  'Last page',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _goToPage(_pages - 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleChrome extends StatelessWidget {
  const _AppleChrome({
    required this.imageForPage,
    required this.visible,
    required this.saved,
    required this.page,
    required this.totalPages,
    required this.zoom,
    required this.onBack,
    required this.onContents,
    required this.onSave,
    required this.onSmaller,
    required this.onReset,
    required this.onLarger,
    required this.onScrub,
    required this.onScrubEnd,
    required this.onThumbnailTap,
  });

  final bool visible;
  final ui.Image? Function(int) imageForPage;
  final bool saved;
  final int page;
  final int totalPages;
  final double zoom;
  final VoidCallback onBack;
  final VoidCallback onContents;
  final VoidCallback onSave;
  final VoidCallback? onSmaller;
  final VoidCallback? onReset;
  final VoidCallback? onLarger;
  final ValueChanged<double> onScrub;
  final ValueChanged<double> onScrubEnd;
  final ValueChanged<int> onThumbnailTap;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !visible,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Row(
              children: [
                _Pill(
                  child: Row(
                    children: [
                      _IconTap(icon: Icons.chevron_left_rounded, onTap: onBack),
                      Container(width: 1, height: 22, color: Colors.white12),
                      _IconTap(
                        icon: Icons.format_list_bulleted_rounded,
                        onTap: onContents,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _Pill(
                  child: _IconTap(
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    onTap: onSave,
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(
                  child: Row(
                    children: [
                      _TextTap(label: 'A−', onTap: onSmaller),
                      _TextTap(
                        label: '${(zoom * 100).round()}%',
                        onTap: onReset,
                        small: true,
                      ),
                      _TextTap(label: 'A+', onTap: onLarger),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (totalPages > 0)
            Positioned(
              right: 18,
              top: 67,
              child: _Pill(
                color: const Color(0xE5222224),
                child: Text(
                  '${page + 1} of $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          if (totalPages > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 0,
                      max: (totalPages - 1).toDouble(),
                      value: page.clamp(0, totalPages - 1).toDouble(),
                      onChanged: onScrub,
                      onChangeEnd: onScrubEnd,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ThumbnailStrip(
                    imageForPage: imageForPage,
                    currentPage: page,
                    totalPages: totalPages,
                    onTap: onThumbnailTap,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.color = const Color(0xAA242830)});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 132),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .45, 1],
            colors: [
              Colors.white.withValues(alpha: .26),
              color,
              Colors.white.withValues(alpha: .10),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .32)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 24,
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Icon(icon, color: Colors.white, size: 23),
    ),
  );
}

class _TextTap extends StatelessWidget {
  const _TextTap({
    required this.label,
    required this.onTap,
    this.small = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 22,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          color: onTap == null ? Colors.white38 : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: small ? 10 : 17,
        ),
      ),
    ),
  );
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.imageForPage,
    required this.currentPage,
    required this.totalPages,
    required this.onTap,
  });

  final int currentPage;
  final ui.Image? Function(int) imageForPage;
  final int totalPages;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final pages = <int>[
      for (var page = currentPage - 2; page <= currentPage + 2; page++)
        if (page >= 0 && page < totalPages) page,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x88202024),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x887F8999), Color(0xBB20232A), Color(0x88555B66)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: pages.map((item) {
              final active = item == currentPage;
              return GestureDetector(
                onTap: () => onTap(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: active ? 42 : 29,
                  height: active ? 56 : 42,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFF9DA0A8),
                    borderRadius: BorderRadius.circular(3),
                    border: active
                        ? Border.all(color: const Color(0xFFA9D9FF), width: 2)
                        : null,
                    boxShadow: active
                        ? const [
                            BoxShadow(color: Color(0x6659B9FF), blurRadius: 12),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: imageForPage(item) != null
                      ? RawImage(image: imageForPage(item), fit: BoxFit.contain)
                      : Text(
                          '${item + 1}',
                          style: TextStyle(
                            color: active ? Colors.black : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
