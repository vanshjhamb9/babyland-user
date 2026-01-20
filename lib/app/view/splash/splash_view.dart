import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

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
     // await SecureStorage.clearToken();
     // await SecureStorage.saveToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoiNjkxMzhlZWJjOGUyNTJkMzJiNGRkZDg0In0sImlhdCI6MTc2MzEzNzY5OX0.Mr0iafS-ffiEFvB60JrRg0SmrUGTd2fhANOxZFDNELQ");
     final id = await SecureStorage.getUserId();
    final token = await SecureStorage.getToken();
    pt("token... $token");
    pt("token... $id");

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
      Navigator.pushNamedAndRemoveUntil(
        navigatorKey.currentContext!,
        AppRoutes.stagesView,
            (route) => false,
        arguments: {"fromLoginScreen": true,"back":false},
      );
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

