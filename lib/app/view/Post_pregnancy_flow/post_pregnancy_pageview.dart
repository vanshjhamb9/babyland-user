import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/container.dart';
import '../../widgets/print.dart';
import 'package:babyland/main.dart';
import '../../data/storage/user_local_data.dart';
import 'baby_detail_view.dart';
import 'post_pregnancy_view.dart';

class CombinedBabyDetailScreen extends StatefulWidget {
  const CombinedBabyDetailScreen({super.key});

  @override
  State<CombinedBabyDetailScreen> createState() =>
      _CombinedBabyDetailScreenState();
}

class _CombinedBabyDetailScreenState extends State<CombinedBabyDetailScreen> {
  final PageController _pageController = PageController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingData();
  }

  Future<void> _checkExistingData() async {
    // First check local flag (safe if secure storage ciphertext is stale/corrupt).
    bool isComplete = false;
    try {
      isComplete = await UserLocalData.isPostPregnancySetupComplete();
    } catch (e, stackTrace) {
      pt('Post-pregnancy setup flag read failed: $e\n$stackTrace');
    }
    if (isComplete) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.postPregnancyNavbarView,
        );
      }
      return;
    }

    // Existing tracker or recovery log means this account already finished setup.
    try {
      final response = await repository.babygrowthsDetails();
      if (response.success == true && response.tracker != null) {
        await _goToPostPregnancyDashboard();
        return;
      }
    } catch (e, stackTrace) {
      pt("Error checking babygrowths: $e\n$stackTrace");
    }

    try {
      final recovery = await repository.getRecoveryTask({
        "date": DateTime.now().toIso8601String().split('T').first,
      });
      final tasks = recovery.tasks;
      final completed = int.tryParse(tasks?.completedTasks ?? '') ?? 0;
      final hasExistingLog = recovery.success == true &&
          tasks != null &&
          (completed > 0 ||
              (tasks.logDate?.isNotEmpty ?? false) ||
              (tasks.mood?.isNotEmpty ?? false) ||
              (tasks.feedings?.isNotEmpty ?? false));
      if (hasExistingLog) {
        await _goToPostPregnancyDashboard();
        return;
      }
    } catch (e, stackTrace) {
      pt("Error checking recovery tasks: $e\n$stackTrace");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _goToPostPregnancyDashboard() async {
    await UserLocalData.savePostPregnancySetupComplete();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.postPregnancyNavbarView,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.buttonClr1),
        ),
      );
    }

    return ChangeNotifierProvider<PostpregnancyProvider>(
      create: (context) => PostpregnancyProvider(),
      child: Scaffold(
        appBar: CustomAppBar(
          centerTitle: true,
          title: Consumer<PostpregnancyProvider>(
            builder: (context, pageProvider, _) {
              return Text(
                pageProvider.currentIndex == 0
                    ? "Delivery Details"
                    : "Baby Details",
                style: AppFontStyle.text_20_400(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              );
            },
          ),
        ),
        body: Consumer<PostpregnancyProvider>(
          builder: (context, pageProvider, _) {
            return AppContainer(
              gradient: AppColors.backGroundColor,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppContainer(
                          height: 6,
                          width: 25,
                          radius: 100,
                          gradient: AppColors.buttonClr,
                        ),
                        const SizedBox(width: 9),
                        AppContainer(
                          height: 6,
                          width: 25,
                          radius: 100,
                          gradient: pageProvider.currentIndex == 1
                              ? AppColors.buttonClr
                              : LinearGradient(
                                  colors: [
                                    AppColors.grey.withAlpha(120),
                                    AppColors.grey.withAlpha(100),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics:
                            const NeverScrollableScrollPhysics(), // Prevent manual swiping
                        onPageChanged: (index) {
                          pageProvider.changeIndex(index);
                        },
                        children: const [PostPregnancyView(), BabyDetailView()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<PostpregnancyProvider>(
          builder: (context, pageProvider, _) {
            return AppContainer(
              color: AppColors.white,
              radius: 100,
              child: AppContainer(
                gradient: AppColors.backGroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Button(
                    onTap: () async {
                      if (pageProvider.currentIndex == 0) {
                        if (pageProvider.dateController.text.isEmpty) {
                          AppPopUp.showToast(
                            message: "Please select date.",
                            lineColor: AppColors.red,
                          );
                        } else if (pageProvider.selectedDeliveryType.isEmpty) {
                          AppPopUp.showToast(
                            message: "Please select delivery type.",
                            lineColor: AppColors.red,
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else if (pageProvider.currentIndex == 1) {
                        if (pageProvider.babyNameController.text.isEmpty) {
                          AppPopUp.showToast(
                            message: "Please enter your baby name.",
                            lineColor: AppColors.red,
                          );
                        } else if (pageProvider.dobController.text.isEmpty) {
                          AppPopUp.showToast(
                            message: "Please select your baby birth date.",
                            lineColor: AppColors.red,
                          );
                        } else if (pageProvider.selectedGender?.isEmpty ??
                            true) {
                          AppPopUp.showToast(
                            message: "Please select baby gender.",
                            lineColor: AppColors.red,
                          );
                        } else {
                          pageProvider.pregnancyInfo();
                          // Navigator.pushNamed(context, AppRoutes.postPregnancyNavbarView);
                        }
                      }
                    },
                    height: 56,
                    child:
                        pageProvider.postPregnancyInfoApiData?.status ==
                            ApiStatus.LOADING
                        ? customLoading()
                        : Text(
                            pageProvider.currentIndex == 0
                                ? "Continue"
                                : "Go to dashboard",
                            style: AppFontStyle.text_16_400(
                              fontFamily: AppFontFamily.gilroyBold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
