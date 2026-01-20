import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';

Text textFieldTitle({required String title,Color? color}) {
  return Text(title,
    style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium,color:color ?? AppColors.textClr),
  );
}

extension CapitalizeFirst on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
