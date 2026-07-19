import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/switch_btn.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/CustomTimerFormField.dart';
import '../../widgets/button.dart';
import '../../widgets/common_select_date_textfield.dart';
import '../../widgets/validation.dart';

class AddReminderView extends StatefulWidget {
  const AddReminderView({super.key});

  @override
  State<AddReminderView> createState() => _AddReminderViewState();
}

class _AddReminderViewState extends State<AddReminderView> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PregnancyController>(
        create: (context) => PregnancyController(),
        builder: (context, child) =>Consumer<PregnancyController>(
            builder: (context, provider, _) => Scaffold(
              appBar: CustomAppBar(
                title: Text("Add Appointment",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold),),
                centerTitle: true,
                // actions: [
                //   Padding(
                //     padding: const EdgeInsets.only(right: 24.0),
                //     child: CustomImage(path: "assets/images/mic.png",scale: 5,),
                //   ),
                // ],
              ),

              body: AppContainer(
                color: AppColors.backgroundClr,
                gradient: AppColors.backGroundColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 30,),
                        Text(
                          "Appointment title",
                          style: AppFontStyle.text_15_400(
                            color: AppColors.black,
                            fontFamily: AppFontFamily.gilroyMedium,
                          ),
                        ),
                        SizedBox(height: 6,),
                        CustomTextFormField(
                          onTap: (){},
                          borderColor: AppColors.borderColor,
                          height: 44,
                          controller: provider.titleController,
                          hintText: "e.g. Ultrasound scan",
                          hintStyle: AppFontStyle.text_13_400(
                            color: AppColors.textLightClr,
                            fontFamily: AppFontFamily.gilroyRegular,
                          ),
                        ),
                        SizedBox(height: 16,),

                        Text(
                          "Date",
                          style: AppFontStyle.text_15_400(
                            color: AppColors.black,
                            fontFamily: AppFontFamily.gilroyMedium,
                          ),
                        ),
                        SizedBox(height: 6,),
                        buildCustomTextFormFieldSelectDate(controller: provider.dateController),


                        SizedBox(height: 16,),

                        Text(
                          "Select Time",
                          style: AppFontStyle.text_15_400(
                            color: AppColors.black,
                            fontFamily: AppFontFamily.gilroyMedium,
                          ),
                        ),
                        SizedBox(height: 6,),
                        buildCustomTextFormFieldSelectTime(controller: provider.timerController),


                        SizedBox(height: 16,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Enable Reminder",
                              style: AppFontStyle.text_14_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                              ),
                            ),
                            SizedBox(width: 12),
                            CustomSwitch(
                              isEnabled: provider.isReminderEnabled,
                              onChanged: (value) {

                                provider.setReminderEnabled(value);

                              },
                            ),

                          ],
                        ),

                        const SizedBox(height: 24),

                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: AppContainer(
                gradient: AppColors.backGroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Button(
                    onTap: (){
                      if (provider.titleController.text.isEmpty) {
                        AppPopUp.showToast(message: "Please enter appointment title.");
                        return;
                      }
                      if (provider.dateController.text.isEmpty) {
                        AppPopUp.showToast(message: "Please select date.");
                        return;
                      }
                      if (provider.timerController.text.isEmpty) {
                        AppPopUp.showToast(message: "Please select time.");
                        return;
                      }
                      provider.addAppointmentApi();

                    },
                    height: 56,
                    child: provider.isLoading
                        ? customLoading(color: AppColors.white)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add,color: AppColors.white,),
                        SizedBox(width: 8,),
                        Text("Add Appointment",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),),
                      ],
                    ),
                  ),
                ),
              ),
            )

        )); }


}
