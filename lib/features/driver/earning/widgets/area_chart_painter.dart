import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
class AreaChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  AreaChartPainter({
    required this.data,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final yAxisWidth = 35.0;
    final chartWidth = size.width - yAxisWidth;
    final chartHeight = size.height;

    _drawGridLines(canvas, yAxisWidth, chartWidth, chartHeight);
    _drawYAxisLabels(canvas, yAxisWidth, chartHeight);
    _drawChart(canvas, yAxisWidth, chartWidth, chartHeight);
  }

  void _drawGridLines(Canvas canvas, double yAxisWidth, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppColors.dividerGray.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 4.0;

    for (int i = 0; i <= 4; i++) {
      final y = (chartHeight / 4) * i;
      double startX = yAxisWidth;
      
      while (startX < yAxisWidth + chartWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashWidth).clamp(yAxisWidth, yAxisWidth + chartWidth), y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  void _drawYAxisLabels(Canvas canvas, double yAxisWidth, double chartHeight) {
    final interval = (maxValue / 4).ceil();
    
    for (int i = 0; i <= 4; i++) {
      final value = interval * (4 - i);
      final y = (chartHeight / 4) * i;
      
      final textSpan = TextSpan(
        text: value.toString(),
        style: TextStyle(
          color: AppColors.midGray,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );
    }
  }

  void _drawChart(Canvas canvas, double yAxisWidth, double chartWidth, double chartHeight) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryOrange.withOpacity(0.5),
          AppColors.primaryOrange.withOpacity(0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(yAxisWidth, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    final dashedLinePaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = chartWidth / (data.length - 1);
    
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = yAxisWidth + (i * stepX);
      final normalizedValue = (data[i] / maxValue).clamp(0.0, 1.0);
      final y = chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    path.moveTo(yAxisWidth, chartHeight);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(yAxisWidth + chartWidth, chartHeight);
    path.close();

    canvas.drawPath(path, fillPaint);

    for (int i = 0; i < points.length - 1; i++) {
      _drawDashedLine(
        canvas,
        points[i],
        points[i + 1],
        dashedLinePaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dashWidth = 4.0;
    final dashSpace = 3.0;
    
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / distance;
      final t2 = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;
      
      if (t2 > 1.0) break;
      
      final p1 = Offset(
        start.dx + dx * t1,
        start.dy + dy * t1,
      );
      final p2 = Offset(
        start.dx + dx * t2,
        start.dy + dy * t2,
      );
      
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
