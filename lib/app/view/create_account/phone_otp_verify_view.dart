import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/core/services/firebase_phone_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/pinput.dart';

/// Enter SMS code after [FirebasePhoneAuthService.sendOtp] (Firebase Phone Auth).
class PhoneOtpVerifyView extends StatefulWidget {
  const PhoneOtpVerifyView({super.key});

  @override
  State<PhoneOtpVerifyView> createState() => _PhoneOtpVerifyViewState();
}

class _PhoneOtpVerifyViewState extends State<PhoneOtpVerifyView> {
  final _otpController = TextEditingController();
  bool _syncingBackend = false;
  bool _isVerifying = false;

  String _nationalDigits(String? e164) {
    if (e164 == null || e164.isEmpty) return '';
    final d = e164.replaceAll(RegExp(r'\D'), '');
    if (d.length >= 10) return d.substring(d.length - 10);
    return d;
  }

  Future<void> _onOtpComplete(String code) async {
    if (_isVerifying) return;
    final phoneAuth = context.read<FirebasePhoneAuthService>();
    if (code.length != 6) return;
    setState(() => _isVerifying = true);
    try {
      await phoneAuth.verifySmsCode(code);
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      if (idToken == null) {
        throw Exception("Failed to retrieve Firebase ID token");
      }

      setState(() => _syncingBackend = true);
      final repo = context.read<Repository>();
      final national = _nationalDigits(phoneAuth.phoneE164);

      // Update payload to include idToken for verification on the backend
      final response = await repo.updatePhone({
        'phone': national,
        'idToken': idToken,
      });
      if (!mounted) return;

      if (response.success == true) {
        AppPopUp.showToast(message: response.message ?? 'Phone verified');
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.stagesView,
          arguments: {'fromLoginScreen': true},
        );
      } else {
        AppPopUp.showToast(
          message:
              response.message ??
              'Phone verified in Firebase but profile update failed.',
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.stagesView,
          arguments: {'fromLoginScreen': true},
        );
      }
    } on FirebaseAuthException catch (_) {
      if (mounted && phoneAuth.userFacingMessage != null) {
        AppPopUp.showToast(message: phoneAuth.userFacingMessage!);
      }
    } catch (e) {
      if (mounted) {
        AppPopUp.showToast(message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncingBackend = false;
          _isVerifying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebasePhoneAuthService>(
      builder: (context, phoneAuth, _) {
        final masked = phoneAuth.phoneE164 ?? '';
        final busy = phoneAuth.isBusy || _syncingBackend || _isVerifying;

        return Scaffold(
          body: AppContainer(
            gradient: AppColors.backGroundColor,
            child: Stack(
              children: [
                Column(
                  children: [
                    CustomAppBar(backgroundClr: AppColors.transparent),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify phone',
                            style: AppFontStyle.text_28_400(
                              color: AppColors.textClr,
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit code sent to $masked',
                            maxLines: 4,
                            style: AppFontStyle.text_15_400(
                              color: AppColors.textLightClr,
                              fontFamily: AppFontFamily.gilroyRegular,
                            ),
                          ),
                          if (phoneAuth.userFacingMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              phoneAuth.userFacingMessage!,
                              style: AppFontStyle.text_14_400(
                                color: AppColors.red,
                                fontFamily: AppFontFamily.gilroyMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          CommonPinput(
                            controller: _otpController,
                            onCompleted: (v) {
                              if (!busy) _onOtpComplete(v);
                            },
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              phoneAuth.resendCooldownSeconds > 0
                                  ? 'Resend in ${phoneAuth.resendCooldownSeconds}s'
                                  : 'Didn’t get the SMS?',
                              style: AppFontStyle.text_14_400(
                                color: AppColors.textLightClr,
                                fontFamily: AppFontFamily.gilroyRegular,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: GestureDetector(
                              onTap: busy || !phoneAuth.canResendOtp
                                  ? null
                                  : () async {
                                      _otpController.clear();
                                      try {
                                        await phoneAuth.resendOtp();
                                        if (context.mounted) {
                                          AppPopUp.showToast(
                                            message: 'Code sent',
                                          );
                                        }
                                      } catch (_) {
                                        if (context.mounted &&
                                            phoneAuth.userFacingMessage !=
                                                null) {
                                          AppPopUp.showToast(
                                            message:
                                                phoneAuth.userFacingMessage!,
                                          );
                                        }
                                      }
                                    },
                              child: Text(
                                'Resend code',
                                style:
                                    AppFontStyle.text_14_400(
                                      color: phoneAuth.canResendOtp && !busy
                                          ? AppColors.buttonClr1
                                          : AppColors.textLightClr,
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                    ).copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (busy) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }
}
