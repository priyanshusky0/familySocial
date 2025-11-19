import 'package:flutter/material.dart';
import 'dart:math' as math;



class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = math.min(centerX, centerY);

    
    final facePaint = Paint()
      ..color = const Color(0xFFF5F7FA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 10, facePaint);

    
    final markerPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMainHour = i % 3 == 0;
      final startRadius = radius - (isMainHour ? radius * 0.13 : radius * 0.10);
      final endRadius = radius - radius * 0.08;

      final x1 = centerX + startRadius * math.cos(angle);
      final y1 = centerY + startRadius * math.sin(angle);
      final x2 = centerX + endRadius * math.cos(angle);
      final y2 = centerY + endRadius * math.sin(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        markerPaint..strokeWidth = isMainHour ? 3 : 2,
      );
    }

    
    final now = DateTime.now();
    final hour = now.hour % 12;
    final minute = now.minute;
    final second = now.second;

    
    final hourAngle = ((hour + minute / 60) * 30 - 90) * math.pi / 180;
    final hourHandPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = math.max(4, radius * 0.03)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        centerX + (radius * 0.4) * math.cos(hourAngle),
        centerY + (radius * 0.4) * math.sin(hourAngle),
      ),
      hourHandPaint,
    );

    
    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minuteHandPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = math.max(3, radius * 0.02)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        centerX + (radius * 0.6) * math.cos(minuteAngle),
        centerY + (radius * 0.6) * math.sin(minuteAngle),
      ),
      minuteHandPaint,
    );

    
    final secondAngle = (second * 6 - 90) * math.pi / 180;
    final secondHandPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        centerX + (radius * 0.7) * math.cos(secondAngle),
        centerY + (radius * 0.7) * math.sin(secondAngle),
      ),
      secondHandPaint,
    );

    
    final centerDotPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, math.max(4, radius * 0.03), centerDotPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}