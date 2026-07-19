import 'dart:async';

import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
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
      pt(
        "token... ${token != null && token.isNotEmpty ? 'Token exists' : 'No token'}",
      );
      pt("id... $uid");
      pt("step... $step");
      pt("isAuthenticated... ${sl.authService.isAuthenticated}");
    }

    if (isFirstTime) {
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
      final navCtx = navigatorKey.currentContext;
      if (navCtx != null && navCtx.mounted) {
        try {
          await navCtx.read<GetUserProvider>().getUser();
          final after = navigatorKey.currentContext;
          if (after != null && after.mounted) {
            final userPhone = after
                .read<GetUserProvider>()
                .userData
                ?.data
                ?.user
                ?.user
                ?.phone
                ?.trim();
            final needsPhone = await UserLocalData.needsPhoneProfile();
            if (needsPhone && (userPhone == null || userPhone.isEmpty)) {
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

            final needsBasicProfile = await UserLocalData.needsBasicProfile();
            if (needsBasicProfile) {
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
          }
        } catch (e) {
          if (kDebugMode) {
            pt('Splash profile prefetch: $e');
          }
        }
      }

      final shouldShowStageScreen = await UserLocalData.shouldShowStageScreen();

      if (!mounted) return;
      setState(() => _checkingAuth = false);

      if (shouldShowStageScreen) {
        await UserLocalData.saveLastStageScreenShown();
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          AppRoutes.stagesView,
          (route) => false,
          arguments: {"fromLoginScreen": true, "back": false},
        );
      } else {
        if (step != null && step.isNotEmpty) {
          switch (step) {
            case "0":
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
                Navigator.pushAndRemoveUntil(
                  navigatorKey.currentContext!,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NavbarView(flow: FlowType.pregnancy),
                  ),
                  (route) => false,
                );
              } else {
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
                Navigator.pushNamedAndRemoveUntil(
                  navigatorKey.currentContext!,
                  AppRoutes.postPregnancyNavbarView,
                  (route) => false,
                );
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  navigatorKey.currentContext!,
                  AppRoutes.combinedBabyDetailScreen,
                  (route) => false,
                );
              }
              break;
            default:
              await UserLocalData.saveLastStageScreenShown();
              Navigator.pushNamedAndRemoveUntil(
                navigatorKey.currentContext!,
                AppRoutes.stagesView,
                (route) => false,
                arguments: {"fromLoginScreen": true, "back": false},
              );
          }
        } else {
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
