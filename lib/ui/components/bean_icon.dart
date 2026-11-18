import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A coffee bean drawn like a Material icon: it takes its size and colour
/// from the surrounding [IconTheme], so it follows the bottom bar's selected
/// and unselected colours.
class BeanIcon extends StatelessWidget {
  final double? size;

  const BeanIcon({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(painter: _BeanPainter(theme.color ?? Colors.white)),
    );
  }
}

class _BeanPainter extends CustomPainter {
  final Color color;

  _BeanPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.translate(w / 2, h / 2);
    canvas.rotate(math.pi / 6);

    // Bean body: an oval about 60% wide and 90% tall of the icon box.
    final body = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.6,
      height: h * 0.88,
    );
    canvas.drawOval(body, Paint()..color = color);

    // Centre crease: an S-curve cut out of the body.
    final top = body.top + h * 0.06;
    final bottom = body.bottom - h * 0.06;
    final crease = Path()
      ..moveTo(0, top)
      ..cubicTo(
        w * 0.16,
        top + h * 0.22,
        -w * 0.16,
        bottom - h * 0.22,
        0,
        bottom,
      );
    canvas.drawPath(
      crease,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BeanPainter old) => old.color != color;
}
