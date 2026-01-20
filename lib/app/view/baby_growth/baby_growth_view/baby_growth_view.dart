import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/common_select_date_textfield.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/texttield_title.dart';

class BabyGrowthView extends StatelessWidget {
   BabyGrowthView({super.key});


   @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BabyGrowthProvider>(
        create: (context) => BabyGrowthProvider(),
     builder: (context, child) => Consumer<BabyGrowthProvider>(
     builder: (context, provider, _) => Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text("Add Growth Data", style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),),),
      body: AppContainer(
        padding: EdgeInsets.symmetric(horizontal: 14),
        gradient: AppColors.backGroundColor,
        child: Form(
          key: provider.formKey,
          child: Column(
            children: [
              AppContainer(
                radius: 12,
                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 14),
                color: AppColors.white,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomImage(path: ImageConstants.babyIcon),
                        SizedBox(width: 10),
                        Text("Baby Measurements", style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroySemiBold),)
                      ],
                    ),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Date"),
                    buildCustomTextFormFieldSelectDate(controller: provider.dateController,),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Height (Cm)"),
                    SizedBox(height: 6),
                    CustomTextFormField(
                      controller: provider.heightController,
                      hintText: "e.g. 35 ",
                      borderColor: AppColors.borderColor,
                      textInputType: TextInputType.number,
                      validator: (value){
                        if(value?.isEmpty ?? true)
                          {
                            return "Please enter a height";
                          }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Weight (Kg)"),
                    SizedBox(height: 6),
                    CustomTextFormField(
                      controller: provider.weightController,
                      hintText: "e.g. 72 ",
                      textInputType: TextInputType.number,
                      borderColor: AppColors.borderColor,
                      validator: (value){
                        if(value?.isEmpty ?? true)
                        {
                          return "Please enter a weight";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    textFieldTitle(title: "Head Circumference (cm)"),
                    SizedBox(height: 6),
                    CustomTextFormField(
                      controller: provider.cmController,
                      hintText: "e.g. 42 ",
                      borderColor: AppColors.borderColor,
                      textInputType: TextInputType.number,
                      validator: (value){
                        if(value?.isEmpty ?? true)
                        {
                          return "Please enter a head circumference";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<BabyGrowthProvider>(
        builder: (context,provider,_) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Button(
                onTap: (){
                  if (provider.dateController.text.isEmpty) {
                    AppPopUp.showToast(
                      message: "Please select date",
                      lineColor: AppColors.red,
                    );
                    return;
                  }

                  if (provider.formKey.currentState!.validate()) {
                    provider.addBabyGrowthApi();
                  }
                },
                height: 56,
                child: provider.addNewBabyGrowthData?.status == ApiStatus.LOADING ? customLoading() : Center(child: Text("Continue",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),)),
              ),
            ),
          );
        }
      ),
     )));
  }
}
