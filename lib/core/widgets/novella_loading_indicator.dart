import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Novella's signature loader: an open book with pages that gently fan out.
class NovellaLoadingIndicator extends StatefulWidget {
  const NovellaLoadingIndicator({super.key, this.message = ''});

  final String message;

  @override
  State<NovellaLoadingIndicator> createState() =>
      _NovellaLoadingIndicatorState();
}

class _NovellaLoadingIndicatorState extends State<NovellaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: widget.message.isEmpty ? 'Loading' : widget.message,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final open = Curves.easeInOutCubic.transform(_controller.value);
          return SizedBox(
            width: 154,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var layer = 2; layer >= 0; layer--) ...[
                  _FlyingPage(isLeft: true, layer: layer, open: open),
                  _FlyingPage(isLeft: false, layer: layer, open: open),
                ],
                Transform.translate(
                  offset: Offset(0, -open * 2),
                  child: Transform.scale(
                    scaleX: 1 + open * .075,
                    child: Image.asset(
                      'assets/novella_launcher_logo.png',
                      width: 106,
                      height: 106,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 9,
                  child: Container(
                    width: 38 + open * 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C4EA9).withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _FlyingPage extends StatelessWidget {
  const _FlyingPage({
    required this.isLeft,
    required this.layer,
    required this.open,
  });

  final bool isLeft;
  final int layer;
  final double open;

  @override
  Widget build(BuildContext context) {
    final direction = isLeft ? -1.0 : 1.0;
    final delay = math.max(0, open - layer * .13) / (1 - layer * .13);
    final spread = delay.clamp(0.0, 1.0).toDouble();
    final distance = 10 + layer * 7 + spread * (15 + layer * 8);
    final angle = direction * (.08 + layer * .055 + spread * .22);
    return Transform.translate(
      offset: Offset(direction * distance, -8 - layer * 3 - spread * 10),
      child: Transform.rotate(
        angle: angle,
        alignment: isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Opacity(
          opacity: (.18 + spread * .68).clamp(0.0, 1.0).toDouble(),
          child: SizedBox(
            width: 44,
            height: 64,
            child: CustomPaint(
              painter: _PagePainter(isLeft: isLeft, layer: layer),
            ),
          ),
        ),
      ),
    );
  }
}

class _PagePainter extends CustomPainter {
  const _PagePainter({required this.isLeft, required this.layer});

  final bool isLeft;
  final int layer;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isLeft) {
      path
        ..moveTo(size.width, size.height)
        ..quadraticBezierTo(size.width * .1, size.height * .88, 2, 8)
        ..quadraticBezierTo(size.width * .55, 3, size.width, 0)
        ..close();
    } else {
      path
        ..moveTo(0, size.height)
        ..quadraticBezierTo(
          size.width * .9,
          size.height * .88,
          size.width - 2,
          8,
        )
        ..quadraticBezierTo(size.width * .45, 3, 0, 0)
        ..close();
    }
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: .96),
          const Color(0xFFB9D9FF).withValues(alpha: .72),
        ],
        begin: isLeft ? Alignment.topLeft : Alignment.topRight,
        end: isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3D8DFF).withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PagePainter oldDelegate) =>
      oldDelegate.isLeft != isLeft || oldDelegate.layer != layer;
}
