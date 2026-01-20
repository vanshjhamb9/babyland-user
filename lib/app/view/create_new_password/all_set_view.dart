import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class AllSetView extends StatelessWidget {
  const AllSetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: CustomImage(path: ImageConstants.allSet)),
              SizedBox(height: 25),
              Text(
                "You’re All Set!",
                style: AppFontStyle.text_28_400(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              Text(
                "Your password has been updated.",
                maxLines: 10,
                style: AppFontStyle.text_15_400(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyRegular,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Button(
            onTap: (){
              Navigator.pushNamed(context, AppRoutes.signInView);
            },
            height: 56,
            text: "Sign In",
          ),
        ),
      ),
    );
  }
}
