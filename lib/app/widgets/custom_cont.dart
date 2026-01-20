import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import 'container.dart';
import 'custom_image.dart';

class CustomCont extends StatelessWidget {
  final String title;
  final String path;

  const CustomCont({
    Key? key,
    required this.title,
    required this.path,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 76,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.white,
      radius: 8,
      isBordered: true,
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
    );
  }
}

