import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/images.dart';
import '../../controller/post_pregenancy/post_pregenancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/common_select_date_textfield.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_image.dart';

class PostPregnancyView extends StatelessWidget {
  const PostPregnancyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PostpregnancyProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: AppContainer(
              color: AppColors.backgroundClr,
              gradient: AppColors.backGroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 18),
                     AppContainer(
                        height: 185,
                        width: double.infinity,
                        color: AppColors.white,
                        borderColor: AppColors.borderColor,
                        radius: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomImage(path: ImageConstants.calender,scale: 6,),
                                  SizedBox(width: 10,),
                                  Text(
                                    "Select Your Delivery date?",
                                    style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),
                                  ),
                                ],

                              ),
                              SizedBox(height: 8,),
                              Text(
                                "This helps us personalize your recovery journey",
                                style: AppFontStyle.text_12_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),
                              ),
                              SizedBox(height: 10,),
                              AppContainer(
                                height: 77,
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
                      ),

                    SizedBox(height: 12,),
                    deliveryTypeCard(),
/*
                     AppContainer(
                        height: 142,
                        width: double.infinity,
                        color: AppColors.white,
                        borderColor: AppColors.borderColor,
                        radius: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  CustomImage(path: ImageConstants.baby,scale: 4,),
                                  SizedBox(width: 5,),
                                  Text(
                                    "Delivery Type",
                                    style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroySemiBold),
                                  ),
                                ],

                              ),
                              SizedBox(height: 20,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,

                                children: [
                                  Expanded(
                                    child: AppContainer(
                                      height: 48,border: Border.all(color: AppColors.borderColor),
                                      color: AppColors.white,
                                      radius: 8,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CustomImage(path: ImageConstants.thumb,scale: 4,),
                                          SizedBox(width: 10,),
                                          Text("Normal",style: AppFontStyle.text_13_400(
                                              fontFamily: AppFontFamily.gilroySemiBold),)
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16,),
                                  Expanded(
                                    child: AppContainer(
                                      height: 48,border: Border.all(color: AppColors.borderColor),
                                      color: AppColors.white,
                                      radius: 8,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CustomImage(path: ImageConstants.injection,scale: 4,),
                                          SizedBox(width: 10,),
                                          Text("C-Section",style: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroySemiBold),)
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                              ),

                            ],
                          ),
                        ),
                      ),
*/

                    SizedBox(height: 16,),
                     AppContainer(
                        width: double.infinity,
                        color: AppColors.white,
                        borderColor: AppColors.borderColor,
                        radius: 8,
                        padding: EdgeInsets.all(12),
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
                              "To personalize your recovery & self-care plan.",
                            ),
                            buildBulletText(
                              "To track your baby’s growth and milestones.",
                            ),
                            buildBulletText(
                              "To monitor your health & emotional well-being.",
                            ),
                            buildBulletText(
                              "To send timely reminders for feeding, recovery, and checkups.",
                            ),

                          ],
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ),

        );
      }
    );
  }

  Widget deliveryTypeCard() {
    return AppContainer(
      height: 142,
      width: double.infinity,
      color: AppColors.white,
      borderColor: AppColors.borderColor,
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomImage(path: ImageConstants.baby, scale: 4),
                const SizedBox(width: 5),
                Text(
                  "Delivery Type",
                  style: AppFontStyle.text_15_400(
                      fontFamily: AppFontFamily.gilroySemiBold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: deliveryOption("Normal", ImageConstants.thumb)),
                const SizedBox(width: 16),
                Expanded(child: deliveryOption("C-Section", ImageConstants.injection)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// ✅ function to build each option
  Widget deliveryOption(String type, String iconPath) {
    return Consumer<PostpregnancyProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.selectedDeliveryType == type;
        return GestureDetector(
          onTap: () => provider.onDeliveryTypeSelect(type),
          child: AppContainer(
            height: 48,
            radius: 8,
            border: Border.all(
              color: !isSelected ? AppColors.borderColor : AppColors.buttonClr1,
              width: 1,
            ),
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImage(path: iconPath, scale: 4),
                const SizedBox(width: 10),
                Text(
                  type,
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.black ,
                  ),
                ),
              ],
            ),
          ),
        );
      }
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
