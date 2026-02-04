import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/widgets/common_select_date_textfield.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_textform_field.dart';

class BabyDetailView extends StatefulWidget {
   const BabyDetailView({super.key});

  @override
  State<BabyDetailView> createState() => _BabyDetailViewState();
}

class _BabyDetailViewState extends State<BabyDetailView> {

  final List<String> genderOptions = [
    'Boy',
    'Girl',
    'Prefer not to say',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PostpregnancyProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: AppContainer(
              gradient: AppColors.backGroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 18,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Baby name",
                          style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),
                        ),
                        SizedBox(height: 6,),
                        CustomTextFormField(
                          controller: provider.babyNameController,
                          borderColor: AppColors.borderColor,
                          height: 45,
                          hintText: "Enter your baby’s name",
                          hintStyle: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroyRegular,
                            color: AppColors.textLightClr,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Baby’s Date of birth",
                          style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),
                        ),
                        SizedBox(height: 6,),
                        CustomTextFormField(
                          controller: provider.dobController,
                          readOnly: true,
                          borderColor: AppColors.borderColor,
                          height: 45,
                          hintText: "DD-MM-YYYY",
                          hintStyle: AppFontStyle.text_13_400(
                            fontFamily: AppFontFamily.gilroyRegular,
                            color: AppColors.textLightClr,
                          ),
                          onTap: () {
                            AppPopUp.showToast(message: "Please change delivery date to update birth date.");
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Baby’s Gender",
                          style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium),
                        ),
                        SizedBox(height: 6,),
                      DropdownButtonFormField2<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderColor, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        hint:  Text("Select",
                          style: AppFontStyle.text_13_400(fontFamily: AppFontFamily.gilroyRegular,
                            color: AppColors.textLightClr,
                          ),
                        ),
                        style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyRegular,
                          color: AppColors.black,
                        ),
                        value: provider.selectedGender,
                        items: genderOptions
                            .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            provider.selectedGender = value;
                          });
                        },
                        dropdownStyleData: DropdownStyleData(
                          offset: const Offset(0, -10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.white,

                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        }
      ),
      // bottomNavigationBar: AppContainer(
      //   gradient: AppColors.backGroundColor,
      //   child: Padding(
      //     padding: const EdgeInsets.all(10),
      //     child: Button(
      //       onTap: (){
      //        // Navigator.pushNamed(context, AppRoutes.forgotPasswordOtpVerifyView);
      //       },
      //       height: 56,
      //       text: "Go to dashboard",
      //     ),
      //   ),
      // ),
    );
  }
}
