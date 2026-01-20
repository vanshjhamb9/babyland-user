import 'package:babyland/app/controller/forgot_password/forgot_pass_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_popup.dart';
import '../../widgets/validation.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgotPassController>(
      builder: (context, provider, _) => Scaffold(
          body: AppContainer(
    gradient: AppColors.backGroundColor,
    child:  Form(
      key: provider.formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAppBar(backgroundClr: AppColors.transparent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Forgot Password? 🔑",
                  style: AppFontStyle.text_28_400(
                    color: AppColors.textClr,
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
                Text(
                  "Don't worry, we've got you covered. Enter your registered email address, and we'll send you an OTP code to reset your password.",
                  maxLines: 10,
                  style: AppFontStyle.text_15_400(
                    color: AppColors.textLightClr,
                    fontFamily: AppFontFamily.gilroyRegular,
                  ),
                ),
                SizedBox(height: 32),
                textFieldTitle(title: "Registered Email address"),
                SizedBox(height: 4),
                CustomTextFormField(
                  controller: provider.emailController,
                  borderColor: AppColors.borderColor,
                  hintText: "example@gmail.com",
                  onChanged: (value){

                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a email";
                    }
                    else if (!provider.validateEmail(value.trim())) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
              ],
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
         if(provider.emailController.text.isNotEmpty){
           provider.forgotPassApi();
         }else{
           AppPopUp.showToast(message: "Please enter email.");
         }
        },
        height: 56,
        text:provider.isLoading ?  null  : "Continue",
        child: provider.isLoading
            ? customLoading(color: AppColors.white)
            : null,
      ),
    ),
          ),
        )
        ); }
}
