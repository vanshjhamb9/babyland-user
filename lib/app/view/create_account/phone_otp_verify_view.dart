import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/core/auth/jwt_utils.dart';
import 'package:babyland/core/di/service_locator.dart';
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
    print('[OTP-AUDIT] _onOtpComplete start code.len=${code.length}');
    try {
      print('[OTP-AUDIT] calling verifySmsCode...');
      await phoneAuth.verifySmsCode(code);
      print('[OTP-AUDIT] verifySmsCode returned. mounted=$mounted');
      if (!mounted) {
        print('[OTP-AUDIT] NOT mounted — aborting');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      print('[OTP-AUDIT] currentUser uid=${user?.uid} phoneNumber=${user?.phoneNumber}');
      final idToken = await user?.getIdToken();
      print('[OTP-AUDIT] idToken obtained: ${idToken != null ? 'len=${idToken.length}' : 'NULL'}');

      if (idToken == null) {
        print('[OTP-AUDIT] idToken is NULL — throwing');
        throw Exception("Failed to retrieve Firebase ID token");
      }

      setState(() => _syncingBackend = true);
      final repo = context.read<Repository>();
      final national = _nationalDigits(phoneAuth.phoneE164);
      print('[OTP-AUDIT] phone national=$national');

      final payload = <String, dynamic>{
        'phone': national,
        'idToken': idToken,
      };
      // Include Google idToken if this is a Google sign-in flow requiring phone
      final googleIdToken = await SecureStorage.getGoogleIdToken();
      print('[OTP-AUDIT] googleIdToken from storage: ${googleIdToken != null ? 'len=${googleIdToken.length}' : 'NULL'}');
      if (googleIdToken != null && googleIdToken.isNotEmpty) {
        payload['googleIdToken'] = googleIdToken;
        final googlePayload = decodeJwtPayload(googleIdToken);
        final googleEmail = googlePayload?['email']?.toString();
        print('[OTP-AUDIT] googleEmail from JWT=$googleEmail');
        if (googleEmail != null && googleEmail.isNotEmpty) {
          payload['email'] = googleEmail;
        }
      }

      // The backend /auth/update-phone requires an auth-token header, but in the
      // requirePhone flow we have no backend JWT yet. Try the Firebase ID token
      // first (backend likely verifies Firebase tokens), then Google ID token.
      final authHeaderValue = idToken ?? googleIdToken;
      print('[OTP-AUDIT] auth header: using ${idToken != null ? "Firebase idToken" : "googleIdToken"}, len=${authHeaderValue?.length}');
      print('[OTP-AUDIT] calling repo.updatePhone(payload keys=${payload.keys.toList()})');
      final response = await repo.updatePhone(
        payload,
        authHeader: authHeaderValue,
      );
      print('[OTP-AUDIT] updatePhone response: success=${response.success} token=${response.token != null ? "present" : "NULL"} message=${response.message}');
      if (!mounted) {
        print('[OTP-AUDIT] NOT mounted after updatePhone — aborting');
        return;
      }

      if (response.success == true) {
        print('[OTP-AUDIT] SUCCESS path — saving tokens and navigating');
        await SecureStorage.clearGoogleIdToken();

        final newToken = response.token ?? "";
        final newRefreshToken = response.refreshToken ?? "";
        if (newToken.isNotEmpty) {
          await SecureStorage.saveToken(newToken);
          await sl.authService.saveToken(newToken);
          final uid = extractUserIdFromAccessJwt(newToken);
          if (uid != null && uid.isNotEmpty) {
            await SecureStorage.saveUserId(uid);
            await sl.authService.saveUserId(uid);
          }
        }
        if (newRefreshToken.isNotEmpty) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
          await sl.authService.saveRefreshToken(newRefreshToken);
        }

        await UserLocalData.setNeedsBasicProfile(true);

        AppPopUp.showToast(message: response.message ?? 'Phone verified');
        print('[OTP-AUDIT] navigating to basicProfileView');
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.basicProfileView,
        );
      } else {
        print('[OTP-AUDIT] FAILED path — clearing tokens, going to signInView');
        await SecureStorage.clearAll();
        await sl.authService.logout();
        await SecureStorage.clearGoogleIdToken();
        AppPopUp.showToast(
          message:
              response.message ??
              'Phone verified in Firebase but profile update failed. Please sign in again.',
        );
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.signInView,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('[OTP-AUDIT] FirebaseAuthException: code=${e.code} message=${e.message}');
      if (mounted && phoneAuth.userFacingMessage != null) {
        AppPopUp.showToast(message: phoneAuth.userFacingMessage!);
      }
    } catch (e) {
      print('[OTP-AUDIT] CATCH: ${e.runtimeType}: $e');
      if (mounted) {
        AppPopUp.showToast(message: e.toString());
      }
    } finally {
      print('[OTP-AUDIT] finally: mounted=$mounted');
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
