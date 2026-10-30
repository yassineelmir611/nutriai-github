import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrendLineSeries {
  const TrendLineSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

class CurvedTrendChart extends StatelessWidget {
  const CurvedTrendChart({
    super.key,
    required this.labels,
    required this.series,
    this.minValue = 0,
    this.maxValue = 1.25,
    this.height = 210,
    this.guideValues = const [0, 0.5, 1.0, 1.25],
  });

  final List<String> labels;
  final List<TrendLineSeries> series;
  final double minValue;
  final double maxValue;
  final double height;
  final List<double> guideValues;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: guideValues.reversed
                      .map(
                        (value) => Text(
                          '${(value * 100).round()}%',
                          style: textStyle,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomPaint(
                  painter: _CurvedTrendChartPainter(
                    series: series,
                    minValue: minValue,
                    maxValue: maxValue,
                    guideValues: guideValues,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Row(
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CurvedTrendChartPainter extends CustomPainter {
  const _CurvedTrendChartPainter({
    required this.series,
    required this.minValue,
    required this.maxValue,
    required this.guideValues,
  });

  final List<TrendLineSeries> series;
  final double minValue;
  final double maxValue;
  final List<double> guideValues;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series.first.values.isEmpty) return;

    const horizontalPadding = 10.0;
    const verticalPadding = 14.0;
    final chartRect = Rect.fromLTWH(
      horizontalPadding,
      verticalPadding,
      size.width - (horizontalPadding * 2),
      size.height - (verticalPadding * 2),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE7EAF7)
      ..strokeWidth = 1;

    for (final guide in guideValues) {
      final y = _mapY(guide, chartRect);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final targetPaint = Paint()
      ..color = const Color(0xFFB0B6D6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(chartRect.left, _mapY(1, chartRect)),
      Offset(chartRect.right, _mapY(1, chartRect)),
      targetPaint,
    );

    for (var index = 0; index < series.length; index++) {
      final trend = series[index];
      final points = _buildPoints(trend.values, chartRect);
      if (points.isEmpty) continue;

      if (index == 0) {
        final areaPath = _buildSmoothPath(points)
          ..lineTo(points.last.dx, chartRect.bottom)
          ..lineTo(points.first.dx, chartRect.bottom)
          ..close();

        final areaPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              trend.color.withValues(alpha: 0.20),
              trend.color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(chartRect);
        canvas.drawPath(areaPath, areaPaint);
      }

      final linePaint = Paint()
        ..color = trend.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_buildSmoothPath(points), linePaint);

      for (final point in points) {
        canvas.drawCircle(
          point,
          4.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          point,
          3,
          Paint()..color = trend.color,
        );
      }
    }
  }

  List<Offset> _buildPoints(List<double> values, Rect chartRect) {
    if (values.isEmpty) return const [];

    if (values.length == 1) {
      return [
        Offset(
          chartRect.center.dx,
          _mapY(values.first, chartRect),
        )
      ];
    }

    final stepX = chartRect.width / (values.length - 1);
    return List.generate(values.length, (index) {
      final x = chartRect.left + (stepX * index);
      final y = _mapY(values[index], chartRect);
      return Offset(x, y);
    });
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      return path;
    }

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      final controlX = (current.dx + next.dx) / 2;
      path.cubicTo(
        controlX,
        current.dy,
        controlX,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  double _mapY(double value, Rect chartRect) {
    final normalized =
        ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0).toDouble();
    return chartRect.bottom - (normalized * chartRect.height);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final totalDistance = (end - start).distance;
    final direction = (end - start) / totalDistance;
    var distance = 0.0;

    while (distance < totalDistance) {
      final segmentStart = start + (direction * distance);
      final segmentEnd = start +
          (direction *
              math.min(distance + dashWidth, totalDistance).toDouble());
      canvas.drawLine(segmentStart, segmentEnd, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedTrendChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.guideValues != guideValues;
  }
}
