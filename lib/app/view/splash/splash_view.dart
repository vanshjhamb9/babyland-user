import 'dart:async';

import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';
import 'package:babyland/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navbar/pregnancy/navbar.dart';
import '../../constants/flow.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await routing();
        await _resumePendingConsultationPaymentIfNeeded();
        await _resumePendingSubscriptionIfNeeded();
      }());
    });
  }

  Future<void> _resumePendingConsultationPaymentIfNeeded() async {
    final token =
        await sl.authService.getToken() ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    final navCtx = navigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;

    final checkout = navCtx.read<ConsultationCheckoutController>();
    final pending = await checkout.restorePendingConsultation();
    if (!navCtx.mounted) return;
    if (pending == null) return;

    pt(
      '[PROJECTION_POLL] Resuming killed-app consultation payment '
      'merchantTransactionId=${pending.merchantTransactionId} '
      'consultationId=${pending.consultationId ?? "(none)"}',
    );
    Navigator.pushNamed(
      navCtx,
      AppRoutes.consultationPaymentVerification,
      arguments: pending.toRouteArguments(),
    );
  }

  Future<void> _resumePendingSubscriptionIfNeeded() async {
    final token =
        await sl.authService.getToken() ?? await SecureStorage.getToken();
    if (token == null || token.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 320));
    final navCtx = navigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;

    final coord = navCtx.read<SubscriptionPaymentCoordinator>();
    if (coord.state != SubscriptionPaymentState.pendingVerification) return;

    pt(
      '[SUBSCRIPTION_PAYMENT] Resuming pending subscription verification from cold start',
    );
    Navigator.pushNamed(navCtx, AppRoutes.subscriptionScreen);
  }

  Future<void> routing() async {
    bool isFirstTime = UserPreference.getIsFirstTime() ?? true;

    await sl.authService.checkAuthState();

    final token =
        await sl.authService.getToken() ?? await SecureStorage.getToken();
    final step = await UserLocalData.getStep();

    if (kDebugMode) {
      final uid =
          await sl.authService.getUserId() ?? await SecureStorage.getUserId();
      pt('[SPLASH-AUDIT] token... ${token != null && token.isNotEmpty ? 'Token exists (${token.length} chars)' : 'No token'}');
      pt('[SPLASH-AUDIT] token prefix: ${token != null && token.isNotEmpty ? token.substring(0, token.length > 30 ? 30 : token.length) : "(none)"}');
      pt('[SPLASH-AUDIT] id... $uid');
      pt('[SPLASH-AUDIT] step... $step');
      pt('[SPLASH-AUDIT] isAuthenticated... ${sl.authService.isAuthenticated}');
      pt('[SPLASH-AUDIT] isFirstTime... $isFirstTime');
    }

    if (isFirstTime) {
      pt('[SPLASH-AUDIT] → FIRST TIME → onboardingView');
      if (!mounted) return;
      setState(() => _checkingAuth = false);
      Navigator.pushNamedAndRemoveUntil(
        navigatorKey.currentContext!,
        AppRoutes.onboardingView,
        (route) => false,
      );
      return;
    }

    if (token != null && token.isNotEmpty) {
      pt('[SPLASH-AUDIT] Token present. Calling getUser()...');
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null && navCtx.mounted) {
        try {
          await navCtx.read<GetUserProvider>().getUser();
          pt('[SPLASH-AUDIT] getUser() completed. Checking result...');

          final after = navigatorKey.currentContext;
          if (after != null && after.mounted) {
            final userProvider = after.read<GetUserProvider>();
            final userData = userProvider.userData;
            pt('[SPLASH-AUDIT] userData status: ${userData?.status}');
            pt('[SPLASH-AUDIT] userData message: ${userData?.message}');
            pt('[SPLASH-AUDIT] userData data: ${userData?.data}');
            pt('[SPLASH-AUDIT] userData success: ${userData?.data?.success}');

            final userPhone = userData?.data?.user?.user?.phone?.trim();
            pt('[SPLASH-AUDIT] userPhone: $userPhone');

            final needsPhone = await UserLocalData.needsPhoneProfile();
            final needsBasic = await UserLocalData.needsBasicProfile();
            pt('[SPLASH-AUDIT] needsPhoneProfile: $needsPhone');
            pt('[SPLASH-AUDIT] needsBasicProfile: $needsBasic');

            if (needsPhone && (userPhone == null || userPhone.isEmpty)) {
              pt('[SPLASH-AUDIT] → needsPhone=true & no phone → profileUpdateScreen');
              final target = navigatorKey.currentContext;
              if (target != null && target.mounted) {
                if (!mounted) return;
                setState(() => _checkingAuth = false);
                Navigator.pushNamedAndRemoveUntil(
                  target,
                  AppRoutes.profileUpdateScreen,
                  (route) => false,
                );
                return;
              }
            }

            if (needsBasic) {
              pt('[SPLASH-AUDIT] → needsBasic=true → basicInfoView');
              final target = navigatorKey.currentContext;
              if (target != null && target.mounted) {
                if (!mounted) return;
                setState(() => _checkingAuth = false);
                Navigator.pushNamedAndRemoveUntil(
                  target,
                  AppRoutes.basicInfoView,
                  (route) => false,
                );
                return;
              }
            }

            pt('[SPLASH-AUDIT] getUser succeeded, no onboarding flags → fall through to stage/dashboard routing');
          }
        } catch (e) {
          pt('[SPLASH-AUDIT] ⚠️ getUser() THREW: $e');
        }
      } else {
        pt('[SPLASH-AUDIT] ⚠️ navCtx is null or not mounted');
      }

      // Check if getUser() failed — if so, the interceptor may have cleared
      // the session. Log heavily but still fall through so we can audit what
      // the existing routing does.
      final authCheckCtx = navigatorKey.currentContext;
      if (authCheckCtx != null && authCheckCtx.mounted) {
        final userData = authCheckCtx.read<GetUserProvider>().userData;
        pt('[SPLASH-AUDIT] Post-try check: userData.status=${userData?.status}');
        if (userData == null || userData.status == ApiStatus.ERROR) {
          final currentToken = await SecureStorage.getToken();
          final authServiceToken = await sl.authService.getToken();
          pt('[SPLASH-AUDIT] ⚠️ getUser FAILED. SecureStorage token: ${currentToken != null && currentToken.isNotEmpty ? "present" : "NULL"}. AuthService token: ${authServiceToken != null && authServiceToken.isNotEmpty ? "present" : "NULL"}');

          if (currentToken == null || currentToken.isEmpty) {
            pt('[SPLASH-AUDIT] → Token cleared by interceptor. signInView should already be pushed. Returning.');
            return;
          }
          // Token still exists — log but allow fall-through for audit
          pt('[SPLASH-AUDIT] → Token STILL present despite getUser failure. Will fall through (audit mode).');
        }
      }

      final shouldShowStageScreen = await UserLocalData.shouldShowStageScreen();
      pt('[SPLASH-AUDIT] shouldShowStageScreen: $shouldShowStageScreen');

      if (!mounted) return;
      setState(() => _checkingAuth = false);

      if (shouldShowStageScreen) {
        pt('[SPLASH-AUDIT] → stagesView (stageScreen)');
        await UserLocalData.saveLastStageScreenShown();
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          AppRoutes.stagesView,
          (route) => false,
          arguments: {"fromLoginScreen": true, "back": false},
        );
      } else {
        pt('[SPLASH-AUDIT] step=$step → routing to step-based screen');
        if (step != null && step.isNotEmpty) {
          switch (step) {
            case "0":
              pt('[SPLASH-AUDIT] → navbarPrePregancyView');
              Navigator.pushNamedAndRemoveUntil(
                navigatorKey.currentContext!,
                AppRoutes.navbarPrePregancyView,
                (route) => false,
              );
              break;
            case "1":
              final isPregnancySetupComplete =
                  await UserLocalData.isPregnancySetupComplete();
              if (isPregnancySetupComplete) {
                pt('[SPLASH-AUDIT] → NavbarView(pregnancy)');
                Navigator.pushAndRemoveUntil(
                  navigatorKey.currentContext!,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NavbarView(flow: FlowType.pregnancy),
                  ),
                  (route) => false,
                );
              } else {
                pt('[SPLASH-AUDIT] → pregnancyView');
                Navigator.pushNamedAndRemoveUntil(
                  navigatorKey.currentContext!,
                  AppRoutes.pregnancyView,
                  (route) => false,
                );
              }
              break;
            case "2":
              final isSetupComplete =
                  await UserLocalData.isPostPregnancySetupComplete();
              if (isSetupComplete) {
                pt('[SPLASH-AUDIT] → postPregnancyNavbarView');
                Navigator.pushNamedAndRemoveUntil(
                  navigatorKey.currentContext!,
                  AppRoutes.postPregnancyNavbarView,
                  (route) => false,
                );
              } else {
                pt('[SPLASH-AUDIT] → combinedBabyDetailScreen');
                Navigator.pushNamedAndRemoveUntil(
                  navigatorKey.currentContext!,
                  AppRoutes.combinedBabyDetailScreen,
                  (route) => false,
                );
              }
              break;
            default:
              pt('[SPLASH-AUDIT] → stagesView (default step)');
              await UserLocalData.saveLastStageScreenShown();
              Navigator.pushNamedAndRemoveUntil(
                navigatorKey.currentContext!,
                AppRoutes.stagesView,
                (route) => false,
                arguments: {"fromLoginScreen": true, "back": false},
              );
          }
        } else {
          pt('[SPLASH-AUDIT] → stagesView (no step)');
          await UserLocalData.saveLastStageScreenShown();
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            AppRoutes.stagesView,
            (route) => false,
            arguments: {"fromLoginScreen": true, "back": false},
          );
        }
      }
    } else {
      pt('[SPLASH-AUDIT] → No token → letsGetStartedView');
      if (!mounted) return;
      setState(() => _checkingAuth = false);
      Navigator.pushNamedAndRemoveUntil(
        navigatorKey.currentContext!,
        AppRoutes.letsGetStartedView,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: CustomImage(path: ImageConstants.splash)),
          if (_checkingAuth)
            const Positioned(
              bottom: 80,
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }
}
