import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CircularPercentageIndicator extends StatelessWidget {
  final double percentage; // 0.0 to 100.0
  final double size; // diameter
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color backgroundColor;

  const CircularPercentageIndicator({
    super.key,
    required this.percentage,
    this.size = 100,
    this.strokeWidth = 8,
    this.gradientColors = const [AppColors.buttonClr2, AppColors.buttonClr1],
    this.backgroundColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleBackgroundPainter(strokeWidth, backgroundColor),
          ),
          // Foreground Gradient Arc
          CustomPaint(
            size: Size(size, size),
            painter: _CircleGradientPainter(strokeWidth, gradientColors, percentage),
          ),
          // Center Text
          Text(
            "${percentage.toStringAsFixed(0)}%",
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackgroundPainter extends CustomPainter {
  final double strokeWidth;
  final Color backgroundColor;

  _CircleBackgroundPainter(this.strokeWidth, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, 2 * pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleGradientPainter extends CustomPainter {
  final double strokeWidth;
  final List<Color> gradientColors;
  final double percentage;

  _CircleGradientPainter(this.strokeWidth, this.gradientColors, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Proper SweepGradient with stops
    final gradient = LinearGradient(
      // startAngle: 0,
      // endAngle: 2 * pi,
      colors: gradientColors,
      stops: List.generate(
        gradientColors.length,
            (index) => index / (gradientColors.length - 1),
      ),
      tileMode: TileMode.clamp,
      transform: const GradientRotation(-pi / 2), // start from top
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

