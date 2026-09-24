import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rasterizes only the current sheet and its neighbours, then bends the real
/// page texture around a cylinder. The gesture controls the fold continuously.
class CurlPdfView extends StatefulWidget {
  const CurlPdfView({
    super.key,
    required this.path,
    required this.bookId,
    required this.onPage,
    required this.onError,
    required this.onTouch,
  });
  final String path, bookId;
  final void Function(int, int) onPage;
  final ValueChanged<Object> onError;
  final VoidCallback onTouch;
  @override
  State<CurlPdfView> createState() => CurlPdfViewState();
}

class CurlPdfViewState extends State<CurlPdfView>
    with SingleTickerProviderStateMixin {
  ui.Image? imageForPage(int page) => _images[page];
  static const _channel = MethodChannel('novella/page_images');
  final _images = <int, ui.Image>{};
  final _pending = <int, Future<void>>{};
  final _transform = TransformationController();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  int _page = 0, _count = 0, _direction = 1;
  bool _loaded = false, _busy = false;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final value
          in prefs.getStringList('reading_page_by_book') ?? <String>[]) {
        final parts = value.split('|');
        if (parts.length == 2 && parts.first == widget.bookId) {
          _page = int.tryParse(parts.last) ?? 0;
        }
      }
      await _load(_page);
      if (!mounted) return;
      _page = _page.clamp(0, _count - 1);
      if (!_images.containsKey(_page)) await _load(_page);
      if (!mounted) return;
      setState(() => _loaded = true);
      widget.onPage(_page, _count);
      _prefetch();
    } catch (error) {
      if (mounted) widget.onError(error);
    }
  }

  Future<void> _load(int page) {
    if (_images.containsKey(page)) return Future.value();
    return _pending
        .putIfAbsent(page, () async {
          final data = await _channel.invokeMapMethod<String, dynamic>(
            'render',
            {'path': widget.path, 'page': page},
          );
          final codec = await ui.instantiateImageCodec(data!['bytes']);
          final frame = await codec.getNextFrame();
          codec.dispose();
          if (!mounted) {
            frame.image.dispose();
            return;
          }
          _count = data['count'] as int;
          _images[page] = frame.image;
          setState(() {});
        })
        .whenComplete(() => _pending.remove(page));
  }

  Future<void> _prefetch() async {
    try {
      for (final i in [
        _page + _direction,
        _page - _direction,
        _page + 2 * _direction,
      ]) {
        if (i >= 0 && i < _count) await _load(i);
      }
      if (!mounted) return;
      for (final i in _images.keys.toList()) {
        if ((i - _page).abs() > 2) {
          _images.remove(i)?.dispose();
          _pending.remove(i);
        }
      }
    } catch (_) {
      /* A direct page turn will surface a retryable render error. */
    }
  }

  Future<void> goToPage(int target) async {
    if (!_loaded ||
        _busy ||
        target == _page ||
        target < 0 ||
        target >= _count) {
      return;
    }
    _busy = true;
    try {
      await _load(target);
      if (!mounted) return;
      _direction = target > _page ? 1 : -1;
      // Non-adjacent scrub jumps do not pretend to turn intervening sheets.
      if ((target - _page).abs() == 1) {
        await _animation.animateTo(
          1,
          duration: Duration(
            milliseconds: (300 * (1 - _animation.value)).round().clamp(
              120,
              300,
            ),
          ),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) return;
      setState(() {
        _page = target;
        _animation.value = 0;
      });
      widget.onPage(_page, _count);
      _prefetch();
    } catch (error) {
      if (mounted) widget.onError(error);
    } finally {
      _busy = false;
    }
  }

  void setZoom(double value) {
    _scale = value;
    _transform.value = Matrix4.diagonal3Values(value, value, 1);
    setState(() {});
  }

  Future<void> _cancelTurn() async {
    if (_busy) return;
    _busy = true;
    try {
      await _animation.animateBack(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: Text('Opening pages…', style: TextStyle(color: Colors.white)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final image = _images[_page]!;
        final size = applyBoxFit(
          BoxFit.contain,
          Size(image.width.toDouble(), image.height.toDouble()),
          constraints.biggest,
        ).destination;
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: GestureDetector(
              onTap: widget.onTouch,
              onHorizontalDragStart: _scale > 1
                  ? null
                  : (_) {
                      if (!_busy) widget.onTouch();
                    },
              onHorizontalDragUpdate: _scale > 1
                  ? null
                  : (details) {
                      if (_busy) return;
                      if (_animation.value == 0) {
                        _direction = details.delta.dx < 0 ? 1 : -1;
                      }
                      final next = _page + _direction;
                      if (!_images.containsKey(next)) return;
                      _animation.value =
                          (_animation.value -
                                  details.delta.dx *
                                      _direction /
                                      (size.width * .8))
                              .clamp(0, 1);
                    },
              onHorizontalDragEnd: _scale > 1
                  ? null
                  : (details) async {
                      if (_busy) return;
                      final velocity =
                          details.velocity.pixelsPerSecond.dx * _direction;
                      if (velocity < -320 ||
                          (_animation.value > .16 && velocity < 320)) {
                        await goToPage(_page + _direction);
                      } else {
                        await _cancelTurn();
                      }
                    },
              onHorizontalDragCancel: _cancelTurn,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 4,
                panEnabled: _scale > 1,
                onInteractionEnd: (_) => setState(
                  () => _scale = _transform.value.getMaxScaleOnAxis(),
                ),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      size: size,
                      painter: _CurlPainter(
                        current: image,
                        next: _images[_page + _direction],
                        progress: _animation.value,
                        direction: _direction,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurlPainter extends CustomPainter {
  _CurlPainter({
    required this.current,
    required this.next,
    required this.progress,
    required this.direction,
  });
  final ui.Image current;
  final ui.Image? next;
  final double progress;
  final int direction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void flat(ui.Image image) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint(),
    );
    if (progress <= 0 || next == null) {
      flat(current);
      return;
    }
    flat(next!);
    canvas.save();
    canvas.clipRect(rect.inflate(12));
    final radius = size.width * .13;
    final crease = size.width - progress * (size.width + math.pi * radius);
    // Draw strips from the hinge outwards, including the reversed back face.
    const strips = 180;
    for (var i = 0; i < strips; i++) {
      final a = size.width * i / strips;
      final b = size.width * (i + 1) / strips;
      double project(double x) {
        final distance = x - crease;
        if (distance <= 0) return x;
        if (distance >= math.pi * radius) {
          return crease - (distance - math.pi * radius);
        }
        return crease + radius * math.sin(distance / radius);
      }

      final theta = ((a + b) / 2 - crease) / radius;
      final back = theta > math.pi / 2;
      var x1 = project(a), x2 = project(b);
      if (direction < 0) {
        x1 = size.width - x1;
        x2 = size.width - x2;
      }
      final heightLift = theta > 0 && theta < math.pi
          ? math.sin(theta) * 12
          : 0.0;
      final dest = Rect.fromLTRB(
        math.min(x1, x2),
        -heightLift,
        math.max(x1, x2) + .6,
        size.height + heightLift,
      );
      final sourceX = direction > 0 ? a : size.width - b;
      canvas.drawImageRect(
        current,
        Rect.fromLTWH(
          sourceX / size.width * current.width,
          0,
          (b - a) / size.width * current.width,
          current.height.toDouble(),
        ),
        dest,
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (back) {
        canvas.drawRect(dest, Paint()..color = const Color(0xC0F4F0E7));
      }
      final shade = theta > 0 && theta < math.pi
          ? .24 * (1 - math.sin(theta).abs())
          : 0.0;
      canvas.drawRect(
        dest,
        Paint()..color = Colors.black.withValues(alpha: shade),
      );
    }
    final edge = direction > 0 ? crease : size.width - crease;
    canvas.drawRect(
      Rect.fromLTWH(edge - 12, 0, 24, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.transparent, Color(0x38000000), Colors.transparent],
        ).createShader(Rect.fromLTWH(edge - 12, 0, 24, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurlPainter old) =>
      current != old.current ||
      next != old.next ||
      progress != old.progress ||
      direction != old.direction;
}
