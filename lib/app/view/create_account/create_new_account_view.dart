import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/social_login/social_login.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class CreateNewAccountView extends StatelessWidget {
CreateNewAccountView({super.key});

 final List<String> icons = [
    // ImageConstants.facebook,
    ImageConstants.google,
    ImageConstants.apple,
    // ImageConstants.whatsApp,
  ];

 SocialLoginService socialLoginService = SocialLoginService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backGroundColor,
            ),
            child: Column(
              children: [
                CustomAppBar(
                  centerTitle: true,
                  title: Text("Create new account",
                  style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),
                  ),
                  backgroundClr: AppColors.transparent,
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text("Begin with creating new free account. This helps you keep your learning way easier.",
                    style: AppFontStyle.text_14_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular),
                    maxLines: 5,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Button(
                    onTap: (){
                      Navigator.pushNamed(context, AppRoutes.addEmailView);
                    },
                    text: "Continue with email",
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "or",
                  style: AppFontStyle.text_16_600(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textLightClr),
                ),
                SizedBox(height: 20),
                Text(
                  "or continue with",
                  style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),
                ),
                SizedBox(height: 22),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children:List.generate(icons.length, (index) => InkWell(
                      splashColor: AppColors.transparent,
                      highlightColor: AppColors.transparent,
                      onTap: () {
                        switch(index){
                          case 1:
                            socialLoginService.signInWithGoogle();
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 14,right: icons.length -1 == index ? 10 :0),
                        height: 50,
                        width: 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: CustomImage(path: icons[index],h: 24,w: 24,),
                        )
                      ),
                    ),),
                  ),
                )
              ],
            )),
      ),
    );
  }
}
