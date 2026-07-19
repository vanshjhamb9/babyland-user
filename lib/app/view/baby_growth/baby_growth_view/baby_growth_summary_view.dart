import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/common_profile_header/profile_header.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/response/status.dart';


class BabyGrowthSummaryView extends StatefulWidget {
  const BabyGrowthSummaryView({super.key});

  @override
  State<BabyGrowthSummaryView> createState() => _BabyGrowthSummaryViewState();
}

class _BabyGrowthSummaryViewState extends State<BabyGrowthSummaryView> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BabyGrowthProvider>();
      provider.babyGrowthsDetails();
    });
  }

  String _lastUpdatedLabel(dynamic apiData) {
    final summary = apiData?.data?.tracker?.babyGrowthSummary;
    if (summary == null || summary.isEmpty) return "--";
    final dateStr = summary.first.date;
    if (dateStr == null || dateStr.isEmpty) return "--";
    return formatDate(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BabyGrowthProvider>();
    final apiData = provider.babyGrowthApiData;
    return Scaffold(
      appBar: const ProfileHeader(showBackButton: true),
      body: AppContainer(
        height: mediaQueryH(context),
        padding: EdgeInsets.symmetric(horizontal: 14),
        gradient: AppColors.backGroundColor,
        child: RefreshIndicator(
          onRefresh: () {
           return context.read<BabyGrowthProvider>().babyGrowthsDetails();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 20),
                switch (apiData?.status) {
                  ApiStatus.ERROR =>
                    GeneralExceptionWidget(
                      onPress: () => context.read<BabyGrowthProvider>().babyGrowthsDetails(),
                    ),
                  ApiStatus.LOADING =>
                    Center(
                      child: babyMeasurementsShimmer(),
                    ),
                  ApiStatus.COMPLETED => AppContainer(
                        radius: 8,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        color: AppColors.white,
                        isBordered: true,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: CustomImage(path: ImageConstants.increase),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Baby Measurements",
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Last Updated: ${_lastUpdatedLabel(apiData)} ",
                                    maxLines: 2,
                                    style: AppFontStyle.text_11_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                    ),
                                  ),

                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            (apiData?.data?.tracker?.babyGrowthSummary?.isEmpty ?? false ) ?
                            Text("No data found!",style: AppFontStyle.text_16_400(color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),) :
                            ListView.separated(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: apiData?.data?.tracker?.babyGrowthSummary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final List<Color> bgColors = [
                                  AppColors.lightGreen,
                                  AppColors.lightBlue,
                                  AppColors.lightPurple,
                                ];

                                final List<Color> mainColors = [
                                  AppColors.green,
                                  AppColors.blue,
                                  AppColors.purpleClr,
                                ];

                                final Color background = bgColors[index % bgColors.length];
                                final Color mainColor = mainColors[index % mainColors.length];

                                return AppContainer(
                                  color: background,
                                  radius: 10,
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Height: ${apiData?.data?.tracker?.babyGrowthSummary?[index].height ?? "0"} cm",
                                        style: AppFontStyle.text_14_400(
                                          color: mainColor,
                                          fontFamily: AppFontFamily.gilroyMedium,
                                        ),
                                      ),
                                      Spacer(),
                                      AppContainer(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        radius: 100,
                                        color: AppColors.lightYellow,
                                        child: Text(
                                          "41th percentile",
                                          style: AppFontStyle.text_12_400(
                                            color: AppColors.yellow,
                                            fontFamily: AppFontFamily.gilroyMedium,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) => SizedBox(height: 10),
                            ),
                            SizedBox(height: 16 ),
                            InkWell(
                              onTap: (){
                                Navigator.pushNamed(context, AppRoutes.babyGrowthView);
                              },
                              child: AppContainer(
                                gradient: AppColors.buttonClr,
                                radius: 100,
                                padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add,color: AppColors.white),
                                    SizedBox(width: 4),
                                    Text("Update",
                                      style: AppFontStyle.text_16_400(
                                        color: AppColors.white  ,
                                        fontFamily: AppFontFamily.gilroySemiBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                  _ => const SizedBox(),
                },
                SizedBox(height: 16),
                allTiles(),
                SizedBox(height: 50),

              ],
            ),
          ),
        ),
      ),
    );
  }

  ListView allTiles() {
    return ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
                List<String> images =  [
                  ImageConstants.mildstones,
                  ImageConstants.photos,
                  ImageConstants.vaccinations,
                ];
                List<String> title = [
                  "Milestones",
                  "Photos",
                  "Vaccinations",
                ];
                return InkWell(
                  onTap: () {
                    switch(index){
                      case 0 :
                        Navigator.pushNamed(context, AppRoutes.mildStonesView);
                      case 1:
                        Navigator.pushNamed(context, AppRoutes.photoView);
                      case 2 :
                        Navigator.pushNamed(context, AppRoutes.vaccinationView);
                    }
                  },
                  child: AppContainer(
                    radius: 8,
                    padding: EdgeInsets.symmetric(horizontal: 14,vertical: 14),
                    isBordered: true,
                    color: AppColors.white,
                    child: Row(
                      children: [
                        CustomImage(path: images[index]),
                        SizedBox(width: 12),
                        Text(title[index],
                          style: AppFontStyle.text_16_400(
                            fontFamily: AppFontFamily.gilroySemiBold,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios,color: AppColors.black,size: 16)
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: 8),
            );
  }



  Widget babyMeasurementsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: AppContainer(
        radius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: Colors.white,
        child: Column(
          children: [
            Container(width: 120, height: 20, color: Colors.white),
            SizedBox(height: 16),
            Container(width: double.infinity, height: 50, color: Colors.white),
            SizedBox(height: 16),
            Container(width: 80, height: 30, color: Colors.white),
          ],
        ),
      ),
    );
  }


}
