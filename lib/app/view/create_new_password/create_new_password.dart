import 'package:babyland/app/controller/create_new_password/create_new_password_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/forgot_password/forgot_pass_controller.dart';
import '../../theme/font_family.dart';
import '../../widgets/custom_appbar.dart';

class CreateNewPasswordView extends StatelessWidget {
  const CreateNewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateNewPasswordProvider(),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: AppContainer(
            gradient: AppColors.backGroundColor,
            child: Column(
              children: [
                CustomAppBar(backgroundClr: AppColors.transparent),
                _addPassword(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Consumer<CreateNewPasswordProvider>(
              builder: (context, provider, _) {
                return Button(
                  onTap: () {
                    final password = provider.passwordController.text.trim();
                    final confirm = provider.confirmPasswordController.text.trim();

                    if (password.isEmpty) {
                      AppPopUp.showToast(
                          message: "Please enter password!",
                          lineColor: AppColors.red);
                      return;
                    }

                    if (!provider.isPasswordValid) {
                      AppPopUp.showToast(
                          message: "Password does not meet requirements!",
                          lineColor: AppColors.red);
                      return;
                    }

                    if (confirm.isEmpty || confirm != password) {
                      AppPopUp.showToast(
                          message: "Passwords do not match!",
                          lineColor: AppColors.red);
                      return;
                    }

                    // All good → navigate
                    context.read<ForgotPassController>().setPassword(password: provider.confirmPasswordController.text);
                    },

                  height: 56,
                  child: Consumer<ForgotPassController>(
                    builder: (context, ctrl, _) {
                      return ctrl.setPasswordApiData?.status == ApiStatus.LOADING
                          ? customLoading()
                          : Center(
                        child: Text(
                          "Set New Password",
                          style: AppFontStyle.text_16_400(
                            fontFamily: AppFontFamily.gilroyBold,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  Widget _addPassword() {
    return Consumer<CreateNewPasswordProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Secure Your Account 🔒",
                style: AppFontStyle.text_28_400(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              Text(
                "Enter a new password for your account. Ensure it’s strong and unique for enhanced security.",
                maxLines: 10,
                style: AppFontStyle.text_15_400(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyRegular,
                ),
              ),
              SizedBox(height: 32),
              textFieldTitle(title: "Enter new password",),
              SizedBox(height: 6),
              CustomTextFormField(
                controller: provider.passwordController,
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
                    Icon(Icons.visibility_outlined,size: 16,color: AppColors.black),
                    SizedBox(width: 10),
                  ],
                ),
                hintText: "Enter password",
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
              SizedBox(height: 28),
              textFieldTitle(title: "Confirm password"),
              SizedBox(height: 6),
              CustomTextFormField(
                controller: provider.confirmPasswordController,
                hintText: "Enter confirm password",
                onChanged: (_) {
                  provider.notifyListeners();
                },
              ),


            ],
          ),
        );
      },
    );
  }
  Widget _buildIndicator(int index) {
    return Expanded(
      child: Consumer<CreateNewPasswordProvider>(
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


}
