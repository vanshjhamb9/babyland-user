import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/images.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';
import '../../widgets/common_select_date_textfield.dart';
import '../../widgets/custom_image.dart';
import '../../common_profile_header/profile_header.dart';

class PregnancyView extends StatefulWidget {
  const PregnancyView({super.key});

  @override
  State<PregnancyView> createState() => _PregnancyViewState();
}

class _PregnancyViewState extends State<PregnancyView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PregnancyController>(
      builder: (context, provider, _) => Scaffold(
        appBar: ProfileHeader(subtitle: "Track your cycle and stay healthy"),
        body: AppContainer(
          color: AppColors.backgroundClr,
          gradient: AppColors.backGroundColor,
          child: Column(
            children: [
              SizedBox(height: 8,),
              Divider(
                height: 1,
                color: AppColors.borderColor,
              ),
              SizedBox(height: 25,),
              AppContainer(
                  width: double.infinity,
                  color: AppColors.white,
                  borderColor: AppColors.borderColor,
                  radius: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [
                          CustomImage(path: ImageConstants.calender,scale: 6,),
                          SizedBox(width: 12,),
                          Text(
                            "Select Your Date of conception",
                            style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),
                          ),
                        ],

                      ),
                      SizedBox(height: 8,),
                      Text(
                        "Used to calculate due date & track growth milestones.",
                        style: AppFontStyle.text_11_400(fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.lightGrey,
                        ),
                      ),
                      SizedBox(height: 15,),
                      AppContainer(
                        width: double.infinity,
                        color: AppColors.white,
                        radius: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Date",
                              style: AppFontStyle.text_15_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                              ),
                            ),
                            SizedBox(height: 6,),
                            buildCustomTextFormFieldSelectDate(controller: provider.dateController),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 26,),
              AppContainer(
                width: double.infinity,
                color: AppColors.white,
                borderColor: AppColors.borderColor,
                radius: 8,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.black,
                          size: 27,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Why We Need This Information",
                          style: AppFontStyle.text_15_400(
                            fontFamily: AppFontFamily.gilroySemiBold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    buildBulletText(
                      "Calculate your current pregnancy week and due date",
                    ),
                    buildBulletText(
                      "Determine which trimester you’re in for personalized content",
                    ),
                    buildBulletText(
                      "Track your baby’s development and size week by week",
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
        bottomNavigationBar: AppContainer(
          gradient: AppColors.backGroundColor,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Button(
              onTap: (){
                if(provider.dateController.text.isNotEmpty) {
                  provider.pregnancyInfo();
                }else{
                  AppPopUp.showToast(message: "Please select date",lineColor: AppColors.red);
                }
               // Navigator.pushNamed(context, AppRoutes.navbarView);
              },
              height: 56,
              child: provider.pregnancyInfoApiData?.status == ApiStatus.LOADING ? customLoading() : Text("Calculate my week",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),),
            ),
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
            "• ",
            style: AppFontStyle.text_13_400(
              color: AppColors.lightGrey,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
          SizedBox(width: 4,),
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
