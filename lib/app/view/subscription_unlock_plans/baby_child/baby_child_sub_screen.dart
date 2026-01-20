import 'package:babyland/app/widgets/button.dart';
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

class BabyChildSubScreen extends StatefulWidget {

  const BabyChildSubScreen({super.key});
  @override
  State<BabyChildSubScreen> createState() => _BabyChildSubScreenState();

}

class _BabyChildSubScreenState extends State<BabyChildSubScreen> {

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
                margin: EdgeInsets.symmetric(vertical: 16),
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
                  'Baby & Child (0-2 years)',
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
                  child: SubCustomContainer(title: "Basics", price: "₹2,499/month",borderValue: doneValue1)),

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
                  child: SubCustomContainer(title: "Care+", price: "₹3,999/month",
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
                  child: SubCustomContainer(title: "First 2 years", price: "₹5,499/month",
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [


                    Text("Plan Features",style: AppFontStyle.text_18_400(
                        color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),),

                    SizedBox(
                      height: 12,
                    ),

                    IconTextRow(label: "AI growth & milestone tracker",imagePath:imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Vaccination reminders",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Baby nutrition guidance",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Baby food recipes",imagePath: imgValue1 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Pediatrician tele-consult",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Baby yoga/massage classes",imagePath: imgValue2 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Sleep consultant support",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Pediatric phychologist access",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),

                    IconTextRow(label: "Babyland subscription product box",imagePath: imgValue3 ? ImageConstants.done2 : ImageConstants.cancel),


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
