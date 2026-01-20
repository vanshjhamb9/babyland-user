import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';

class LetsGetStartedView extends StatelessWidget {
  const LetsGetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: mediaQueryH(context)*0.25),
              Center(child: CustomImage(path: ImageConstants.babyDear)) ,
              SizedBox(height: 15),
              Text("Let's Get Started!",style: AppFontStyle.text_32_400(fontFamily: AppFontFamily.gilroyBold),),
              SizedBox(height: 10),
              Text("Let's dive in into your account",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr),)  ,
               SizedBox(height: 75),
              Button(
                onTap: (){
                  Navigator.pushNamed(context, AppRoutes.createNewAccountView);
                },
                text: "Sign up",
              ),
              SizedBox(height: 10),
              Button(
                color: AppColors.transparent,
                border: Border.all(color: AppColors.borderColor),
                onTap: (){
                  Navigator.pushNamed(context, AppRoutes.signInView);
                },
                text: "Sign in",
                textStyle: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.black),
              ),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Privacy Policy",style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),
                    Text(" • "),
                    Text("Terms of Service",style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr),),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
