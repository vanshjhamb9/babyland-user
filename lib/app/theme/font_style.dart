import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:flutter/material.dart';

class AppFontStyle {
  /// Base TextStyle Generator
  static TextStyle _textStyle(
      Color? color,
      double size,
      FontWeight fontWeight, {
        double? height,
        String? fontFamily,
      }) {
    return TextStyle(
      color: color ?? AppColors.black, // ✅ optional color with default
      fontSize: size,
      fontWeight: fontWeight,
      height: height ?? 1.4,
      overflow: TextOverflow.ellipsis,
      fontFamily: fontFamily ?? AppFontFamily.gilroyRegular,
    );
  }

  /// ===================== 300 Weight =====================
  static text_14_300({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 14, FontWeight.w300, height: height, fontFamily: fontFamily);

  static text_16_300({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 16, FontWeight.w300, height: height, fontFamily: fontFamily);

  static text_18_300({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 18, FontWeight.w300, height: height, fontFamily: fontFamily);

  /// ===================== 400 Weight =====================
  static text_10_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 10, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_9_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 9, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_11_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 11, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_12_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 12, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_13_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 13, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_14_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 14, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_15_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 15, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_16_400({Color? color, double? height, FontWeight? fontWeight, String? fontFamily}) =>
      _textStyle(color, 16, fontWeight ?? FontWeight.w400,
          height: height, fontFamily: fontFamily);

  static text_17_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 17, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_18_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 18, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_20_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 20, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_22_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 22, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_24_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 24, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_26_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 26, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_28_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 28, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_32_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 32, FontWeight.w400, height: height, fontFamily: fontFamily);

  static text_34_400({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 34, FontWeight.w400, height: height, fontFamily: fontFamily);

  /// ===================== 500 Weight =====================
  static text_12_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 12, FontWeight.w500, height: height, fontFamily: fontFamily);

  static text_14_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 14, FontWeight.w500, height: height, fontFamily: fontFamily);

  static text_15_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 15, FontWeight.w500, height: height, fontFamily: fontFamily);

  static text_16_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 16, FontWeight.w500, height: height, fontFamily: fontFamily);

  static text_18_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 18, FontWeight.w500, height: height, fontFamily: fontFamily);

  static text_20_500({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 20, FontWeight.w500, height: height, fontFamily: fontFamily);

  /// ===================== 600 Weight =====================
  static text_12_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 12, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_13_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 13, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_14_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 14, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_15_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 15, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_16_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 16, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_18_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 18, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_20_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 20, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_22_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 22, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_23_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 23, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_24_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 24, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_26_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 26, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_28_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 28, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_30_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 30, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_32_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 32, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_34_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 34, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_36_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 36, FontWeight.w600, height: height, fontFamily: fontFamily);

  static text_40_600({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 40, FontWeight.w600, height: height, fontFamily: fontFamily);

  /// ===================== 800 Weight =====================
  static text_14_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 14, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_15_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 15, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_16_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 16, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_18_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 18, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_20_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 20, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_22_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 22, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_24_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 24, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_26_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 26, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_28_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 28, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_30_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 30, FontWeight.w800, height: height, fontFamily: fontFamily);

  static text_56_800({Color? color, double? height, String? fontFamily}) =>
      _textStyle(color, 56, FontWeight.w800, height: height, fontFamily: fontFamily);

  /// ===================== Custom =====================
  static customText(
      double size,
      FontWeight fontWeight, {
        Color? color,
        double? height,
        String? fontFamily,
      }) =>
      _textStyle(color, size, fontWeight, height: height, fontFamily: fontFamily);
}
