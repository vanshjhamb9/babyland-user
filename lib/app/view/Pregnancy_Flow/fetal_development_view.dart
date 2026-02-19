import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/network/end_points.dart';
import '../../constants/images.dart';
import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/custom_image.dart';

class FetalDevelopmentView extends StatelessWidget {
  const FetalDevelopmentView({super.key});

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PregnancyController>();

    final data = provider.pregnancyApiData?.data?.data?.data;

    // Provide fallback values if data is null
    final currentWeek = data?.currentWeek ?? 0;
    final trimester = data?.trimester ?? 0;
    // final fetalGrowthStage = data?.fetalGrowthStage ?? '';

    // final progress = (currentWeek > 0 && currentWeek <= 40) ? currentWeek / 40.0 : 0.4;
    // final percentProgress = (progress * 100).toStringAsFixed(0) + '%';


    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      appBar: CustomAppBar(title: Text("Fetal Development",
        style: AppFontStyle.text_20_400(
            color: AppColors.textClr,
            fontFamily: AppFontFamily.gilroySemiBold),),centerTitle: true,),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: SingleChildScrollView( // Added ScrollView
          child: Column(
            children: [
              SizedBox(height: 18),
              AppContainer(
                color: AppColors.white,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(horizontal: 16),
                isBordered: true,
                radius: 8,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
  
                      children: [
                        CustomImage(path: ImageConstants.calender,scale: 6,),
                        SizedBox(width: 10,),
                        // Example 1: RichText (standard)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Week $currentWeek ',
                                style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),
                              ),
  
                              TextSpan(
                                text: '- Trimester $trimester',
                                style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),
  
                              ),
                            ],
                          ),
                        )
  
                      ],
  
                    ),
                    SizedBox(height: 18,),
                    Row(
                      children: [
                        Expanded(
                          child: GradientProgressBar(
                            progress:  double.tryParse(data?.percentage.toString() ?? "0")?? 0.0,
                            height: 8,
                          ),
                        ),
                        SizedBox(width: 11,),
                        Text("${data?.percentage ?? ""}%",style: AppFontStyle.text_13_400(
                            color: AppColors.buttonClr1,
                            fontFamily: AppFontFamily.gilroyMedium),)
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 18,),
              AppContainer(
                height: 395,
                margin: EdgeInsets.symmetric(horizontal: 22),
  
                child: Column(
                  children: [
  
                    AppContainer( height: 220,
                      width: 220,
                      radius: 110,
                      gradient: AppColors.backGroundColor,
                      border: Border.all(color: AppColors.buttonClr1.withAlpha(20),width: 6),
  
                      child: AppContainer(
                        height: 220,
                        width: 220,
                        radius: 110,
                        gradient: AppColors.backGroundColor,
                        border: Border.all(color: AppColors.buttonClr2.withAlpha(40),width: 6),
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: AppColors.white,
                          child: Builder(
                            builder: (context) {
                              String? imagePath = data?.predictions?.fetalImage;
                              if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('assets')) {
                                final baseUrl = Uri.parse(EndPoints.baseUrl).origin;
                                if (!imagePath.startsWith('/')) {
                                  imagePath = "/$imagePath";
                                }
                                imagePath = "$baseUrl$imagePath";
                              }
                              return ClipOval(
                                child: CustomImage(
                                  path: imagePath ?? ImageConstants.civi,
                                  fit: BoxFit.cover,
                                  h: 200, // Matching the diameter of CircleAvatar (radius 100 * 2)
                                  w: 200,
                                ),
                              );
                            }
                          ),
                        ),
                      ),
                    ),
  
  
                    Stack(
                      children: [
                        Positioned(
                          top: 10,
                            left: 28,
                            child: CustomImage(path: ImageConstants.yellow_star,scale: 4,)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 58.0,vertical: 26),
                          child: AppContainer(
                           // height: 90,
                            color: AppColors.white,
                            padding: EdgeInsetsGeometry.symmetric(horizontal: 8,vertical: 12),
                            child: RichText(
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              text: TextSpan(
                                style: AppFontStyle.text_18_400(fontFamily: AppFontFamily.gilroyMedium),
                                children: [
                                  TextSpan(text: 'Your baby is now the size of a '),
                                  TextSpan(
                                    text: data?.predictions?.fetalSize ?? '',
                                    style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            SizedBox(height: 8),
            AppContainer(
                color: AppColors.white,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 16),
              isBordered: true,
              radius: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Development this week",
                    style: AppFontStyle.text_15_400(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ),
                  ),
  
                  const SizedBox(height: 10),
                  if(data?.fetalGrowthStage?.isNotEmpty ?? false)
                  buildBulletText(
                    data?.fetalGrowthStage ?? '',
                  ),
                  if(data?.predictions?.nextMilestone?.isNotEmpty ?? false)
                  buildBulletText(
                    data?.predictions?.nextMilestone ?? '',
                  ),
  
                ],
              )
            )
          ],
        ),
      ),
      ),
    );
  }
  Widget buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0,left: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "•",
            style: AppFontStyle.text_14_400(
              color: AppColors.lightGrey,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
          SizedBox(width: 8,),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              style: AppFontStyle.text_12_400(
                color: AppColors.lightGrey,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
