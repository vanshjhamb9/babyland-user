import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';

CustomTextFormField buildCustomTextFormFieldSelectTime({required TextEditingController controller}) {
  return CustomTextFormField(
    readOnly: true,
    controller: controller,
    hintText: "--:--",
    borderColor: AppColors.borderColor,
    onTap: () async {
      FocusScope.of(navigatorKey.currentContext!).requestFocus(FocusNode());

      final TimeOfDay? pickedTime = await showTimePicker(
        context: navigatorKey.currentContext!,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.backgroundClr2, // header & selected time button
                onPrimary: AppColors.white,        // text on selected time
                onSurface: AppColors.textClr,      // time picker text
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

              // Time picker hour/minute text style
              timePickerTheme: TimePickerThemeData(
                backgroundColor: AppColors.white,
                hourMinuteTextStyle: AppFontStyle.text_18_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
                dayPeriodTextColor: AppColors.textClr,
                dialBackgroundColor: AppColors.backgroundClr2,
                dialHandColor: AppColors.buttonClr1,
                dialTextColor: AppColors.textClr,
                dayPeriodColor: AppColors.backgroundClr2,
                hourMinuteColor: AppColors.backgroundClr2,

              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Convert TimeOfDay to DateTime for formatting
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);

        // Format as "10:30 AM"
        final formattedTime = DateFormat.jm().format(dt);

        controller.text = formattedTime;
      }
    },
  );
}
