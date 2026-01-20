import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:flutter/material.dart';

class GeneralExceptionWidget extends StatefulWidget {
  final VoidCallback onPress;

  const GeneralExceptionWidget({Key? key, required this.onPress}) : super(key: key);

  @override
  _GeneralExceptionWidgetState createState() => _GeneralExceptionWidgetState();
}

class _GeneralExceptionWidgetState extends State<GeneralExceptionWidget> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              height: height * .15,
            ),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [ AppColors.buttonClr1.withValues(alpha: 0.9),
                    AppColors.buttonClr2.withValues(alpha: 0.6),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.white, // This color is ignored by ShaderMask
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  "Oops!\nSomething went wrong. Please try again.",
                  textAlign: TextAlign.center,
                  style: AppFontStyle.text_16_400(color: AppColors.black,fontFamily: AppFontFamily.gilroyMedium)
                ),
              ),
            ),
            SizedBox(
              height: height * .06,
            ),
            InkWell(
              onTap: widget.onPress, // Retry logic passed from the parent widget
              child: Container(
                height: 44,
                width: 160,
                decoration: BoxDecoration(
                  color: AppColors.red, // Retry button color (red for general error)
                  borderRadius: BorderRadius.circular(50),
                  gradient: AppColors.buttonClr,
                ),
                child: Center(
                  child: Text(
                    "Retry",
                      style: AppFontStyle.text_16_400(color: AppColors.white,fontFamily: AppFontFamily.gilroyMedium)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
