import 'dart:math';
import 'package:flutter/material.dart';

class CircularGauge extends StatelessWidget {
  final double confidence;
  final double size;

  const CircularGauge({
    super.key,
    required this.confidence,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: confidence),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _GaugePainter(
            value: value,
            theme: Theme.of(context),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final ThemeData theme;

  _GaugePainter({required this.value, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;

    // Scale factors relative to gauge size for proper rendering at any size
    final double arcStroke = (size.width * 0.05).clamp(3.0, 8.0);
    final double tickInset = arcStroke + (size.width * 0.07);
    final double needleWidth = (size.width * 0.02).clamp(1.5, 3.0);
    final double pinRadius = (size.width * 0.04).clamp(3.0, 7.0);
    final double pinInner = (pinRadius * 0.45).clamp(1.5, 3.0);

    // 1. Draw outer glowing bezel/ring
    final bezelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.1),
          theme.colorScheme.primary.withValues(alpha: 0.8),
          theme.colorScheme.primary.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius + 2, bezelPaint);

    // 2. Draw dial background (dark twilight glass style)
    final dialBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialBgPaint);

    // 3. Define the start and sweep angle for the barometer gauge (135 degrees to 405 degrees)
    // 0 rad is at 3 o'clock. 135 deg = 3 * pi / 4. Sweep is 270 deg = 3 * pi / 2.
    const startAngle = 3 * pi / 4;
    const totalSweep = 3 * pi / 2;
    final currentSweep = value * totalSweep;

    // Draw secondary background track
    final trackPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 15),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Draw active confidence gradient arc
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcStroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.3),
          theme.colorScheme.primary,
          Colors.cyanAccent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 15));
    
    if (value > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 15),
        startAngle,
        currentSweep,
        false,
        activePaint,
      );
    }

    // 4. Draw scientific tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final majorTickPaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Fewer ticks at small sizes to avoid clutter
    final int numTicks = size.width < 140 ? 21 : 31;
    for (int i = 0; i < numTicks; i++) {
      final angle = startAngle + (i / (numTicks - 1)) * totalSweep;
      final isMajor = i % 5 == 0;
      
      final double tickLength = isMajor ? 8.0 : 4.0;
      final startRadius = radius - 15 - tickInset;
      final endRadius = startRadius - tickLength;

      final startOffset = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      final endOffset = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );

      canvas.drawLine(startOffset, endOffset, isMajor ? majorTickPaint : tickPaint);
    }

    // 5. Draw dark backing behind center text so needle doesn't obscure it
    final textZoneRadius = radius * 0.42;
    final textBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, textZoneRadius, textBgPaint);

    // 6. Draw analog physical needle pointing to current value
    // Drawn BEFORE text so text is always on top
    final needleAngle = startAngle + currentSweep;
    final needleLength = radius - 15 - tickInset - 2;
    
    final needlePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = needleWidth
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    // Draw the tail of the needle extending slightly backwards
    final double tailLength = size.width * 0.08;
    final needleTail = Offset(
      center.dx - tailLength * cos(needleAngle),
      center.dy - tailLength * sin(needleAngle),
    );

    canvas.drawLine(needleTail, needleEnd, needlePaint);

    // Needle pivot center pin
    final centerPinOuter = Paint()..color = Colors.redAccent;
    final centerPinInner = Paint()..color = Colors.white;

    canvas.drawCircle(center, pinRadius, centerPinOuter);
    canvas.drawCircle(center, pinInner, centerPinInner);

    // 7. Draw digital readout in center (ON TOP of everything)
    final percentageText = '${(value * 100).toStringAsFixed(1)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: percentageText,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.19,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
          shadows: [
            Shadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 6),
    );

    // Label under percentage
    final double labelFontSize = (size.width * 0.07).clamp(7.0, 11.0);
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'CONFIDENCE',
        style: TextStyle(
          color: Colors.white70,
          fontSize: labelFontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy + textPainter.height / 2 - 6),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
