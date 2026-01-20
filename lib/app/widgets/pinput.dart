import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

class CommonPinput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onCompleted;
  final double width;
  final double height;

  const CommonPinput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.width = 77,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: width,
      height: height,
      textStyle: AppFontStyle.text_14_400(
        color: AppColors.black,
        fontFamily: AppFontFamily.gilroyMedium
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
    );

    return Pinput(
      length: 6,
      controller: controller,

      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly
      ],
      defaultPinTheme: defaultPinTheme,
      submittedPinTheme: defaultPinTheme,
      onCompleted: onCompleted,
      showCursor: true,
      preFilledWidget: Text(
        "0",
        style: AppFontStyle.text_14_400(
          color: AppColors.textLightClr,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}
