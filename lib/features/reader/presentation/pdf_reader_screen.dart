import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/widgets/friendly_error_state.dart';
import '../../../core/widgets/novella_loading_indicator.dart';
import '../../library/domain/book.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late Future<File> _pdfFile = _downloadPdf();
  PDFViewController? _controller;
  String? _viewerError;
  bool _ready = false;
  int _page = 0;
  int _pages = 0;
  double _zoom = 1;

  Future<File> _downloadPdf() async {
    final response = await http.get(Uri.parse(widget.book.fileUrl!));
    if (response.statusCode != 200) {
      throw HttpException(
        'PDF download failed with status ${response.statusCode}.',
      );
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/novella-${widget.book.id}.pdf');
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

  Future<void> _changeZoom(double amount) async {
    final controller = _controller;
    if (controller == null) return;
    final nextZoom = (_zoom + amount).clamp(1.0, 4.0).toDouble();
    final applied = await controller.setScale(nextZoom);
    if (mounted && applied) setState(() => _zoom = nextZoom);
  }

  Future<void> _resetZoom() async {
    final controller = _controller;
    if (controller == null) return;
    final applied = await controller.setScale(1);
    if (mounted && applied) setState(() => _zoom = 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F3F7),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Column(
        children: [
          Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            _pages == 0 ? 'Preparing your PDF' : 'Page ${_page + 1} of $_pages',
            style: const TextStyle(fontSize: 11, color: Color(0xFF7C7E89)),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Smaller text',
          onPressed: _zoom <= 1 ? null : () => _changeZoom(-.25),
          icon: const Text(
            'A−',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: _zoom == 1 ? null : _resetZoom,
          child: Text(
            '${(_zoom * 100).round()}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Larger text',
          onPressed: _zoom >= 4 ? null : () => _changeZoom(.25),
          icon: const Text(
            'A+',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    body: FutureBuilder<File>(
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
          return const NovellaLoadingIndicator(message: 'Preparing your PDF');
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
            PDFView(
              filePath: snapshot.data!.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              minZoom: 1,
              maxZoom: 4,
              onViewCreated: (controller) {
                _controller = controller;
                controller.setZoomLimits(1, 2, 4);
              },
              onRender: (pages) => setState(() {
                _pages = pages ?? 0;
                _ready = true;
              }),
              onPageChanged: (page, _) => setState(() => _page = page ?? 0),
              onError: (error) =>
                  setState(() => _viewerError = error.toString()),
            ),
            if (!_ready)
              const NovellaLoadingIndicator(message: 'Opening your PDF'),
          ],
        );
      },
    ),
  );
}
