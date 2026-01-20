import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:flutter/material.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isIosBackBtn: true,
        title: Text(
          "Report",
          style: AppFontStyle.text_18_600(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textClr,
          ),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0,vertical: 14),
                  radius: 16,
                  color: AppColors.white,
                  child: Row(
                    children: [
                      CustomImage(path: ImageConstants.networkImageDemo,h: 64,w: 64,
                      borderRadius: BorderRadius.circular(100),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Dr. Sarah Mitchell",
                            style: AppFontStyle.text_18_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textClr,
                            ),
                          ),
                          Text("Pediatrician",
                            style: AppFontStyle.text_14_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textLightClr,
                            ),
                          ),
                          Text("License: MD-12345",
                            style: AppFontStyle.text_14_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textLightClr.withAlpha(190),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      AppContainer(
                          radius: 100,
                          color: AppColors.greenLight.withAlpha(40),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CustomImage(path: ImageConstants.doctorHLogo),
                          )),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                AppContainer(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                  color: AppColors.buttonClr2.withAlpha(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomImage(path: ImageConstants.consultationDate),
                          SizedBox(width: 10),
                          Text(
                            "License: MD-12345",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textClr,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "January 15, 2024 • 2:30 PM",
                        style: AppFontStyle.text_15_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                AppContainer(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                  color: AppColors.buttonClr1.withAlpha(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomImage(path: ImageConstants.notes),
                          SizedBox(width: 10),
                          Text(
                            "Consultation Notes",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textClr,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Patient presents with mild fever and cough. Physical examination shows clear lungs, no signs Patient presents with mild fever and cough. Physical examination shows clear lungs, no signs Patient presents with mild fever and cough  with mild fever and cough.",
                        maxLines: 20,
                        style: AppFontStyle.text_15_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                AppContainer(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                  color: AppColors.lightBlue.withAlpha(100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomImage(path: ImageConstants.medicine),
                          SizedBox(width: 10),
                          Text(
                            "Prescribed Medicines",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textClr,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 2,
                        itemBuilder: (context, index) {
                            return AppContainer(
                              radius: 12,
                              padding: EdgeInsets.all(17),
                              color: AppColors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Paracetamol Syrup",
                                        style: AppFontStyle.text_16_400(
                                          fontFamily: AppFontFamily.gilroyMedium,
                                          color: AppColors.textClr,
                                        ),
                                      ),
                                      AppContainer(
                                        radius: 100,
                                        padding: EdgeInsets.symmetric(horizontal: 8,vertical: 2),
                                        color: index == 1 ? AppColors.greenLight.withAlpha(100) : AppColors.lightBlue,
                                        child:Text(
                                        index == 0 ?  "Fever" : "Cough",
                                          style: AppFontStyle.text_12_400(
                                            fontFamily: AppFontFamily.gilroyMedium,
                                            color:  index == 0 ?  AppColors.blue : AppColors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Dosage: 5ml (120mg)",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                  Text(
                                    "Frequency: Every 6 hours",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                  Text(
                                    "Duration: 3 days",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => SizedBox(height: 10),
                      ),
                      SizedBox(height: 12),
                      AppContainer(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                        color: AppColors.buttonClr1.withAlpha(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.favorite,color: Colors.purpleAccent),
                                SizedBox(width: 10),
                                Text(
                                  "Health Advice",
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.textClr,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                           ListView.separated(
                             physics: NeverScrollableScrollPhysics(),
                             shrinkWrap: true,
                               itemBuilder:(context, index) {
                                 return  Row(
                                   children: [
                                     Icon(Icons.done,color: AppColors.greenLight,size: 18),
                                     SizedBox(width: 6),
                                     Text(
                                       "Ensure adequate rest and sleep",
                                       maxLines: 20,
                                       style: AppFontStyle.text_14_400(
                                         fontFamily: AppFontFamily.gilroyMedium,
                                         color: AppColors.textLightClr,
                                       ),
                                     ),
                                   ],
                                 );
                               } ,
                               separatorBuilder: (context, index) => SizedBox(height: 10),
                               itemCount: 4)
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      AppContainer(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                        color: AppColors.orangeClr.withAlpha(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomImage(path: ImageConstants.followUp),
                                SizedBox(width: 10),
                                Text(
                                  "Follow-up",
                                  style: AppFontStyle.text_15_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.textClr,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Schedule follow-up if symptoms persist beyond 5 days",
                              maxLines: 20,
                              style: AppFontStyle.text_15_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textLightClr,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                borderRadius: 12,
                onTap: (){
                  AppPopUp.showToast(message: "Downloading prescription....");
                },
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImage(path: ImageConstants.download),
                    SizedBox(width: 10),
                    Text("Download Prescription (PDF)",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text("Prescription ID: RX-2024-0115-001",style: AppFontStyle.text_12_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
