import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/circular_indicator.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

import '../../data/storage/user_local_data.dart';
import '../../widgets/print.dart';

class ProcessingDetailsView extends StatefulWidget {
  const ProcessingDetailsView({super.key});

  @override
  State<ProcessingDetailsView> createState() => _ProcessingDetailsViewState();
}

class _ProcessingDetailsViewState extends State<ProcessingDetailsView> {

  int? index;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final index = args?["index"];
      print("Received index: $index");

      // Check if we should show the stage screen
      final shouldShow = await UserLocalData.shouldShowStageScreen();

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (shouldShow) {
        // Show stage selection screen and save the timestamp
        await UserLocalData.saveLastStageScreenShown();
        Navigator.pushNamed(context, AppRoutes.stagesView, arguments: {
          'fromLoginScreen': true,
          'back': false,
        });
      } else {
        // Skip stage screen, go directly to home based on saved preference
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.navbarPrePregancyView);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRoutes.pregnancyView);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.combinedBabyDetailScreen);
            break;
          default:
            Navigator.pushReplacementNamed(context, AppRoutes.signInView);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Column(
            children: [
              SizedBox(height: 60),
              Text('We’re processing your details based on your inputs.',
              maxLines: 3,
              textAlign: TextAlign.center,
              style: AppFontStyle.text_28_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr),
              ),
              SizedBox(height: 120),
              Center(
                child: CircularPercentageIndicator(
                  percentage: 65,
                  size: 150,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                ),

              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(child: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 15),
          child: Text("This will just take a moment.",
            style:  AppFontStyle.text_14_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular),
            textAlign: TextAlign.center,
          ),
        ),
      )),
    );
  }
}
