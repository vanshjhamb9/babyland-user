import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import 'custom_image.dart';

class CustomCont extends StatelessWidget {
  final String title;
  final String path;

  const CustomCont({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CustomImage(path: path, scale: 5,),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppFontStyle.text_15_400(
                fontFamily: AppFontFamily.gilroySemiBold,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 30, color: AppColors.black.withValues(alpha: 0.8),)
          ],
        ),
      ),
    );
  }
}

