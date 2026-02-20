import 'package:babyland/app/navbar/pregnancy/navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/network/end_points.dart';

import '../../constants/images.dart';
import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_cont.dart';
import '../../widgets/custom_image.dart';
import '../../widgets/gradientprogressBar.dart';
import '../../common_profile_header/profile_header.dart';
import '../Pre_pregnancy_flow/Mentrual_cycle.dart';
import 'pregnancy_view.dart';

class PregnancyHomeView extends StatefulWidget {
  const PregnancyHomeView({super.key});

  @override
  State<PregnancyHomeView> createState() => _PregnancyHomeViewState();
}

class _PregnancyHomeViewState extends State<PregnancyHomeView> {

  @override
  void initState() {
    super.initState();
    // Fetch the pregnancy data on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<PregnancyController>(context, listen: false);
      await controller.getPregnancyApiData();
      // If no data returned (Tracker not found), redirect to conception date screen
      final data = controller.pregnancyApiData?.data?.data?.data;
      if (data == null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PregnancyView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileHeader(
        subtitle: "Welcome to your pregnancy journey",
      ),
      body: AppContainer(
        color: AppColors.backgroundClr,
        gradient: AppColors.backGroundColor,
        child:  Consumer<PregnancyController>(
    builder: (context, provider, child) {
      if (provider.isLoadingPreg) {
        // Show shimmer while loading
        return _buildShimmer();
      }

      if (provider.pregnancyApiData?.status == false) {
        // Show error message
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              provider.pregnancyApiData?.message ?? "Something went wrong!",
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      final data = provider.pregnancyApiData?.data?.data?.data;

      if (data == null) {
        return const Center(child: Text("No pregnancy data available."));
      }

      final currentWeek = data.currentWeek ?? "0";
      final trimester = data.trimester ?? "0";
      final expectedDueDate = data.expectedDueDate ?? "";
      final fetalGrowthStage = data.fetalGrowthStage ?? "";
      final predictions = data.predictions;
      pt("message $fetalGrowthStage");
      return RefreshIndicator(
        onRefresh: () {
          provider.getPregnancyApiData();
          return provider.getPregnancyApiData();
        },
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
              SizedBox(height: 15),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.fetalDevelopmentView),
                child: AppContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  radius: 8,
                  color: AppColors.white,
                  isBordered: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomImage(path: ImageConstants.calender, scale: 6),
                          SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Week $currentWeek ',
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                  ),
                                ),

                                TextSpan(
                                  text: '- Trimester $trimester',
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if(predictions?.fetalSize?.isNotEmpty ?? false)...[
                        const SizedBox(height: 14),
                        Text(
                        predictions?.fetalSize ?? "",
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                      ],


                      Row(
                        children: [
                          Expanded(
                            child: GradientProgressBar(progress:  double.tryParse(data.percentage.toString()) ?? 0.0, height: 8),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "${double.tryParse(data.percentage ?? "0")?.toStringAsFixed(0)}%",
                            style: AppFontStyle.text_12_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.buttonClr1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mood Section
              AppContainer(
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
                        SizedBox(height: 6),
                        Text(
                          "How are you feeling?",
                          style: AppFontStyle.text_12_400(
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
                          Container(
                            height: 24,
                            width: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: AppColors.backGroundColor,
                            ),
                            child: Center(
                              child: Text(
                                data.mood ?? "",
                                style: AppFontStyle.text_12_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.black,
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

              const SizedBox(height: 12),

           /*   AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomImage(
                          path: ImageConstants.notification,
                          scale: 4,
                        ),
                        SizedBox(width: 11),
                        Text(
                          "Upcoming",
                          style: AppFontStyle.text_15_400(
                            fontFamily: AppFontFamily.gilroySemiBold,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomImage(
                              path: ImageConstants.glucosse,
                              scale: 8,
                            ),
                            SizedBox(width: 11),
                            Text(
                              "Glucose Test",
                              style: AppFontStyle.text_15_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Today",
                          style: AppFontStyle.text_15_400(
                            fontFamily: AppFontFamily.gilroyMedium,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
*/
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.appointmentView),
                child: CustomCont(
                  title: "Appointments",
                  path: ImageConstants.appointement,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  context.read<NavBarProvider>().setSelectedIndex(3);
                },
                child: CustomCont(
                  title: "Community",
                  path: ImageConstants.community_clr,
                ),
              ),
              const SizedBox(height: 12),

              AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(10),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 56,
                      child: InkWell(
                        onTap: () {
                          context.read<NavBarProvider>().setSelectedIndex(2);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CustomImage(
                                  path: ImageConstants.bulb,
                                  scale: 4,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  "AI Insights & Tips",
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),

                            Icon(Icons.chevron_right, size: 30,
                                color: AppColors.black.withValues(alpha: 0.8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    (data.tracker?.aiInsights?.isEmpty ?? false) ?
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Center(child: Text("No Ai Insights Available",
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.black,
                        ),
                      ),
                      ),
                    ) :
                    ListView.builder(
                      shrinkWrap: true,
                        itemCount:data.tracker?.aiInsights?.length ?? 0,
                        itemBuilder: (context, index) {
                      return Tile(
                        path: ImageConstants.moon,
                        text:data.tracker?.aiInsights?[index].message ?? "",
                      );
                    },)
                  ],
                ),
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      );
    }))
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 120,
              height: 20,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
