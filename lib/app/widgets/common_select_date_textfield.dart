import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';

CustomTextFormField buildCustomTextFormFieldSelectDate({required TextEditingController controller}) {
  return CustomTextFormField(
    readOnly: true,
    controller: controller,
    hintText: "DD-MM-YYYY",
    borderColor: AppColors.borderColor,
    onTap: () async {
      FocusScope.of(navigatorKey.currentContext!).requestFocus(FocusNode());

      final DateTime? pickedDate = await showDatePicker(
        context: navigatorKey.currentContext!,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.backgroundClr2, // header & selected day
                onPrimary: AppColors.white,        // text on selected day
                onSurface: AppColors.textClr,      // normal day text
                surface: AppColors.white,          // dialog background
              ),

              // Buttons (CANCEL / OK)
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textClr,
                  textStyle: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
              ),

              // Header (Month + Year)
              textTheme: TextTheme(
                titleLarge: AppFontStyle.text_18_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),

              // Picker theme
              datePickerTheme: DatePickerThemeData(
                headerBackgroundColor: AppColors.backgroundClr2,
                headerForegroundColor: AppColors.textClr,
                dayForegroundColor: WidgetStateProperty.all(AppColors.textClr),
                weekdayStyle: AppFontStyle.text_14_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
                todayBackgroundColor:
                WidgetStateProperty.all(AppColors.buttonClr1.withOpacity(0.3)),
                todayForegroundColor: WidgetStateProperty.all(AppColors.buttonClr1),
                dayOverlayColor: WidgetStateProperty.all(
                  AppColors.buttonClr2.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        controller.text =
        "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
      }
    },
  );
}
