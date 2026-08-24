import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/services/social_login/social_login.dart';
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
  bool _didAutoComplete = false;
  FirebasePhoneAuthService? _phoneAuth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<FirebasePhoneAuthService>();
    if (!identical(_phoneAuth, next)) {
      _phoneAuth?.removeListener(_onPhoneAuthChanged);
      _phoneAuth = next;
      _phoneAuth!.addListener(_onPhoneAuthChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onPhoneAuthChanged();
    });
  }

  void _onPhoneAuthChanged() {
    if (!mounted) return;
    final phoneAuth = _phoneAuth;
    if (phoneAuth == null) return;
    if (_didAutoComplete) return;
    if (!phoneAuth.isAutoVerified) return;
    if (_isVerifying || _syncingBackend) return;
    _didAutoComplete = true;
    _completeAfterFirebase(smsCode: '');
  }

  String _nationalDigits(String? e164) {
    if (e164 == null || e164.isEmpty) return '';
    final d = e164.replaceAll(RegExp(r'\D'), '');
    if (d.length >= 10) return d.substring(d.length - 10);
    return d;
  }

  /// Shared Google / phone backend sync after Firebase has a phone user.
  Future<void> _completeAfterFirebase({required String smsCode}) async {
    if (_isVerifying) return;
    final phoneAuth = context.read<FirebasePhoneAuthService>();
    final auto = phoneAuth.isAutoVerified;
    if (!auto && smsCode.length != 6) return;
    setState(() => _isVerifying = true);
    print('[OTP-AUDIT] _completeAfterFirebase start auto=$auto code.len=${smsCode.length}');
    try {
      print('[OTP-AUDIT] calling verifySmsCode...');
      await phoneAuth.verifySmsCode(smsCode);
      print('[OTP-AUDIT] verifySmsCode returned. mounted=$mounted');
      if (!mounted) {
        print('[OTP-AUDIT] NOT mounted — aborting');
        return;
      }

      final user = FirebaseAuth.instance.currentUser ??
          phoneAuth.lastUserCredential?.user;
      print('[OTP-AUDIT] currentUser uid=${user?.uid} phoneNumber=${user?.phoneNumber}');
      final idToken = await user?.getIdToken(true);
      print('[OTP-AUDIT] idToken obtained: ${idToken != null ? 'len=${idToken.length}' : 'NULL'}');

      if (idToken == null) {
        print('[OTP-AUDIT] idToken is NULL — throwing');
        throw Exception(
          phoneAuth.userFacingMessage ??
              'Failed to retrieve Firebase ID token. Please request a new code.',
        );
      }

      setState(() => _syncingBackend = true);
      final repo = context.read<Repository>();
      final national = _nationalDigits(
        user?.phoneNumber ?? phoneAuth.phoneE164,
      );
      print('[OTP-AUDIT] phone national=$national');

      // Check if this is a Google sign-in flow requiring phone
      final googleIdToken = await SecureStorage.getGoogleIdToken();
      print('[OTP-AUDIT] googleIdToken from storage: ${googleIdToken != null ? 'len=${googleIdToken.length}' : 'NULL'}');

      if (googleIdToken != null && googleIdToken.isNotEmpty) {
        final googlePayload = decodeJwtPayload(googleIdToken);
        final googleEmail = googlePayload?['email']?.toString() ?? '';
        print('[OTP-AUDIT] googleEmail from JWT=$googleEmail');
      }

      final storedGoogleToken = googleIdToken;
      final bool isGoogleFlow =
          storedGoogleToken != null && storedGoogleToken.isNotEmpty;

      if (isGoogleFlow) {
        // Google flow: go directly to /auth/verify-otp. Pass the Google ID
        // token so the backend can find the Google-created user (which has
        // no phone in DB) by email and attach the verified phone to it.
        print('[OTP-AUDIT] Google flow — calling /auth/verify-otp with googleIdToken');

        final verifyData = <String, String>{
          'phone': national,
          'idToken': idToken,
          'googleIdToken': storedGoogleToken,
        };
        final verifyResult = await repo.verifyOtpSignup(verifyData);
        print('[OTP-AUDIT] verifyOtp result: success=${verifyResult.success} token=${verifyResult.token != null ? "present" : "NULL"} message=${verifyResult.message}');

        if (!mounted) {
          print('[OTP-AUDIT] NOT mounted after verifyOtp — aborting');
          return;
        }

        if (verifyResult.success == true) {
          print('[OTP-AUDIT] SUCCESS path — saving tokens and routing from getUser');
          await SecureStorage.clearGoogleIdToken();
          await _persistOtpTokens(verifyResult);
          AppPopUp.showToast(message: verifyResult.message ?? 'Phone verified');
          await SocialLoginService().routeAfterAuthSession();
        } else {
          print('[OTP-AUDIT] verifyOtp FAILED — ${verifyResult.message}');
          AppPopUp.showToast(
            message: verifyResult.message ?? 'Phone verification failed. Please try again.',
          );
        }
      } else {
        // Non-Google flow: skip /auth/signup (requires email which we don't
        // have for phone-only signup). Go straight to /auth/verify-otp which
        // creates the user on the backend when phone is verified.
        print('[OTP-AUDIT] Non-Google flow — calling /auth/verify-otp directly');
        final verifyData = <String, String>{
          'phone': national,
          'idToken': idToken,
        };
        final verifyResult = await repo.verifyOtpSignup(verifyData);
        print('[OTP-AUDIT] verifyOtp result: success=${verifyResult.success} token=${verifyResult.token != null ? "present" : "NULL"} message=${verifyResult.message}');

        if (!mounted) {
          print('[OTP-AUDIT] NOT mounted after verifyOtp — aborting');
          return;
        }

        if (verifyResult.success == true) {
          print('[OTP-AUDIT] SUCCESS path — saving tokens and routing from getUser');
          await _persistOtpTokens(verifyResult);
          AppPopUp.showToast(message: verifyResult.message ?? 'Phone verified');
          await SocialLoginService().routeAfterAuthSession();
        } else {
          print('[OTP-AUDIT] verifyOtp FAILED — ${verifyResult.message}');
          AppPopUp.showToast(
            message: verifyResult.message ?? 'Phone verification failed. Please try again.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('[OTP-AUDIT] FirebaseAuthException: code=${e.code} message=${e.message}');
      if (mounted) {
        AppPopUp.showToast(
          message: phoneAuth.userFacingMessage ??
              e.message ??
              'Phone verification failed. Please try again.',
        );
      }
    } catch (e) {
      print('[OTP-AUDIT] CATCH: ${e.runtimeType}: $e');
      if (mounted) {
        AppPopUp.showToast(
          message: phoneAuth.userFacingMessage ?? e.toString(),
        );
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

  Future<void> _persistOtpTokens(CommonResponseModel verifyResult) async {
    final newToken = verifyResult.token ?? '';
    final newRefreshToken = verifyResult.refreshToken ?? '';
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
  }

  @override
  void dispose() {
    _phoneAuth?.removeListener(_onPhoneAuthChanged);
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
                            phoneAuth.isAutoVerified
                                ? 'Phone verified automatically. Finishing signup…'
                                : 'Enter the 6-digit code sent to $masked',
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
                              if (!busy) _completeAfterFirebase(smsCode: v);
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
                                      _didAutoComplete = false;
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
