import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/menstrual_dashboard_Predict_model.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:babyland/app/common_profile_header/profile_header.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';

class MentrualCycle extends StatefulWidget {
  const MentrualCycle({super.key});

  @override
  State<MentrualCycle> createState() => _MentrualCycleState();
}

class _MentrualCycleState extends State<MentrualCycle> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CycleCalenderProvider>().dashboardData();
      context.read<CycleCalenderProvider>().getDashBoardAiInsights();
      context.read<CycleCalenderProvider>().dashboardMoodData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileHeader(
        subtitle: "Track your cycle and stay healthy",
      ),
      body: Consumer<CycleCalenderProvider>(
        builder: (context, provider, _) {
          final status = provider.dashboardApiData?.status;

          switch (status) {
            case ApiStatus.LOADING:
              return AppContainer(
                  gradient: AppColors.backGroundColor,
                  child: menstrualDashboardShimmer());

            case ApiStatus.ERROR:
              return GeneralExceptionWidget(onPress: (){
                provider.dashboardData();
                provider.aiInsightsApi('nutrition');
                provider.dashboardMoodData();
              },);

            case ApiStatus.COMPLETED:
              return buildAppContainerData(context,provider);

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  AppContainer buildAppContainerData(BuildContext context,CycleCalenderProvider provider) {
    return AppContainer(
      height: mediaQueryH(context),
      color: AppColors.backgroundClr,
      gradient: AppColors.backGroundColor,
      child: RefreshIndicator(
        onRefresh: () {
          provider.aiInsightsApi('nutrition');
          provider.dashboardMoodData();
          return provider.dashboardData();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 18),
              AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CustomImage(path: ImageConstants.calender, scale: 4.7),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Menstrual cycle",
                                  style: AppFontStyle.text_14_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Day ${provider.dashboardApiData?.data?.data?.daysSinceCreation ?? "0"} of cycle",
                                  style: AppFontStyle.text_12_400(
                                    fontFamily: AppFontFamily.gilroyRegular,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.cycleCalendarView,
                          ),
                          child: Text(
                            "View Calendar",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppFontFamily.gilroyRegular,
                              decoration: TextDecoration.underline,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GradientProgressBar(progress: double.tryParse(provider.dashboardApiData?.data?.data?.percentage ?? "0.0") ?? 0.0, height: 7),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "${provider.dashboardApiData?.data?.data?.percentage ?? "0"}%",
                          style: AppFontStyle.text_12_400(
                            fontFamily: AppFontFamily.gilroySemiBold,
                            color: AppColors.buttonClr1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppContainer(
                      radius: 8,
                      gradient: AppColors.backGroundColor,
                      padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Next period",
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                            ),
                          ),
                          Text(
                            formatDateToDayMonth(provider.dashboardApiData?.data?.data?.nextPeriodDate ?? "-"),
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Mood Section
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.prePreSubscriptionView);
                },
                child: AppContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  radius: 8,
                  isBordered: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Mood",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "How are you feeling?",
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: AppColors.lightGrey,
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
                            (provider.dashboardMoodApiData?.data?.data?.mood?.isNotEmpty ?? false) ? AppContainer(
                              height: 26,
                              width: 58,
                              radius: 100,
                              gradient: AppColors.backGroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Center(
                                child: Text(
                                  provider.dashboardMoodApiData?.data?.data?.mood ?? "",
                                  style: AppFontStyle.text_13_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ) : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 56,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.aiInsights);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CustomImage(path: ImageConstants.bulb, scale: 4),

                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    "AI Insights & Tips",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.chevron_right, size: 30),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    (provider.menstrualAiInsightsDash?.data?.data?.isEmpty ?? false) ?
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Center(
                        child: Text("No insights available!",
                        style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyRegular),
                        ),
                      ),
                    )  :
                    ListView.separated(
                      itemCount: provider.menstrualAiInsightsDash?.data?.data?.length ?? 0,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        List<String> images = [ImageConstants.moon,ImageConstants.walk,ImageConstants.water];
                      return Tile(
                        path: images[index % images.length],
                        text: provider.menstrualAiInsightsDash?.data?.data?[index].message ?? "",
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100,)
            ],
          ),
        ),
      ),
    );
  }


  Widget menstrualDashboardShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          shimmerBox(height: 120, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 80, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 160, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 180, width: double.infinity),
        ],
      ),
    );
  }

  /// Generic shimmer for any rectangular placeholder
  Widget shimmerBox({
    double? width,
    double? height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey,
      highlightColor: AppColors.grey,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey.withAlpha(100),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  final String path;
  final String text;

  const Tile({super.key, required this.path, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: AppColors.backGroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppContainer(
            height: 25,
            width: 25,
            radius: 100,
            color: Colors.white,
            child: Center(child: CustomImage(path: path, scale: 4)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              style: AppFontStyle.text_12_400(
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
