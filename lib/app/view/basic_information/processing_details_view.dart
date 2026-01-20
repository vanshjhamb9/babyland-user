import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/circular_indicator.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final index = args?["index"];
      print("Received index: $index");

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        switch (index) {
          case 0:
          // Pregnancy
            Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
            break;
          case 1:
          // Pre-pregnancy
            Navigator.pushNamed(context, AppRoutes.pregnancyView);
            break;
          case 2:
          // Post-pregnancy
            Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
            break;
          default:
            Navigator.pushNamed(context, AppRoutes.signInView);
        }
      });
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
