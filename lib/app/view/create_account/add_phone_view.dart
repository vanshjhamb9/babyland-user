import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/core/services/firebase_phone_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddPhoneView extends StatefulWidget {
  const AddPhoneView({super.key});

  @override
  State<AddPhoneView> createState() => _AddPhoneViewState();
}

class _AddPhoneViewState extends State<AddPhoneView> {
  final TextEditingController phoneController = TextEditingController();

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
      await phoneAuth.sendOtp(phoneController.text.trim());
      if (!mounted) return;
      if (!phoneAuth.hasPendingPhoneVerification) {
        AppPopUp.showToast(
          message: phoneAuth.userFacingMessage ??
              'Could not send SMS. Check Firebase SHA-1/SHA-256 and Phone auth.',
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
                  title: const Text(
                    'Complete your profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  backgroundClr: AppColors.transparent,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'We’ll send a verification code to your number (Firebase SMS).',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      if (phoneAuth.userFacingMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          phoneAuth.userFacingMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 20),
                      textFieldTitle(title: 'Phone Number'),
                      const SizedBox(height: 6),
                      CustomTextFormField(
                        controller: phoneController,
                        hintText: '10-digit mobile or +91…',
                        textInputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 30),
                      Button(
                        onTap: sending ? null : _sendOtpAndContinue,
                        child: sending
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
