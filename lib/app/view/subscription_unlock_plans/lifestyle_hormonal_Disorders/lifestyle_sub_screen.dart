import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../../../constants/images.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_family.dart';
import '../../../theme/font_style.dart';
import '../../../widgets/container.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_image.dart';
import '../../../widgets/icon_text_row.dart';
import '../../../widgets/sub_custom_container.dart';

class LifestyleSubScreen extends StatefulWidget {

  const LifestyleSubScreen({super.key});
  @override
  State<LifestyleSubScreen> createState() => _LifestyleSubScreenState();

}

class _LifestyleSubScreenState extends State<LifestyleSubScreen> {

  bool doneValue1 = true;
  bool doneValue2 = false;
  bool doneValue3 = false;
  bool imgValue1 = true;
  bool imgValue2 = false;
  bool imgValue3 = false;

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text("Subscription Plans",
          style: AppFontStyle.text_20_400(
              color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppContainer(
                height: 122,
                width: 118,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: CustomImage(path:ImageConstants.dimands),
              ),
              SizedBox(
                height: 6,
              ),
              AppContainer(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    Text("Unlock Premium Features",
                      style: AppFontStyle.text_20_400(
                          color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
                    ),
                    Text("Get unlimited access to all features",
                      style: AppFontStyle.text_13_400(
                          color: AppColors.textClr,fontFamily: AppFontFamily.gilroyLight),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),

              Center(
                child: Text(
                  'Lifestyle & Hormonal Disorders',
                  style:  AppFontStyle.text_20_400(
                      color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),

                ),),

              SizedBox(
                height: 15,
              ),

              InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: (){
                    setState(() {
                      doneValue1 = true;
                      doneValue2 = false;
                      doneValue3 = false;
                      imgValue1 = true;
                      imgValue2 = false;
                      imgValue3 = false;
                    });
                  },
                  child: SubCustomContainer(title: "Balance", price: "₹2,499/month",borderValue: doneValue1)),

              SizedBox(
                height: 16,
              ),

              InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: (){
                    setState(() {
                      doneValue2 = true;
                      doneValue1 = false;
                      doneValue3 = false;
                      imgValue2 = true;
                      imgValue3 = false;
                    });
                  },
                  child: SubCustomContainer(title: "Care", price: "₹3,999/month",
                      isMostPopular: true,borderValue: doneValue2)),
              SizedBox(
                height: 16,
              ),

              InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: (){
                    setState(() {
                      doneValue3 = true;
                      doneValue1 = false;
                      doneValue2 = false;
                      imgValue3 = true;
                      imgValue1 = true;
                      imgValue2 = true;

                    });
                  },
                  child: SubCustomContainer(title: "Total wellness", price: "₹5,499/month",
                      borderValue: doneValue3)),

              SizedBox(
                height: 16,
              ),

              AppContainer(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.symmetric(horizontal: 16,vertical: 14),
                color: AppColors.white,
                radius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    Text("Plan Features",style: AppFontStyle.text_18_400(
                        color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),),

                    SizedBox(
                      height: 12,
                    ),

                    IconTextRow(label: "${AppConstants.aiAssistantDisplayName} lifecycle tracker",imagePath:imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Diet & yoga plan",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Stress & sleep guidance",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Endocrinologist consult",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Therapy/psychologist support",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Ayurveda/Naturopathy options",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Full doctor + therapist + yoga + nutrition combo",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Babyland supplement/product Kit",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),

                  ],
                ),
              ),

              SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Button(
                  height: 50,borderRadius: 8,
                  text: "Get Full Access",
                  textStyle: AppFontStyle.text_16_600(
                      color: AppColors.white,fontFamily: AppFontFamily.gilroyBold),
                ),
              ),

              SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
