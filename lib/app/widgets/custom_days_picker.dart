
import 'package:babyland/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../theme/font_family.dart';
import '../theme/font_style.dart';

class CustomDayPicker extends StatelessWidget {
  final double? height;
  final double? itemHeight;
  final FixedExtentScrollController? controller;
  final Function(int) onChanged;
  final int? selectedDay;
  final bool? showDays;
  final int? daysLength;
  final int startFrom;
  final int? disableBelow;

  const CustomDayPicker({
    super.key,
    this.height,
    this.itemHeight,
    this.controller,
    required this.onChanged,
    this.selectedDay,
    this.showDays = true,
    this.daysLength = 30,
    this.startFrom = 1,
    this.disableBelow,
  });

  @override
  Widget build(BuildContext context) {
    final double height = this.height ?? MediaQuery.of(context).size.height * 0.7;
    const double itemHeightPredefined = 40.0;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: itemHeight ?? itemHeightPredefined,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.0001,
            squeeze: 0.8,
            onSelectedItemChanged: (index) {
              final value = startFrom + index;
              if (disableBelow != null && value <= disableBelow!) return;
              onChanged(value);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final actualDay = startFrom + index;
                if (index < 0 || actualDay > (daysLength == 31 ? 31 : 30)) return null;

                final isDisabled = disableBelow != null && actualDay <= disableBelow!;
                final distance = ((selectedDay ?? actualDay) - actualDay).abs();

                // Font weight
                FontWeight fontWeight;
                if (distance == 0) {
                  fontWeight = FontWeight.bold;
                } else if (distance == 1) {
                  fontWeight = FontWeight.w600;
                } else {
                  fontWeight = FontWeight.w400;
                }

                // Color
                Color color;
                if (isDisabled) {
                  color = AppColors.grey;
                } else if (distance == 0) {
                  color = AppColors.buttonClr1;
                } else if (distance == 1) {
                  color = AppColors.textClr;
                } else if (distance == 2) {
                  color = AppColors.textClr.withValues(alpha: 0.60);
                } else {
                  color = AppColors.textClr.withValues(alpha: 0.40);
                }

                // Scale for size
                double scale;
                if (distance == 0) {
                  scale = 1.3;
                } else if (distance == 1) {
                  scale = 1.05;
                } else if (distance == 2) {
                  scale = 0.95;
                } else {
                  scale = 0.85;
                }

                // Dynamic vertical offset for spacing effect
                double offset = 0;
                if (distance == 1) {
                  offset = 5;
                } else if (distance == 2) {
                  offset = 10;
                } else if (distance >= 3) {
                  offset = 15;
                }

                return Center(
                  child: Transform.translate(
                    offset: Offset(0, offset * (distance / (distance == 0 ? 1 : distance))),
                    child: Transform.scale(
                      scale: scale,
                      child: Text(actualDay.toString().padLeft(2,"0"),
                        style:  AppFontStyle.text_24_400(color: color,fontFamily: AppFontFamily.gilroySemiBold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 55,
                  decoration:  BoxDecoration(
                    color: AppColors.transparent,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppColors.buttonClr1, width: 1),
                    ),
                  ),
                ),
              ),
              if (showDays == true)
                Positioned(
                  right: -5,
                  bottom: 16,
                  child: Text(
                     "days",
                    style:  AppFontStyle.text_14_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyRegular),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}