import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import 'button.dart';
import 'container.dart';

class SubCustomContainer extends StatelessWidget {
  final String title;
  final String price;
  final bool isMostPopular;
  final bool borderValue;

  const SubCustomContainer({
    Key? key,
    required this.title,
    required this.price,
    this.isMostPopular = false,
    this.borderValue = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(10),
      color: AppColors.white,
      radius: 8,
      border: Border.all(
        color: borderValue
            ? AppColors.buttonClr1
            : AppColors.borderColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppFontStyle.text_18_400(
                  color: AppColors.black,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              const SizedBox(width: 10),
              if (isMostPopular)
                Button(
                  height: 24,
                  width: 95,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  text: "Most popular",
                  child: Text(
                    "Most popular",
                    style: AppFontStyle.text_12_400(
                      color: AppColors.white,
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            price,
            style: AppFontStyle.text_16_400(
              color: AppColors.black,
              fontFamily: AppFontFamily.gilroySemiBold,
            ),
          ),
        ],
      ),
    );
  }
}
