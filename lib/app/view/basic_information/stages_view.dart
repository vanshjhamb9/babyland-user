import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/storage/user_local_data.dart';

class StagesView extends StatefulWidget {
  final bool? fromProfile;
  final bool? isUpdateFlow;

  const StagesView({
    super.key,
    this.fromProfile,
    this.isUpdateFlow,
  });

  @override
  State<StagesView> createState() => _StagesViewState();
}

class _StagesViewState extends State<StagesView> {
  final List<Map<String,String>> stagesList = [
    {"title":"Pre-Pregnancy","image":ImageConstants.prePregnancy1},
    {"title":"Pregnancy","image":ImageConstants.pregnancy},
    {"title":"Post-Pregnancy","image":ImageConstants.postPregnancy},
  ];

  bool fromLoginScreen = false;
  late bool back;
  int? selectedStageIndex;

  @override
  void initState() {
    super.initState();
    back = widget.fromProfile ?? false;
    _loadSelectedStage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('fromLoginScreen')) {
        setState(() {
          fromLoginScreen = args['fromLoginScreen'] ?? false;
          back = args['back'] ?? false;
        });
      }
      pt("fromLoginScreen--------------->>>> $fromLoginScreen");
      pt("back--------------->>>> $back");
      pt("fromprofile--------------->>>> ${widget.fromProfile}");
    },);
  }

  Future<void> _loadSelectedStage() async {
    // 1. Start with local storage
    final step = await UserLocalData.getStep();
    if (step != null && step.isNotEmpty) {
      setState(() {
        selectedStageIndex = int.tryParse(step);
      });
    }
    
    // 2. Immediately prefer fresh backend data if available in the provider
    final userProvider = context.read<GetUserProvider>();
    final backendUser = userProvider.userData?.data?.user?.user;
    if (backendUser != null) {
      final cType = backendUser.cycleType;
      int? backendIndex;
      if (cType == "pregnancy") backendIndex = 1;
      else if (cType == "post_pregnancy") backendIndex = 2;
      else if (cType == "regular" || cType == "irregular" || cType == "prepregnancy") backendIndex = 0;
      
      if (backendIndex != null) {
        setState(() {
          selectedStageIndex = backendIndex;
        });
        pt("StagesView initialized from backend state: $backendIndex ($cType)");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Column(
          children: [
            CustomAppBar(
              isLeading: back,
              centerTitle: true,
              title: Text(
                "What Stage are you In ?",
                style: AppFontStyle.text_20_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              backgroundClr: AppColors.transparent,
            ),
            ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final isSelected = selectedStageIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GestureDetector(
                    onTap: () async {
                      // Save timestamp when user makes a selection
                      await UserLocalData.saveLastStageScreenShown();
                      
                      // Sync with backend (updates local step and cycleType)
                      await context.read<GetUserProvider>().updateUserStage(index);

                      // Update the selected stage visually
                      setState(() {
                        selectedStageIndex = index;
                      });

                      if (fromLoginScreen) {
                        switch (index) {
                          case 0: // Pre-Pregnancy
                            Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
                            break;

                          case 1: // Pregnancy
                            Navigator.pushNamed(context, AppRoutes.pregnancyView);
                            break;

                          case 2: // Post-Pregnancy
                            Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
                            break;
                        }
                      }

                      else if (widget.fromProfile == true) {
                        // Check if this is an update flow
                        if (widget.isUpdateFlow == true) {
                          // Update local data
                          await UserLocalData.saveStep(index.toString());

                          // Show a snackbar to confirm update
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stage updated successfully!'),
                              backgroundColor: AppColors.buttonClr1,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to the respective screen based on selection
                          // Using pushNamedAndRemoveUntil to clear stack and switch mode
                          switch (index) {
                            case 0: // Pre-Pregnancy
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.navbarPrePregancyView,
                                    (route) => false,
                              );
                              break;

                            case 1: // Pregnancy
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.pregnancyView,
                                    (route) => false,
                              );
                              break;

                            case 2: // Post-Pregnancy
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.combinedBabyDetailScreen,
                                    (route) => false,
                              );
                              break;
                          }
                        } else {
                          // Original flow - navigate and remove all routes
                          switch (index) {
                            case 0: // Pre-Pregnancy
                              Navigator.pushNamed(
                                context,
                                AppRoutes.navbarPrePregancyView,
                              );
                              break;

                            case 1: // Pregnancy
                              Navigator.pushNamed(
                                context,
                                AppRoutes.pregnancyView,
                              );
                              break;

                            case 2: // Post-Pregnancy
                              Navigator.pushNamed(
                                context,
                                AppRoutes.combinedBabyDetailScreen,
                              );
                              break;
                          }
                        }
                      }

                      else {
                        // Default flow → Send index to next screen
                        Navigator.pushNamed(
                          context,
                          AppRoutes.processingDetailsView,
                          arguments: {"index": index},
                        );
                      }
                    },
                    child: Container(
                        height: 105,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.buttonClr1.withOpacity(0.1)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.buttonClr1
                                : AppColors.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: index == 0
                                  ? EdgeInsets.symmetric(vertical: 16, horizontal: 8)
                                  : EdgeInsets.symmetric(vertical: 8.0),
                              child: CustomImage(path: stagesList[index]['image'] ?? ""),
                            ),
                            Text(
                              stagesList[index]['title'] ?? "",
                              style: AppFontStyle.text_15_400(
                                  color: isSelected
                                      ? AppColors.buttonClr1
                                      : AppColors.textClr,
                                  fontFamily: AppFontFamily.gilroySemiBold
                              ),
                            ),
                            Spacer(),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.arrow_forward_ios,
                              size: isSelected ? 24 : 16,
                              color: isSelected
                                  ? AppColors.buttonClr1
                                  : AppColors.textClr,
                            ),
                            SizedBox(width: 16),
                          ],
                        )
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: 15),
              itemCount: stagesList.length,
            ),
          ],
        ),
      ),
    );
  }
}