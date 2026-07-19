import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  final String? title;
  final String description;
  final List<String>? bulletPoints;

  const AboutSection({
    super.key,
    this.title,
    required this.description,
    this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppFontStyle.text_16_600(
              fontFamily: AppFontFamily.gilroyBold,
              color: AppColors.textClr,
            ).copyWith(overflow: TextOverflow.visible),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          description,
          style: AppFontStyle.text_15_400(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.textClr,
          ).copyWith(overflow: TextOverflow.visible, height: 1.5),
          softWrap: true,
          textAlign: TextAlign.justify,
        ),
        if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...bulletPoints!.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: AppFontStyle.text_15_400(
                      color: AppColors.buttonClr1,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: AppFontStyle.text_14_400(
                        fontFamily: AppFontFamily.gilroyRegular,
                        color: AppColors.textLightClr,
                      ).copyWith(overflow: TextOverflow.visible, height: 1.5),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
