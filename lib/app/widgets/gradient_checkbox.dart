import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GradientCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Color> gradientColors;
  final double size;
  final double borderRadius;

  const GradientCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.gradientColors = const [
      AppColors.buttonClr2,
      AppColors.buttonClr1,
    ],
    this.size = 20,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: value ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: value ? AppColors.transparent : AppColors.greyStroke,
            width: 1.5,
          ),
        ),
        child:   Icon(Icons.check, color:value ? Colors.white : AppColors.transparent, size: 18),
      ),
    );
  }
}
