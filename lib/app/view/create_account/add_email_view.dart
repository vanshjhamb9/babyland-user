import 'package:babyland/app/controller/create_account/create_account_provider.dart';
import 'package:babyland/app/data/response/status.dart';
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
import 'package:babyland/core/auth/phone_normalize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddEmailView extends StatelessWidget {
  const AddEmailView({super.key});


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
                    provider.currentIndex == 0 ? "Create new account" : "Verify your number",
                    style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),
                  ),
                  backgroundClr: AppColors.transparent,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
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
                    physics: NeverScrollableScrollPhysics(), // Prevent swipe to skip validation
                    controller:provider.pageController,
                    itemCount: 2,
                    onPageChanged: (value) {
                      provider.changeIndex(value);
                    },
                    itemBuilder:
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: index == 0 ?
                        SingleChildScrollView(child: _addYourDetails(provider)) :
                        verifyYourEmail(provider),
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
            text: " ${provider.phoneDisplayE164}, ",
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
        CommonPinput(controller:provider.otpController),
        if (provider.phoneAuthMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            provider.phoneAuthMessage!,
            style: AppFontStyle.text_13_400(
              color: AppColors.red,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: Text(
            provider.resendCooldownSeconds > 0
                ? "Resend in ${provider.resendCooldownSeconds}s"
                : "Didn't receive OTP?",
            style: AppFontStyle.text_14_400(
              color: AppColors.textLightClr,
              fontFamily: AppFontFamily.gilroyRegular,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: provider.isSendingPhoneOtp || !provider.canResendPhoneOtp
                ? null
                : () => provider.resendSignupOtp(),
            child: Text(
              "Resend OTP",
              style: AppFontStyle.text_14_400(
                color: provider.canResendPhoneOtp && !provider.isSendingPhoneOtp
                    ? AppColors.buttonClr1
                    : AppColors.textLightClr,
                fontFamily: AppFontFamily.gilroySemiBold,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }



  Widget _addYourDetails(CreateAccountProvider provider) {
    return Form(
      key: provider.emailKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(height: 20),
            textFieldTitle(title: "Phone Number"),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greyStroke),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.countryCallingCode,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: PhoneNormalize.countryOptions
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.dial,
                              child: Text(
                                '${c.iso} +${c.dial}',
                                style: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) provider.setCountryCallingCode(v);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextFormField(
                    hintText: "10-digit mobile number",
                    controller: provider.phoneController,
                    textInputType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: (value) {
                      return PhoneNormalize.validationError(
                        value ?? '',
                        dialCode: provider.countryCallingCode,
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            textFieldTitle(title: "Enter password"),
            SizedBox(height: 6),
            CustomTextFormField(
              controller: provider.passwordController,
              obscureText: provider.isShowPass,
              suffix: InkWell(
                  onTap: () {
                    provider.setIsShowPass(!provider.isShowPass);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(provider.isShowPass ? Icons.visibility_outlined : Icons.visibility_off,size: 20,color: AppColors.black),
                  )),
              hintText: "Password",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 6) {
                   return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
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
              if(provider.currentIndex == 0) {
                 if (provider.signupApiData?.status == ApiStatus.LOADING) {
                   return;
                 }
                 if(provider.emailKey.currentState?.validate() ?? false) {
                    provider.signup();
                 }
              } else if(provider.currentIndex == 1) {
                if (provider.verifyOtpSignupData?.status == ApiStatus.LOADING) {
                  return;
                }
                if (provider.otpController.text.length < 6) {
                  AppPopUp.showToast(
                      message: "Please enter a valid 6 digit otp.");
                } else {
                  provider.verifyOtpSignup();
                }
              }
          },
          child:
          provider.signupApiData?.status == ApiStatus.LOADING ||
          provider.verifyOtpSignupData?.status == ApiStatus.LOADING
          ? customLoading() :
          Text(provider.currentIndex == 0 ? "Send OTP" : "Verify Number",
          style:  AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),
          ),
        ),
      ),
    );
  }

}
