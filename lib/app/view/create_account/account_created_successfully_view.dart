import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class AccountCreatedSuccessfullyView extends StatelessWidget {
  const AccountCreatedSuccessfullyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      bottomNavigationBar:bottomNavBarBtn(context) ,
    );
  }

  Widget _body() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.backGroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: 76,
                width: 76,
                child: CustomImage(path: ImageConstants.done),
            ),
            SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Your account is created successfully.",
                maxLines: 3,
                textAlign: TextAlign.center,
                style: AppFontStyle.text_28_400(fontFamily: AppFontFamily.gilroySemiBold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomNavBarBtn(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backGroundColor
      ),
      height: 100,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14,vertical: 24),
        child: Button(
          height: 58,
          onTap: (){
            Navigator.pushReplacementNamed(context, AppRoutes.basicProfileView,);
          },
          text:"Add Basic Profile",
        ),
      ),
    );
  }

}
