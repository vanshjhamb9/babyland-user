import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import '../../data/storage/user_local_data.dart';
import '../../navbar/pregnancy/navbar.dart';
import '../../constants/flow.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    routing();
  }

  routing() async {
    bool isFirstTime = UserPreference.getIsFirstTime() ?? true;
    final id = await SecureStorage.getUserId();
    final token = await SecureStorage.getToken();
    final step = await UserLocalData.getStep(); // Use UserPreference

    pt("token... $token");
    pt("id... $id");
    pt("step... $step");

    await Future.delayed(const Duration(seconds: 3));

    if (isFirstTime) {
      Navigator.pushNamedAndRemoveUntil(
        navigatorKey.currentContext!,
        AppRoutes.onboardingView,
            (route) => false,
      );
      return;
    }

    if (token != null && token.isNotEmpty) {
      // Check if we should show the stage screen (once a month)
      final shouldShowStageScreen = await UserLocalData.shouldShowStageScreen(); // Use UserPreference

      if (shouldShowStageScreen) {
        // Show stage selection screen and save timestamp
        await UserLocalData.saveLastStageScreenShown(); // Use UserPreference
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          AppRoutes.stagesView,
              (route) => false,
          arguments: {"fromLoginScreen": true, "back": false},
        );
      } else {
        // Skip stage screen, go directly to appropriate home screen based on step
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
              final isPregnancySetupComplete = await UserLocalData.isPregnancySetupComplete();
              if (isPregnancySetupComplete) {
                Navigator.pushAndRemoveUntil(
                  navigatorKey.currentContext!,
                  MaterialPageRoute(
                    builder: (context) => const NavbarView(flow: FlowType.pregnancy),
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
              final isSetupComplete = await UserLocalData.isPostPregnancySetupComplete();
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
            // If step is unknown, show stage screen
              await UserLocalData.saveLastStageScreenShown();
              Navigator.pushNamedAndRemoveUntil(
                navigatorKey.currentContext!,
                AppRoutes.stagesView,
                    (route) => false,
                arguments: {"fromLoginScreen": true, "back": false},
              );
          }
        } else {
          // No step saved, show stage screen
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
      body: Center(
        child:CustomImage(path: ImageConstants.splash) ,
      ),
    );
  }
}

