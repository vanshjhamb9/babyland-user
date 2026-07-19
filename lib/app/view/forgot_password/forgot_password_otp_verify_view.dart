import 'package:babyland/app/controller/forgot_password/forgot_pass_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/pinput.dart';
import '../../widgets/validation.dart';

class ForgotPasswordOtpVerifyView extends StatelessWidget {
  const ForgotPasswordOtpVerifyView({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer<ForgotPassController>(
      builder: (context, controller, child) {
        // if (!controller.isResendAvailable && controller.resendSeconds == 59) {
        //   controller.startResendCountdown();
        // }

        return Scaffold(
          body: Opacity(
            opacity: controller.otpApiData?.status ==  ApiStatus.LOADING ? 0.5 : 1,
            child: AppContainer(
              gradient: AppColors.backGroundColor,
              child: Column(
                children: [
                  CustomAppBar(backgroundClr: AppColors.transparent),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enter OTP Code 🔐",
                          style: AppFontStyle.text_28_400(
                            color: AppColors.textClr,
                            fontFamily: AppFontFamily.gilroySemiBold,
                          ),
                        ),
                        Text(
                          "We've sent an OTP code to ${controller.emailController.text}. Please enter it below to verify your account.",
                          maxLines: 10,
                          style: AppFontStyle.text_15_400(
                            color: AppColors.textLightClr,
                            fontFamily: AppFontFamily.gilroyRegular,
                          ),
                        ),
                        SizedBox(height: 32),

                        if (controller.otpApiData?.status == ApiStatus.ERROR)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              controller.otpApiData?.message ??
                                  'Verification failed. Please try again.',
                              style: AppFontStyle.text_14_400(
                                color: AppColors.red,
                                fontFamily: AppFontFamily.gilroyMedium,
                              ),
                            ),
                          ),

                        /// ---- PIN PUT ----
                        CommonPinput(
                          controller:controller.otpController,
                          onCompleted: (val) async {
                            pt("message.................");
                            controller.otpVerification();
                          },
                        ),

                        SizedBox(height: 32),

                        /// ---- RESEND TIMER ----
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(children: [
                              TextSpan(
                                text: "You can resend the code in ",
                                style: AppFontStyle.text_15_400(
                                  color: AppColors.textLightClr,
                                  fontFamily: AppFontFamily.gilroyRegular,
                                ),
                              ),
                              TextSpan(
                                text: controller.resendSeconds.toString(),
                                style: AppFontStyle.text_14_400(
                                  color: controller.isResendAvailable
                                      ? AppColors.buttonClr1
                                      : AppColors.textLightClr,
                                  fontFamily: AppFontFamily.gilroySemiBold,
                                ),
                              ),
                              TextSpan(
                                text: " seconds",
                                style: AppFontStyle.text_15_400(
                                  color: AppColors.textLightClr,
                                  fontFamily: AppFontFamily.gilroyRegular,
                                ),
                              ),
                            ]),
                          ),
                        ),

                        SizedBox(height: 14),

                        /// ---- RESEND OTP ----
                        Center(
                          child: GestureDetector(
                            onTap: controller.isResendAvailable
                                ? () async {
                              await controller.resendOtp(
                                  controller.emailController.text);
                              controller.otpController.clear();
                            }
                                : null,
                            child: Text(
                              "Resend code",
                              style: AppFontStyle.text_14_400(
                                color: controller.isResendAvailable
                                    ? AppColors.buttonClr1
                                    : AppColors.textLightClr,
                                fontFamily: AppFontFamily.gilroySemiBold,
                              ).copyWith(
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textClr,
                              ),
                            ),
                          ),
                        ),

                        /// Loading
                        if (controller.otpApiData?.status == ApiStatus.LOADING)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: customLoading(color: AppColors.buttonClr1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
