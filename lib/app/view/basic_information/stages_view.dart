import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/stage_accordion_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/storage/user_local_data.dart';

class StagesView extends StatefulWidget {
  final bool? fromProfile;
  final bool? isUpdateFlow;

  const StagesView({super.key, this.fromProfile, this.isUpdateFlow});

  @override
  State<StagesView> createState() => _StagesViewState();
}

class _StagesViewState extends State<StagesView> {
  late final List<StageAccordionData> _stages;

  bool fromLoginScreen = false;
  late bool back;
  int? selectedStageIndex;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    _stages = [
      StageAccordionData(
        title: 'Pre-Pregnancy',
        compactImagePadding: true,
        imagePath: ImageConstants.prePregnancy1,
        description:
            'Track your cycle, ovulation, and daily wellness while you plan for a baby.',
        features: const [
          'Cycle and period calendar with predictions',
          'Daily logs for symptoms and mood',
          'Tips tailored to your pre-conception journey',
        ],
      ),
      StageAccordionData(
        title: 'Pregnancy',
        imagePath: ImageConstants.pregnancy,
        description:
            'Follow each week of pregnancy with guidance, reminders, and health insights.',
        features: const [
          'Week-by-week development and milestones',
          'Appointments and reminders in one place',
          'Community and expert content for every trimester',
        ],
      ),
      StageAccordionData(
        title: 'Post-Pregnancy',
        imagePath: ImageConstants.postPregnancy,
        description:
            'Support recovery, baby growth, and routines after your little one arrives.',
        features: const [
          'Baby growth tracking and development notes',
          'Postpartum wellness and scheduling tools',
          'Resources for feeding, sleep, and care',
        ],
      ),
    ];

    back = widget.fromProfile ?? false;
    _loadSelectedStage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('fromLoginScreen')) {
        setState(() {
          fromLoginScreen = args['fromLoginScreen'] ?? false;
          back = args['back'] ?? false;
        });
      }
      pt("fromLoginScreen--------------->>>> $fromLoginScreen");
      pt("back--------------->>>> $back");
      pt("fromprofile--------------->>>> ${widget.fromProfile}");

      if (!await UserLocalData.needsBasicProfile()) return;
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Complete your profile'),
          content: const Text(
            'Add your cycle and health details so guidance and the assistant can use your information.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.basicInfoView,
                  (route) => false,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadSelectedStage() async {
    final userProvider = context.read<GetUserProvider>();
    final step = await UserLocalData.getStep();
    if (!mounted) return;
    if (step != null && step.isNotEmpty) {
      setState(() {
        selectedStageIndex = int.tryParse(step);
      });
    }

    final backendUser = userProvider.userData?.data?.user?.user;
    if (backendUser != null) {
      final cType = backendUser.cycleType;
      int? backendIndex;
      if (cType == "pregnancy") {
        backendIndex = 1;
      } else if (cType == "post_pregnancy") {
        backendIndex = 2;
      } else if (cType == "regular" ||
          cType == "irregular" ||
          cType == "prepregnancy") {
        backendIndex = 0;
      }

      if (backendIndex == null) {
        final stageField = backendUser.stage?.toLowerCase() ?? '';
        if (stageField.contains('post')) {
          backendIndex = 2;
        } else if (stageField.contains('preg') && !stageField.contains('pre')) {
          backendIndex = 1;
        } else if (stageField.contains('pre')) {
          backendIndex = 0;
        }
      }

      if (backendIndex != null) {
        setState(() {
          selectedStageIndex = backendIndex;
          expandedIndex = backendIndex;
        });
        pt("StagesView initialized from backend state: $backendIndex ($cType)");
      }
    }
  }

  /// Always show all stage cards on this screen so users can compare and switch.
  bool get _showAllStageOptions => true;

  List<int> get _visibleStageIndices {
    if (_showAllStageOptions) {
      return List.generate(_stages.length, (i) => i);
    }
    return [selectedStageIndex!];
  }

  void _onHeaderTap(int index) {
    setState(() {
      if (expandedIndex == index) {
        expandedIndex = null;
      } else {
        expandedIndex = index;
        selectedStageIndex = index;
      }
    });
  }

  Future<void> _confirmStageSelection(int index) async {
    final userProvider = context.read<GetUserProvider>();
    await UserLocalData.saveLastStageScreenShown();
    if (!mounted) return;
    await userProvider.updateUserStage(index);

    if (!mounted) return;
    setState(() {
      selectedStageIndex = index;
    });

    if (fromLoginScreen) {
      switch (index) {
        case 0:
          Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
          break;
        case 1:
          {
            final user = context.read<GetUserProvider>().userData?.data?.user;
            String? concDate = user?.user?.pregnancyStartDate;
            if (concDate == null && user?.pregnancyTracker != null) {
              concDate =
                  user?.pregnancyTracker!['pregnancyStartDate']?.toString() ??
                  user?.pregnancyTracker!['conception_date']?.toString();
            }
            if (concDate != null && concDate.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.navbarView);
            } else {
              Navigator.pushNamed(context, AppRoutes.pregnancyView);
            }
          }
          break;
        case 2:
          Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
          break;
      }
      return;
    }

    if (widget.fromProfile == true) {
      if (widget.isUpdateFlow == true) {
        await UserLocalData.saveStep(index.toString());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Stage updated successfully!'),
            backgroundColor: AppColors.buttonClr1,
            duration: const Duration(seconds: 2),
          ),
        );

        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.navbarPrePregancyView,
              (route) => false,
            );
            break;
          case 1:
            {
              final user = userProvider.userData?.data?.user;
              String? concDate = user?.user?.pregnancyStartDate;
              if (concDate == null && user?.pregnancyTracker != null) {
                concDate =
                    user?.pregnancyTracker!['pregnancyStartDate']?.toString() ??
                    user?.pregnancyTracker!['conception_date']?.toString();
              }
              if (concDate != null && concDate.isNotEmpty) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.navbarView,
                  (route) => false,
                );
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.pregnancyView,
                  (route) => false,
                );
              }
            }
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.combinedBabyDetailScreen,
              (route) => false,
            );
            break;
        }
        return;
      }

      switch (index) {
        case 0:
          Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
          break;
        case 1:
          {
            final user = userProvider.userData?.data?.user;
            String? concDate = user?.user?.pregnancyStartDate;
            if (concDate == null && user?.pregnancyTracker != null) {
              concDate =
                  user?.pregnancyTracker!['pregnancyStartDate']?.toString() ??
                  user?.pregnancyTracker!['conception_date']?.toString();
            }
            if (concDate != null && concDate.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.navbarView);
            } else {
              Navigator.pushNamed(context, AppRoutes.pregnancyView);
            }
          }
          break;
        case 2:
          Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
          break;
      }
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.processingDetailsView,
      arguments: {"index": index},
    );
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 24),
                itemCount: _visibleStageIndices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, listIndex) {
                  final index = _visibleStageIndices[listIndex];
                  final data = _stages[index];
                  final isExpanded =
                      expandedIndex == index || _visibleStageIndices.length == 1;
                  final isSelected = selectedStageIndex == index;

                  return StageAccordionCard(
                    data: data,
                    isExpanded: isExpanded,
                    isSelected: isSelected,
                    onHeaderTap: _showAllStageOptions
                        ? () => _onHeaderTap(index)
                        : () {},
                    onNext: () => _confirmStageSelection(index),
                    showNextButton: _showAllStageOptions || isSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
