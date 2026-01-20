import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GradientSliderTrackShape extends SliderTrackShape {
  @override
  void paint(
      PaintingContext context,
      Offset offset, {
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required Animation<double> enableAnimation,
        required TextDirection textDirection,
        required Offset thumbCenter,
        Offset? secondaryOffset,
        bool isEnabled = false,
        bool isDiscrete = false,
      }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Draw full gradient background
    final Paint gradientPaint = Paint()
      ..shader =AppColors.buttonClr.createShader(trackRect);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(10)),
      gradientPaint,
    );

    // Draw overlay for inactive part (right side of thumb)
    final Paint overlayPaint = Paint()
      ..color = Colors.white.withOpacity(0.65);

    final Rect inactiveRect = Rect.fromLTRB(
      thumbCenter.dx,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(inactiveRect, const Radius.circular(10)),
      overlayPaint,
    );
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 6;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
class CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 5,
    this.divisions = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        trackShape: GradientSliderTrackShape(),
        thumbColor: const Color(0xFFFF7E5F),
        overlayColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
        activeTrackColor: Colors.transparent,
        // thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        // divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
