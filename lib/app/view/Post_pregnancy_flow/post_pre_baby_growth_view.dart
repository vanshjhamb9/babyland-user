import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/images.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_cont.dart';
import '../../widgets/custom_image.dart';
import '../../widgets/feeding_entry_dialog.dart';
import '../../widgets/feeding_details_dialog.dart';
import '../../widgets/gradientprogressBar.dart';
import '../../common_profile_header/profile_header.dart';
import '../../data/storage/user_local_data.dart';
import '../../widgets/print.dart';

class PostPreBabyGrowthView extends StatefulWidget {
  const PostPreBabyGrowthView({super.key});

  @override
  State<PostPreBabyGrowthView> createState() => _PostPreBabyGrowthViewState();
}

class _PostPreBabyGrowthViewState extends State<PostPreBabyGrowthView> {
  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      context.read<PostpregnancyProvider>().getFeedingApi();
      final success = await context.read<PostpregnancyProvider>().getRecoveryTaskApi();
      if (!success && mounted) {
        // Tracker not found — clear local flag and redirect to onboarding
        await UserLocalData.clearPostPregnancySetupComplete();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.combinedBabyDetailScreen);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GetUserProvider>();

    final id = provider.userData?.data?.user?.user?.sId.toString();
    print("this is the user id ${id}");
    return Scaffold(
      appBar: ProfileHeader(
        subtitle: "Here is your post pregnancy journey." /*img: false,*/,
      ),
      body: Consumer<PostpregnancyProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            color: AppColors.backgroundClr,
            gradient: AppColors.backGroundColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Dashboard",
                      style: AppFontStyle.text_16_400(
                        fontFamily: AppFontFamily.gilroySemiBold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  AppContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    radius: 8,
                    color: AppColors.white,
                    border: BoxBorder.fromBorderSide(
                      BorderSide(color: AppColors.grey.withAlpha(70)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return AppColors.buttonClr.createShader(
                                        bounds,
                                      );
                                    },
                                    blendMode: BlendMode.srcIn,
                                    child: const Icon(Icons.favorite, size: 28),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Recovery Progress",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "View all",
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: AppFontFamily.gilroyRegular,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GradientProgressBar(
                                progress: double.parse(
                                  provider
                                          .getRecoveryApiData
                                          ?.data
                                          ?.tasks
                                          ?.completionPercentage ??
                                      "0.0",
                                ),
                                height: 7,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "${provider.getRecoveryApiData?.data?.tasks?.completionPercentage ?? "0.0"}%",
                              style: AppFontStyle.text_12_400(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.buttonClr1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          separatorBuilder: (context, index) => SBox(h: 10),
                          itemCount:
                              provider
                                  .getRecoveryApiData
                                  ?.data
                                  ?.tasks
                                  ?.tasks
                                  ?.length ??
                              0,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final tasks = provider
                                .getRecoveryApiData
                                ?.data
                                ?.tasks
                                ?.tasks?[index];

                            return customCheckboxTile(
                              title: capitalizeFirstLetter(tasks?.task ?? ""),
                              subtitle: DateFormat('yyyy-MM-dd').format(
                                DateTime.parse(tasks?.dateAssigned ?? ""),
                              ),
                              value: (tasks?.completed ?? false)
                                  ? true
                                  : provider.selectedIndexes.contains(index),

                              onChanged: (val) async {
                                if (tasks?.completed == false) {
                                  provider.toggleRecoveryIndex(index);

                                  if (val == true) {
                                    await provider.recoveryTaskApi(
                                      completed: true,
                                      id: id,
                                      dateAssigned: tasks?.dateAssigned ?? "",
                                      dateCompleted: tasks?.dateCompleted ?? "",
                                      dueDate: tasks?.dueDate ?? "",
                                      task: tasks?.task ?? "",
                                    );
                                    // if (success) {
                                    //   provider.selectedIndexes.remove(index);
                                    //   provider.notifyListeners();
                                    // }
                                  }
                                }
                              },
                            );
                          },
                        ),
                        /* Column(
                          children: [
                            customCheckboxTile(
                              title: "Pelvic Floor Exercises",
                              subtitle: "Complete 10 minutes of kegel exercises",
                              value: isChecked1,
                                onChanged: (val) async {
                                  if (isChecked1 == true && val == false) {
                                    setState(() {
                                      isChecked1 = false;
                                      pt("Unchecked without API call");
                                    });
                                  } else {
                                    bool apiResponseSuccess = await provider.recoveryTaskApi(
                                      completed: val == true,
                                      id: id,
                                    );

                                    if (apiResponseSuccess) {
                                      setState(() {
                                        isChecked1 = val;
                                        pt("this is value $val");
                                      });
                                    } else {
                                      pt("API call failed, checkbox state unchanged");
                                    }
                                  }
                                }
                            ),
                            SizedBox(height: 12,),
                            customCheckboxTile(
                              title: "Drink 8 Glasses of Water",
                              subtitle: "Stay hydrated throughout the day",
                                value: isChecked2,
                                onChanged: (val) async {
                                  if (isChecked2 == true && val == false) {
                                    setState(() {
                                      isChecked2 = false;
                                      pt("Unchecked without API call");
                                    });
                                  } else {
                                    bool apiResponseSuccess = await provider.recoveryTaskApi(
                                      completed: val == true,
                                      id: id,
                                    );

                                    if (apiResponseSuccess) {
                                      setState(() {
                                        isChecked2 = val;
                                        pt("this is value $val");
                                      });
                                    } else {
                                      pt("API call failed, checkbox state unchanged");
                                    }
                                  }
                                }

                            ),
                            SizedBox(height: 12,),
                            customCheckboxTile(
                              title: "Check C-Section Incision",
                              subtitle: "Monitor healing and cleanliness",
                                value: isChecked3,
                              onChanged: (val) async {
                                // Agar checkbox current me already checked hai aur user uncheck kar raha hai
                                if (isChecked3 == true && val == false) {
                                  setState(() {
                                    isChecked3 = false;
                                    pt("Unchecked without API call");
                                  });
                                } else {
                                  bool apiResponseSuccess = await provider.recoveryTaskApi(
                                    completed: val == true,
                                    id: id,
                                  );

                                  if (apiResponseSuccess) {
                                    setState(() {
                                      isChecked3 = val;
                                      pt("this is value $val");
                                    });
                                  } else {
                                    pt("API call failed, checkbox state unchanged");
                                  }
                                }
                              }

                            )],
                        )*/
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  AppContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    radius: 8,
                    color: AppColors.white,
                    isBordered: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Mood",
                              style: AppFontStyle.text_15_600(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textClr,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "How are you feeling?",
                              style: AppFontStyle.text_14_400(
                                fontFamily: AppFontFamily.gilroyRegular,
                                color: AppColors.textLightClr,
                              ),
                            ),
                          ],
                        ),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomImage(path: ImageConstants.emoji, scale: 4),
                              SizedBox(width: 5),
                              if (provider
                                      .getRecoveryApiData
                                      ?.data
                                      ?.tasks
                                      ?.mood
                                      ?.isNotEmpty ??
                                  false)
                                Container(
                                  height: 24,
                                  width: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    gradient: AppColors.backGroundColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      provider
                                              .getRecoveryApiData
                                              ?.data
                                              ?.tasks
                                              ?.mood ??
                                          "",
                                      style: AppFontStyle.text_12_600(
                                        fontFamily: AppFontFamily.gilroyRegular,
                                        color: AppColors.textClr,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  AppContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    radius: 8,
                    color: AppColors.white,
                    isBordered: true,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CustomImage(
                                  path: ImageConstants.feeding,
                                  scale: 5,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Feeding Today",
                                  style: AppFontStyle.text_15_600(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.textClr,
                                  ),
                                ),
                              ],
                            ),
                            Button(
                              height: 36,
                              width: 84,
                              text: "+ Add",
                              padding: EdgeInsets.all(9),
                              textStyle: AppFontStyle.text_12_400(
                                fontFamily: AppFontFamily.gilroyBold,
                                color: AppColors.white,
                              ),
                              onTap: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (context) => FeedingEntryDialog(),
                                );
                                // Refresh data if feeding was added successfully
                                if (result == true) {
                                  // You can add logic here to refresh feeding data if needed
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        if (provider.getRecoveryApiData?.status ==
                            ApiStatus.LOADING) ...[
                          noLogsShimmer(),
                        ] else ...[
                          if (provider
                                  .getRecoveryApiData
                                  ?.data
                                  ?.tasks
                                  ?.feedings
                                  ?.isEmpty ??
                              false) ...[
                            AppContainer(
                              height: 53,
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              radius: 8,
                              color: AppColors.white,
                              isBordered: true,
                              child: Center(
                                child: Text(
                                  "No Logs yet",
                                  style: AppFontStyle.text_12_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.textLightClr,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount:
                                provider
                                    .getRecoveryApiData
                                    ?.data
                                    ?.tasks
                                    ?.feedings
                                    ?.length ??
                                0,
                            itemBuilder: (context, index) {
                              final feeding = provider.getRecoveryApiData?.data?.tasks?.feedings?[index];
                              return AppContainer(
                                onTap: () {
                                  if (feeding != null) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => FeedingDetailsDialog(feeding: feeding),
                                    );
                                  }
                                },
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                                radius: 8,
                                gradient: AppColors.backGroundColor,
                                child: Text(
                                  // ignore: prefer_interpolation_to_compose_strings
                                  capitalizeFirstLetter(provider.getRecoveryApiData?.data?.tasks?.feedings?[index].notes ?? "") +
                                      " (${capitalizeFirstLetter(provider.getRecoveryApiData?.data?.tasks?.feedings?[index].type ?? "")})",
                                  style: AppFontStyle.text_14_500(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.postAppointmentView);
                    },
                    child: CustomCont(
                      title: "Appointments",
                      path: ImageConstants.appointement,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.babyGrowthSummaryView);
                      // context.read<BabyGrowthProvider>().addBabyDataInitial();
                    },
                    child: CustomCont(
                      title: "Baby Growth Tracker",
                      path: ImageConstants.baby_growth,
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    color: AppColors.white,
                    radius: 8,
                    border: BoxBorder.fromBorderSide(
                      BorderSide(color: AppColors.greyStroke),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 56,
                          child: InkWell(
                            onTap: () {
                              //  Navigator.pushNamed(context, AppRoutes.aiInsights);
                            },
                            child: Row(
                              children: [
                                CustomImage(
                                  path: ImageConstants.postPreAiInsights,
                                  scale: 5,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Postpartum Tips & AI Insights",
                                  style: AppFontStyle.text_14_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                    color: AppColors.black,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  size: 30,
                                  color: AppColors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AppContainer(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 13,
                          ),
                          radius: 8,
                          gradient: AppColors.backGroundColor,
                          child: Text(
                            "Stay hydrated and eat nutritious meals."
                            " Your body is healing and needs proper fuel to recover effectively.",
                            maxLines: 3,
                            style: AppFontStyle.text_12_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget customCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    double size = 30,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AppContainer(
          //   width: size,
          //   height: size,
          //   border: Border.all(color: AppColors.greyStroke, width: 1),
          //   radius: 4,
          //   gradient: value ? AppColors.buttonClr : null,
          //   color: value ? null : Colors.transparent,
          //   child: value
          //       ? Icon(Icons.check, size: size * 0.7, color: Colors.white)
          //       : null,
          // ),
          GradientCheckbox(value: value, onChanged: onChanged, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppFontFamily.gilroySemiBold,
                    decoration: value ? TextDecoration.lineThrough : null,
                    color: value
                        ? AppColors.black.withAlpha(65)
                        : AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Text(
                //   subtitle,
                //   style: TextStyle(
                //     fontSize: 11,
                //     fontFamily: AppFontFamily.gilroyMedium,
                //     fontWeight: FontWeight.w400,
                //     color: AppColors.textLightClr,
                //   ),
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget noLogsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: AppContainer(
        height: 53,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        radius: 8,
        color: AppColors.white,
        isBordered: true,
        child: Center(
          child: Container(
            height: 12,
            width: 80, // approx size of "No Logs yet"
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
