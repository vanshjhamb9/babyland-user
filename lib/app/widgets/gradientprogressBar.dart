import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'container.dart';

class GradientProgressBar extends StatelessWidget {
  final double progress; // Should be between 0 and 100
  final double height;

  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure progress is between 0 and 100
    final clampedProgress = progress.clamp(0.0, 100.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: Stack(
        children: [
          AppContainer(
            height: height,
            width: double.infinity,
            color: AppColors.greyStroke,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate actual width based on percentage
              final actualWidth = (clampedProgress / 100) * constraints.maxWidth;

              return AppContainer(
                height: height,
                width: actualWidth,
                radius: 35,
                gradient: AppColors.buttonClr,
              );
            },
          ),
        ],
      ),
    );
  }
}