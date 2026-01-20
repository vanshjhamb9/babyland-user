import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import 'container.dart';
import 'custom_image.dart';

class IconTextRow extends StatelessWidget {
  final String label;
  final String imagePath;

  const IconTextRow({
    super.key,
    required this.label,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppContainer(
              height: 25,
              width: 25,
              child: CustomImage(
                path: imagePath,
                scale: 12,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppFontStyle.text_12_400(
                color: AppColors.textLightClr,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
