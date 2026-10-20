// lib/ui/splash/splash_screen.dart
import 'package:espresso_log/ui/theme.dart';
import 'package:flutter/material.dart';

const Color _kCupColor = Color(0xFFE8D7B0);
const Duration _kPourDuration = Duration(milliseconds: 1800);
const Duration _kFadeDuration = Duration(milliseconds: 400);

/// Shows an abstract espresso-pour animation over [child] at app start,
/// then fades out. Matches the static launch splash and the app icon.
class AppStartSplash extends StatefulWidget {
  final Widget? child;

  const AppStartSplash({super.key, this.child});

  @override
  State<AppStartSplash> createState() => _AppStartSplashState();
}

class _AppStartSplashState extends State<AppStartSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _kPourDuration,
  )..forward();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Hold the full cup briefly, then fade out.
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _done = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        IgnorePointer(
          ignoring: _done,
          child: AnimatedOpacity(
            opacity: _done ? 0 : 1,
            duration: _kFadeDuration,
            curve: Curves.easeOut,
            child: ColoredBox(
              color: kBackgroundColor,
              child: Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) => CustomPaint(
                      painter: _PourPainter(
                        Curves.easeInOut.transform(_controller.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the logo on a 1024 unit grid (same geometry as
/// assets/branding/icon.svg), with the stream and liquid level driven by
/// [progress] in 0..1.
class _PourPainter extends CustomPainter {
  final double progress;

  _PourPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Content spans x 242..810, y 250..800 on the 1024 grid.
    canvas.scale(size.width / 1024, size.height / 1024);
    canvas.translate(-14, -190);

    final bowl = Path()
      ..moveTo(312, 600)
      ..quadraticBezierTo(312, 790, 512, 790)
      ..quadraticBezierTo(712, 790, 712, 600)
      ..close();

    // Liquid rises from the bottom of the cup.
    const liquidBottom = 800.0;
    final liquidTop = liquidBottom - 110 * progress;
    canvas.save();
    canvas.clipPath(bowl);
    canvas.drawRect(
      Rect.fromLTRB(300, liquidTop, 730, liquidBottom),
      Paint()..color = kAccentColor,
    );
    canvas.restore();

    // Streams: head falls first, then the tail follows, so a drop of liquid
    // travels down each spout.
    const streamTop = 365.0;
    final streamHead =
        streamTop + (liquidTop - streamTop) * _ease(progress * 3);
    final streamTail = progress < 0.85
        ? streamTop
        : streamTop + (streamHead - streamTop) * ((progress - 0.85) / 0.15);
    if (streamHead > streamTail) {
      final stream = Paint()..color = kAccentColor;
      for (final x in const [443.0, 563.0]) {
        canvas.drawRect(
          Rect.fromLTRB(x, streamTail, x + 18, streamHead),
          stream,
        );
      }
    }

    final outline = Paint()
      ..color = _kCupColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(312, 560)
        ..lineTo(312, 600)
        ..quadraticBezierTo(312, 790, 512, 790)
        ..quadraticBezierTo(712, 790, 712, 600)
        ..lineTo(712, 560),
      outline,
    );
    canvas.drawPath(
      Path()
        ..moveTo(712, 620)
        ..quadraticBezierTo(800, 620, 800, 690)
        ..quadraticBezierTo(800, 750, 725, 755),
      outline,
    );
    // Portafilter with two spouts above the cup.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(372, 250, 280, 70),
        const Radius.circular(35),
      ),
      outline,
    );
    canvas.drawPath(
      Path()
        ..moveTo(452, 320)
        ..lineTo(452, 352)
        ..moveTo(572, 320)
        ..lineTo(572, 352),
      outline,
    );
    // Handle pointing toward the viewer (foreshortened, down-left).
    canvas.drawLine(
      const Offset(368, 312),
      const Offset(262, 410),
      Paint.from(outline)..strokeWidth = 42,
    );
    canvas.restore();
  }

  double _ease(double t) => Curves.easeOut.transform(t.clamp(0.0, 1.0));

  @override
  bool shouldRepaint(_PourPainter old) => old.progress != progress;
}
