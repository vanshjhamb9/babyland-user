import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/basic_information/basic_information_provider.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_days_picker.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/switch_btn.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/storage/secure_storage.dart';

class BasicInfoView extends StatelessWidget {
  BasicInfoView({super.key});

  final PageController _pageController = PageController();

  final otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BasicInformationProvider>(
      create: (context) => BasicInformationProvider(),
      child: Consumer<BasicInformationProvider>(
        builder: (context, provider, _) {
          return  Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backGroundColor,
              ),
              child: Column(
                children: [
                  CustomAppBar(
                    centerTitle: true,
                    title: Text(
                      provider.currentIndex == 0 ?
                      "Last Period Details" : provider.currentIndex == 1 ? "Cycle Details" : provider.currentIndex == 2 ?"Average period length" : "Any Existing Conditions?",
                      style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroySemiBold),
                    ),
                    backgroundClr: AppColors.transparent,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                          (index1) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: 15,
                        decoration: BoxDecoration(
                          color: index1 <= provider.currentIndex ?  AppColors.buttonClr1 :AppColors.greyStroke,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 4,
                      onPageChanged: (value) {
                        provider.changeIndex(value);
                      },
                      itemBuilder:
                          (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              provider.currentIndex == 0 ?
                              lastPeriodDetails(provider, context) :
                              provider.currentIndex == 1 ?
                              cycleDetails(provider, context) : provider.currentIndex == 2 ?
                              averagePeriodLength(provider, context) :
                              existingConditions(provider),
                            ],
                          )
                        );
                      },),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: bottomNavBarBtn(provider, context),
          );
        },),
    );
  }

  Widget existingConditions(BasicInformationProvider provider) {
    return Expanded(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Help us understand your health better by selecting any conditions you've been diagnosed with.",
              textAlign: TextAlign.center,
              maxLines: 5,
              style:  AppFontStyle.text_16_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular),
            ),
            SizedBox(height: 28),
            ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: provider.existingConditions.length,
                itemBuilder:(context, index) => AppContainer(
                  height: 74,
                  color: AppColors.white,
                  isBordered: true,
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.grey.withValues(alpha: 0.25),
                          child: Icon(Icons.water_drop,color: AppColors.green,size: 20,),
                        ),
                        SizedBox(width: 10),
                        Text(
                         provider.existingConditions[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textClr),
                        ),
                        Spacer(),
                       /* Transform.scale(
                          scale: 0.8, // Thumb ko bada karne ke liye, 1.0 = default
                          child: Switch(
                            value: provider.existingConditionsSelected[index],
                            onChanged: (val) {
                              provider.toggleConditionSelection(index);
                            },
                            activeColor: AppColors.white,
                            inactiveThumbColor: AppColors.white,
                            inactiveTrackColor: AppColors.grey.withOpacity(0.2),
                            thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                                  (states) => null,
                            ),
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                            trackColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) {
                                return AppColors.buttonClr1;
                              }
                              return AppColors.grey.withOpacity(0.2);
                            }),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )*/
                        SizedBox(
                          width: 55,
                          height: 30,
                          child: CustomSwitch(
                            isEnabled: provider.existingConditionsSelected[index],
                            onChanged: (val) {
                              provider.toggleConditionSelection(index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                separatorBuilder: (context, index) => SizedBox(height: 10),),
            SizedBox(height: 16),
            Text("Add medical history if any?",
              style:  AppFontStyle.text_14_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),
            ),
            SizedBox(height: 5),
            CustomTextFormField(
              controller: provider.medicalReason,
              minLines: 4,
              maxLines: 200,
              borderColor: AppColors.borderColor,
              hintText: "Describe your medical history",
            ),
          ],
        ),
      ),
    );
  }

  Widget averagePeriodLength(BasicInformationProvider provider, BuildContext context) {
    return Column(
      children: [
        Text("How many days does your periods usually last?",
          textAlign: TextAlign.center,
          maxLines: 5,
          style:  AppFontStyle.text_24_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
        ),
        SizedBox(height: 30),
        Center(
          child: CustomDayPicker(
            onChanged: (value) {
              provider.setSelectedPeriodDay1(value);
            },
            height: mediaQueryH(context) * 0.55,
            controller: provider.controllerPeriodLength1,
            selectedDay: provider.selectedPeriodLengthDay1,
            showDays: true,
            daysLength: 31,
          ),
        ),
      ],
    );
  }

  Widget cycleDetails(BasicInformationProvider provider, BuildContext context) {
    return Column(
      children: [
        Text("How long does your cycle usually last?",
          textAlign: TextAlign.center,
          maxLines: 5,
          style:  AppFontStyle.text_24_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Button(
              onTap: () {
                provider.setIsRegular(true);
                provider.setSelectedDay1(15);
                provider.setSelectedDay2(16);
              },
              height: 49,
              width: 120,
              borderRadius: 12,
              gradient: provider.isRegular ? AppColors.buttonClr : null,
              color: provider.isRegular ? null : AppColors.white,
              border: Border.all(
                color: provider.isRegular ? Colors.transparent : AppColors.borderColor,
              ),
              text: "Regular",
              textStyle: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: provider.isRegular ? AppColors.white : AppColors.textClr,
              ),
            ),
            Button(
              onTap: () {
                provider.setIsRegular(false);
                provider.setSelectedDay1(15);
                provider.setSelectedDay2(16);
              },
              height: 49,
              width: 120,
              borderRadius: 12,
              gradient: !provider.isRegular ? AppColors.buttonClr : null,
              color: !provider.isRegular ? null : AppColors.white,
              border: Border.all(
                color: !provider.isRegular ? Colors.transparent : AppColors.borderColor,
              ),
              text: "Irregular",
              textStyle: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: !provider.isRegular ? AppColors.white : AppColors.textClr,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if(provider.isRegular)...[
        CustomDayPicker(
          onChanged: (value) {
            provider.setSelectedDay1(value);
          },
          height: mediaQueryH(context) * 0.48,
          controller: provider.controllerCycle1,
          selectedDay: provider.selectedCycleDay1,
          showDays: true,
          daysLength: 30,
        ),
      ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: CustomDayPicker(
                  onChanged: (value) {
                    provider.setSelectedDay1(value);
                  },
                  height: mediaQueryH(context) * 0.48,
                  controller: provider.controllerCycle1,
                  selectedDay: provider.selectedCycleDay1,
                  showDays: false,
                  daysLength: 30,
                ),
              ),
              Text("–", style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.buttonClr1,
              ),),
              SizedBox(
                width: 120, // fixed width for second picker
                child: CustomDayPicker(
                  onChanged: (value) {
                    provider.setSelectedDay2(value);
                  },
                  height: mediaQueryH(context) * 0.48,
                  controller: provider.controllerCycle2,
                  selectedDay: provider.selectedCycleDay2,
                  daysLength: 31,
                  disableBelow: provider.selectedCycleDay1,
                ),
              ),
            ],
          )
        ],
      ],
    );
  }

  Widget lastPeriodDetails(BasicInformationProvider provider, BuildContext context) {
    return Column(
      children: [
        AppContainer(
          color: AppColors.white,
          isBordered: true,
          radius: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImage(path: ImageConstants.calendar),
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Your Last Period Start Date",
                        style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "When did your last period start?",
                        style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  "Select Date",
                  style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.black),
                ),
                SizedBox(height: 6),
                CustomTextFormField(
                  readOnly: true,
                  controller: provider.dateController,
                  hintText: "DD-MM-YYYY",
                  borderColor: AppColors.borderColor,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());

                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.backgroundClr2, // header & selected day
                              onPrimary: AppColors.white,        // text on selected day
                              onSurface: AppColors.textClr,      // normal day text
                              surface: AppColors.white,          // dialog background
                            ),

                            // Buttons (CANCEL / OK)
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textClr,
                                textStyle: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroySemiBold,
                                  color: AppColors.textClr,
                                ),
                              ),
                            ),

                            // Header (Month + Year)
                            textTheme: TextTheme(
                              titleLarge: AppFontStyle.text_18_600(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.textClr,
                              ),
                            ),

                            // Picker theme
                            datePickerTheme: DatePickerThemeData(
                              headerBackgroundColor: AppColors.backgroundClr2,
                              headerForegroundColor: AppColors.textClr,
                              dayForegroundColor: WidgetStateProperty.all(AppColors.textClr),
                              weekdayStyle: AppFontStyle.text_14_400(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.textClr,
                              ),
                              todayBackgroundColor:
                              WidgetStateProperty.all(AppColors.buttonClr1.withOpacity(0.3)),
                              todayForegroundColor: WidgetStateProperty.all(AppColors.buttonClr1),
                              dayOverlayColor: WidgetStateProperty.all(
                                AppColors.buttonClr2.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      provider.dateController.text =
                      "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        //-------------------------------------------------------------------------
        SizedBox(height: 28),
        AppContainer(
          isBordered: true,
          borderColor: AppColors.borderColor,
          color: AppColors.white,
          radius: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,size: 24),
                    SizedBox(width: 10),
                    Text("Why We Need This Information",
                      style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              bulletPointText(" Helps us calculate your current and upcoming menstrual cycles."),
              bulletPointText(" Predicts ovulation and fertile days for planning or avoiding pregnancy."),
              bulletPointText(" Anticipates when cramps, mood swings, or fatigue may occur."),
              bulletPointText(" Sends notifications for next period or ovulation days."),
              ],
            ),
          ),
        )
      ],
    );
  }

  Padding bulletPointText(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(" • "),
          Expanded(
            child: Text(
              title,
              maxLines: 4,
              style: AppFontStyle.text_14_400(
                color: AppColors.lightGrey,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget bottomNavBarBtn(BasicInformationProvider provider, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: AppColors.backGroundColor
      ),
      height: 100,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14,vertical: 24),
        child: Button(
          height: 58,
          onTap: ()async{
              if(provider.currentIndex == 0){
                if( provider.dateController.text.isEmpty){
                  AppPopUp.showToast(message: "Please select date",lineColor: AppColors.red);
                }else{
                  _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                }
              }else if(provider.currentIndex == 1){
                _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
              }else if(provider.currentIndex == 2){
                _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
              }else if(provider.currentIndex == 3){
                if(provider.selectedConditions.isEmpty && provider.medicalReason.text.isEmpty){
                  AppPopUp.showToast(message: "Please select any option or describe any reason",lineColor: AppColors.red);
                }else{
                  provider.onboardingCompleteApi();
                }
                // pt(provider.selectedConditions.toString());
                // _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
              }
          },
          child:provider.onboardingApiData?.status == ApiStatus.LOADING ? customLoading(color: AppColors.white) : Text("Continue",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),),
        ),
      ),
    );
  }
}
