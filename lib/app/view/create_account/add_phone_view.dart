import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/social_login/social_login.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/core/auth/phone_normalize.dart';
import 'package:babyland/core/services/firebase_phone_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddPhoneView extends StatefulWidget {
  const AddPhoneView({super.key});

  @override
  State<AddPhoneView> createState() => _AddPhoneViewState();
}

class _AddPhoneViewState extends State<AddPhoneView> {
  final TextEditingController phoneController = TextEditingController();
  String _countryCallingCode = '91';
  bool _skipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebasePhoneAuthService>().resetVerificationState();
    });
  }

  /// Sends Firebase SMS OTP, then navigates to OTP screen only after [codeSent].
  Future<void> _sendOtpAndContinue() async {
    if (phoneController.text.trim().isEmpty) {
      AppPopUp.showToast(message: 'Please enter phone number');
      return;
    }

    final phoneAuth = context.read<FirebasePhoneAuthService>();
    try {
      await phoneAuth.sendOtp(
        phoneController.text.trim(),
        defaultCountryCallingCode: _countryCallingCode,
      );
      if (!mounted) return;
      if (!phoneAuth.hasPendingPhoneVerification && !phoneAuth.isAutoVerified) {
        AppPopUp.showToast(
          message: phoneAuth.userFacingMessage ??
              'Could not send SMS. Check Firebase configuration.',
        );
        return;
      }
      await Navigator.pushNamed(context, AppRoutes.phoneOtpVerifyView);
    } catch (e) {
      if (!mounted) return;
      AppPopUp.showToast(
        message: phoneAuth.userFacingMessage ??
            'Failed to send verification SMS. Check network and Firebase setup.',
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _skipPhone() async {
    if (_skipping) return;
    setState(() => _skipping = true);
    await UserLocalData.clearNeedsPhoneProfile();
    if (!mounted) return;
    try {
      await SocialLoginService().routeAfterAuthSession();
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.splashView,
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebasePhoneAuthService>(
      builder: (context, phoneAuth, _) {
        final sending = phoneAuth.isSendingOtp;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backGroundColor),
            child: Column(
              children: [
                CustomAppBar(
                  centerTitle: true,
                  title: Text(
                    'Complete your profile',
                    style: AppFontStyle.text_20_400(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ),
                  ),
                  backgroundClr: AppColors.transparent,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phone number is optional. You can add it now or skip.",
                        style: AppFontStyle.text_14_400(
                          color: AppColors.textLightClr,
                          fontFamily: AppFontFamily.gilroyRegular,
                        ),
                      ),
                      if (phoneAuth.userFacingMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          phoneAuth.userFacingMessage!,
                          style: AppFontStyle.text_13_400(
                            color: AppColors.red,
                            fontFamily: AppFontFamily.gilroyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      textFieldTitle(title: 'Phone Number (optional)'),
                      const SizedBox(height: 6),
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
                                value: _countryCallingCode,
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
                                  if (v != null) {
                                    setState(() => _countryCallingCode = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextFormField(
                              controller: phoneController,
                              hintText: '10-digit mobile number',
                              textInputType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Button(
                        onTap: sending || _skipping ? null : _sendOtpAndContinue,
                        child: sending
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Send code',
                                style: AppFontStyle.text_16_400(
                                  fontFamily: AppFontFamily.gilroyBold,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: sending || _skipping ? null : _skipPhone,
                          child: Text(
                            _skipping ? 'Continuing…' : 'Skip for now',
                            style: AppFontStyle.text_14_400(
                              color: AppColors.buttonClr1,
                              fontFamily: AppFontFamily.gilroyMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
