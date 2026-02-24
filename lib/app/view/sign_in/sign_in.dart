import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/services/social_login/social_login.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/sign_in/sign_in_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {

  SocialLoginService googleSignInService = SocialLoginService();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignInController>(
      create: (context) => SignInController(),
      builder: (context, child) => Scaffold(
        body: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Consumer<SignInController>(
            builder: (context, provider, _) =>  Form(
              key: provider.formKey,
              child: Stack(
                children: [
                  Opacity(
                    opacity: provider.loginApiData?.status == ApiStatus.LOADING ? 0.5 : 1,
                    child: Column(
                      children: [
                        CustomAppBar(backgroundClr: AppColors.transparent),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Welcome Back!",
                                        style: AppFontStyle.text_28_400(
                                          color: AppColors.textClr,
                                          fontFamily: AppFontFamily.gilroySemiBold,
                                        ),
                                      ),
                                      CustomImage(path: ImageConstants.babyDear, w: 34, h: 44),
                                    ],
                                  ),
                                  Text(
                                    "Access your BabyLand account and stay on top of your cycle.",
                                    maxLines: 5,
                                    style: AppFontStyle.text_15_400(
                                      color: AppColors.textLightClr,
                                      fontFamily: AppFontFamily.gilroyRegular,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  textFieldTitle(title: "Email"),
                                  SizedBox(height: 6),
                                  CustomTextFormField(
                                    controller: provider.emailController,
                                    borderColor: AppColors.borderColor,
                                    hintText: "example@gmail.com",
                                    validator: (value) {
                                      if(value!.isEmpty){
                                        return "Please enter your email";
                                      }else if(!isValidEmail(value)){
                                        return "Please enter a valid email!";
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  textFieldTitle(title: "Enter password"),
                                  SizedBox(height: 6),
                                  CustomTextFormField(
                                    controller: provider.passwordController,
                                    borderColor: AppColors.borderColor,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter a password";
                                      }
                                      if (value.length < 8) {
                                        return "Please enter a valid 8-digit password";
                                      }
                                      return null;
                                    },
                                    hintText: "Enter password",
                                    obscureText: provider.isShowPass,
                                    suffix: InkWell(
                                      onTap: () {
                                        provider.setIsShowPass(provider.isShowPass == false ? true : false);
                                      },
                                      child: Icon(
                                       provider.isShowPass == true ? Icons.visibility_off : Icons.visibility,
                                        size: 16,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Center(
                                        child: GradientCheckbox(
                                          value: provider.isChecked,
                                          onChanged: (val) {
                                              provider.setIsChecked(val);
                                          },
                                          gradientColors: const [
                                           AppColors.buttonClr2,
                                           AppColors.buttonClr1,
                                          ], // custom gradient
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text("Remember me",
                                        style:  AppFontStyle.text_14_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),
                                      ),
                                      Spacer(),
                                      InkWell(
                                        onTap: ()=> Navigator.pushNamed(context, AppRoutes.forgotPasswordView),
                                        child: Text("Forgot password?",
                                          style:  AppFontStyle.text_14_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 42),
                                  Center(
                                    child: RichText(text:
                                    TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Don't have an account?",
                                            style:  AppFontStyle.text_16_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),
                                          ),
                                          TextSpan(
                                            text: " Sign up",
                                            style:  AppFontStyle.text_16_400(color: AppColors.buttonClr1,fontFamily: AppFontFamily.gilroyMedium),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.pushNamed(context, AppRoutes.createNewAccountView);
                                              },
                                          ),
                                        ]
                                    )),
                                  ),
                                  SizedBox(height: 24),
                                  Center(
                                    child: Text(
                                      "or continue with",
                                      style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),
                                    ),
                                  ),
                                  SizedBox(height: 22),
                                  Center(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children:List.generate(
                                          provider.icons.length, (index) => InkWell(
                                          splashColor: AppColors.transparent,
                                          highlightColor: AppColors.transparent,
                                          onTap: () {
                                            switch(index){
                                              case 0 :
                                                googleSignInService.signInWithGoogle();
                                            }
                                          },
                                          child: Container(
                                            margin: EdgeInsets.only(left: 16),
                                            height: 50,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
                                              color: AppColors.white,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(13),
                                              child: CustomImage(path: provider.icons[index],h: 24,w: 24,),
                                            )
                                          ),
                                         ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if(provider.loginApiData?.status == ApiStatus.LOADING)
                  customLoading(color: AppColors.buttonClr1),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Consumer<SignInController>(
            builder: (context, provider, _)  {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Button(
                  onTap: (){
                    if (provider.formKey.currentState!.validate()) {
                      provider.login();
                    }
                  },
                  height: 56,
                  text: "Sign In",
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}

