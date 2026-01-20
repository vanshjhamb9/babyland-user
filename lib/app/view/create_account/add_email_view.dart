import 'package:babyland/app/controller/create_account/create_account_provider.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/pinput.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEmailView extends StatelessWidget {
  AddEmailView({super.key});


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateAccountProvider>(
      create: (context) => CreateAccountProvider(),
      child: Consumer<CreateAccountProvider>(
        builder: (context, provider, _) {
        return  Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backGroundColor,
            ),
            child: Column(
              children: [
                CustomAppBar(
                  centerTitle: true,
                  leadingOnTap: () => provider.currentIndex > 0 ? provider.pageController.previousPage(duration: Duration(microseconds: 100), curve: Curves.bounceIn) : Navigator.pop(context),
                  title: Text(
                    provider.currentIndex == 0 ?
                    "Add your email" : provider.currentIndex == 1 ? "Verify your email" : "Add Password",
                    style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),
                  ),
                  backgroundClr: AppColors.transparent,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (index1) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: 15,
                      decoration: BoxDecoration(
                        color: index1 <= provider.currentIndex ?  AppColors.buttonClr1 :AppColors.greyStroke,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    // physics: NeverScrollableScrollPhysics(),
                    controller:provider.pageController,
                    itemCount: 3,
                    onPageChanged: (value) {
                      provider.changeIndex(value);
                    },
                    itemBuilder:
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: index == 0 ?
                        _addYourEmail(provider) :
                        index == 1 ?
                        verifyYourEmail(provider) :
                            _addPassword(provider),
                      );
                    },),
                ),
              ],
            ),
          ),
          bottomNavigationBar: bottomNavBarBtn(provider, context),
        );
      },),
    );
  }

  Column verifyYourEmail(provider,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text:
        TextSpan(
            children: [
          TextSpan(
            text: "We just sent 6-digit code to",
            style: AppFontStyle.text_15_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular),
          ),
          TextSpan(
            text: " ${provider.emailController.text}, ",
            style: AppFontStyle.text_14_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroySemiBold,),
          ),
          TextSpan(
            text: " enter it below:  ",
            style: AppFontStyle.text_15_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular,),
          ),
        ]),
        ),
        SizedBox(height: 16),
        Text("Enter Code",
          style: AppFontStyle.text_14_400(color: AppColors.black,fontFamily: AppFontFamily.gilroyMedium), ),
        SizedBox(height: 5),
        CommonPinput(controller:provider.otpController)
      ],
    );
  }



  Widget _addYourEmail(CreateAccountProvider provider) {
    return Form(
      key: provider.emailKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textFieldTitle(title: "What’s your name?"),
            SizedBox(height: 6),
            CustomTextFormField(
              hintText: "Please enter your name",
              controller: provider.nameController,
              validator: (value) {
                if((value?.isEmpty ?? false)){
                  return "Please enter your name";
                }else if(value!.length < 3){
                  return "Please enter a valid name";
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            textFieldTitle(title: "Email"),
            SizedBox(height: 6),
            CustomTextFormField(
              hintText: "youremail@gmail.com",
              controller: provider.emailController,
              validator: (value) {
                if(value?.isEmpty ?? false){
                  return "Please enter your email";
                }else if(!isValidEmail(value?.trim())){
                  return "please enter a valid email";
                }
                return null;
              },
            ),
          ],
      ),
    );
  }

  Widget _addPassword(CreateAccountProvider provider) {
    return Consumer<CreateAccountProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textFieldTitle(title: "Enter password",),
            SizedBox(height: 6),
            CustomTextFormField(
              controller: provider.passwordController,
              obscureText: provider.isShowPass,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.getPasswordStrength(),
                    style: AppFontStyle.text_12_400(
                      color: provider.getStrengthColor(),
                    ),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                      onTap: () {
                        provider.setIsShowPass(!provider.isShowPass);
                      },
                      child: Icon(provider.isShowPass ? Icons.visibility_outlined : Icons.visibility_off,size: 16,color: AppColors.black)),
                  SizedBox(width: 10),
                ],
              ),
              hintText: "Password",
              onChanged:provider.validatePassword,
            ),

            SizedBox(height: 6),
            Row(
              children: [
                _buildIndicator(1),
                _buildIndicator(2),
                _buildIndicator(3),
              ],
            ),
            SizedBox(height: 6),
            Text("Use at least 8 characters with a mix of letters, numbers, and symbols.",
              maxLines: 3,
              style: AppFontStyle.text_12_400(
                fontFamily: AppFontFamily.gilroyRegular,
              ),),
            SizedBox(height: 20),
            textFieldTitle(title: "Confirm password"),
            SizedBox(height: 6),
            CustomTextFormField(
              controller: provider.confirmPasswordController,
              hintText: "Confirm Password",
            ),

          ],
        );
      },
    );
  }

  Widget _buildIndicator(int index) {
    return Expanded(
      child: Consumer<CreateAccountProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          decoration: BoxDecoration(
            color: provider.trueConditionsCount >= index ? Colors.green : AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
      ),
    );
  }

  Widget bottomNavBarBtn(CreateAccountProvider provider, BuildContext context) {
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
              if((provider.emailKey.currentState?.validate() ?? false) && provider.currentIndex == 0){
                provider.requestVerification();
              }else if(provider.currentIndex == 1) {
                if (provider.otpController.text.length < 6) {
                  AppPopUp.showToast(
                      message: "Please enter a valid 6 digit otp.");
                } else {
                  provider.otpVerification();
                }
              }else if(provider.currentIndex == 2){
                if(provider.passwordController.text.trim().isEmpty && provider.confirmPasswordController.text.trim().isEmpty){
                  AppPopUp.showToast(message: "Please enter password");
                }else if(provider.passwordController.text.trim() != provider.confirmPasswordController.text.trim()){
                  AppPopUp.showToast(message: "Password not matched!");
                }else{
                provider.setPassword(token: provider.otpApiData?.data?.token ?? "");
              }
             }
          },
          child:
          provider.forgotPassRequestOtpData?.status == ApiStatus.LOADING ||
          provider.otpApiData?.status == ApiStatus.LOADING ||
          provider.setPasswordApiData?.status == ApiStatus.LOADING
          ? customLoading() :
          Text(provider.currentIndex == 0 ? "Create an account" : provider.currentIndex == 1 ? "Verify Email" : "Continue",
          style:  AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),
          ),
        ),
      ),
    );
  }

}
