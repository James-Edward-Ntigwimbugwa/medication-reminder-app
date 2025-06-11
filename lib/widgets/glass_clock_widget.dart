// File: lib/widgets/glass_clock_widget.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';

class GlassClockWidget extends StatefulWidget {
  final double size;
  final Color glassColor;

  const GlassClockWidget({
    super.key,
    this.size = 200.0,
    this.glassColor = const Color(0xFF4CAF50), // Green color
  });

  @override
  State<GlassClockWidget> createState() => _GlassClockWidgetState();
}

class _GlassClockWidgetState extends State<GlassClockWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Glass effect with elevation
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: widget.glassColor.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Glass background with transparency
              gradient: RadialGradient(
                colors: [
                  widget.glassColor.withOpacity(0.2),
                  widget.glassColor.withOpacity(0.1),
                  widget.glassColor.withOpacity(0.05),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              // Glass border
              border: Border.all(
                color: widget.glassColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: ClockPainter(_currentTime, widget.glassColor),
              size: Size(widget.size, widget.size),
            ),
          ),
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime dateTime;
  final Color accentColor;

  ClockPainter(this.dateTime, this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 20;

    // Draw hour markers and numbers
    _drawHourMarkersAndNumbers(canvas, center, radius);

    // Draw minute markers
    _drawMinuteMarkers(canvas, center, radius);

    // Draw clock hands
    _drawClockHands(canvas, center, radius);

    // Draw center dot
    _drawCenterDot(canvas, center);
  }

  void _drawHourMarkersAndNumbers(Canvas canvas, Offset center, double radius) {
    final hourPaint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final textStyle = TextStyle(
      color: accentColor.withOpacity(0.9),
      fontSize: radius * 0.15, // Responsive font size
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto', // Modern font
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;

      // Hour markers (thicker lines)
      final startPoint = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, hourPaint);

      // Hour numbers with better positioning
      final textPainter = TextPainter(
        text: TextSpan(text: i.toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final numberRadius = radius - 35; // Moved closer to center
      final numberOffset = Offset(
        center.dx + numberRadius * math.cos(angle) - textPainter.width / 2,
        center.dy + numberRadius * math.sin(angle) - textPainter.height / 2,
      );

      // Add subtle shadow to numbers
      final shadowPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: textStyle.copyWith(
            color: Colors.black.withOpacity(0.3),
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      shadowPainter.layout();
      shadowPainter.paint(canvas, numberOffset);

      textPainter.paint(canvas, numberOffset);
    }
  }

  void _drawMinuteMarkers(Canvas canvas, Offset center, double radius) {
    final minutePaint = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) { // Skip hour markers
        final angle = (i * 6 - 90) * math.pi / 180;
        final startPoint = Offset(
          center.dx + (radius - 8) * math.cos(angle),
          center.dy + (radius - 8) * math.sin(angle),
        );
        final endPoint = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawLine(startPoint, endPoint, minutePaint);
      }
    }
  }

  void _drawClockHands(Canvas canvas, Offset center, double radius) {
    final hour = dateTime.hour % 12;
    final minute = dateTime.minute;
    final second = dateTime.second;

    // Hour hand
    final hourAngle = (hour * 30 + minute * 0.5 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = accentColor.withOpacity(0.9)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.5 * math.cos(hourAngle),
        center.dy + radius * 0.5 * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute hand
    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.7 * math.cos(minuteAngle),
        center.dy + radius * 0.7 * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // Second hand
    final secondAngle = (second * 6 - 90) * math.pi / 180;
    final secondPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.8 * math.cos(secondAngle),
        center.dy + radius * 0.8 * math.sin(secondAngle),
      ),
      secondPaint,
    );
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);

    // Inner white dot for contrast
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, innerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Usage in your AddMedicationScreen:
// Add this widget where you want the clock to appear

class ClockSection extends StatelessWidget {
  const ClockSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Current Time",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          const GlassClockWidget(
            size: 220,
            glassColor: Color(0xFF4CAF50), // Green theme
          ),
          const SizedBox(height: 16),
          Text(
            "Schedule your medication reminders",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}