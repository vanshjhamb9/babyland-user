import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors{
  static const Color primary =  Color(0xFFFAC8F1);
  static const Color textClr = Color(0xFF1E293B);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.red;
  static const Color grey = Colors.grey;
  static const Color greyStroke = Color(0xffD5D7DA);
  static const Color greyLight = Color(0xffF2F5F8);
  static const Color lightGrey = Color(0xff7C8087);
  static const Color transparent = Colors.transparent;
  static const Color backgroundClr2 = Color(0xFFFFDCCE);
  static const Color backgroundClr1 = Color(0xFFFAC8F1);
  static const Color backgroundClr = Color(0xFFFFFFFF);
  static const Color textLightClr = Color(0xFF5B6679);
  static const Color buttonClr1 = Color(0xFFF8926C);
  static const Color buttonClr2 = Color(0xFFFF48DD);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color borderColorTextField = Color(0xFFE2E8F0);
  static const Color green = Color(0xFF4B9700);
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color darkBrown = Color(0xFFBE185D);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color starYellow = Color(0xFFFACC15);
  static const Color lightGreen = Color(0xFFE7FFED);
  static const Color lightBlue = Color(0xFFE0F3FF);
  static const Color lightPurple = Color(0xFFEEE0FF);
  static const Color lightYellow = Color(0xFFFFF3D2);
  static const Color blue = Color(0xFF002F6D);
  static const Color purpleClr = Color(0xFF43006D);
  static const Color orangeClr = Color(0xFFB86F00);
  static const Color lightWhite = Color(0xFFEBEDF4);


  static LinearGradient pinkPurple = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    transform: const GradientRotation(5),
    colors: [
      AppColors.backgroundClr1.withValues(alpha: 0.5),
      AppColors.backgroundClr2.withValues(alpha: 0.5),
    ],
  );

  static LinearGradient backGroundColor = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    transform: const GradientRotation(5),
    colors: [
      AppColors.buttonClr2.withValues(alpha: 0.15),
      AppColors.buttonClr1.withValues(alpha: 0.1),
    ],
  );

  static LinearGradient buttonClr = LinearGradient(
    // begin: Alignment.centerLeft,
    // end: Alignment.centerRight,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.buttonClr1.withValues(alpha: 0.9),
      AppColors.buttonClr2.withValues(alpha: 0.6),
    ],
  );

  static LinearGradient whiteGradientClr = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.white,
      AppColors.white,
    ],
  );


}