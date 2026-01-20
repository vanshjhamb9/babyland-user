import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectSlotTimeView extends StatefulWidget {
  const SelectSlotTimeView({super.key});

  @override
  State<SelectSlotTimeView> createState() => _SelectSlotTimeViewState();
}

class _SelectSlotTimeViewState extends State<SelectSlotTimeView> {

  String? time;
  String? date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments
      as Map<String, dynamic>?;

      date = args?['appointmentDate'];
      time = args?['appointmentTime'];

      pt("appointmentTime: $time  >>>  appointmentDate: $date");
      setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),

      body: AppContainer(
        gradient: AppColors.backGroundColor,
        height: mediaQueryH(context),
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Consumer<ExpertConsultationProvider>(
          builder: (context,provider,_) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: 3,
              itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  bool isCardSelected = provider.slotIndex != -1;
                  bool isTimeSelected = isCardSelected &&
                      provider.selectedShiftIndex[provider.slotIndex] != -1;

                  if (isCardSelected && isTimeSelected) {
                    Navigator.pushNamed(context, AppRoutes.bookingsView,
                      arguments: {
                        'appointmentDate': date?.toString(),
                        'appointmentTime': time?.toString(),
                      },);
                  } else {
                    AppPopUp.showToast(
                      message: "Please select date & time slot",
                      lineColor: AppColors.red,
                    );
                  }
                },
                child: AppContainer(
                  radius: 8,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("March 14,2022",style: AppFontStyle.text_16_600(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textClr),),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Thursday",style: AppFontStyle.text_12_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.textLightClr),),
                          GradientCheckbox(
                            value:provider.slotIndex == index ? provider.isSelectedTimeSlot : false,
                            onChanged: (val){
                                provider.setIsSelectedTimeSlot(val,index);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(3, (index1) {
                            final isSelectedShift = provider.getShiftIndexForSlot(index) == index1;

                            final isSlotSelected = provider.slotIndex == index && provider.isSelectedTimeSlot;

                            return InkWell(
                              highlightColor: AppColors.transparent,
                              splashColor: AppColors.transparent,
                              onTap: isSlotSelected
                                  ? () {
                                  provider.setShiftIndex(index1, index);

                              }
                                  : null,
                              child: Opacity(
                                opacity: isSlotSelected ? 1.0 : 0.5,
                                child: AppContainer(
                                  radius: 4,
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                  margin: const EdgeInsets.only(right: 12.0),
                                  gradient: isSelectedShift && isSlotSelected
                                      ? AppColors.buttonClr
                                      : LinearGradient(
                                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  child: Text(
                                    "Shift A: 8am To 8pm",
                                    style: AppFontStyle.text_12_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: isSelectedShift && isSlotSelected
                                          ? AppColors.white
                                          : AppColors.textLightClr,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
                   separatorBuilder: (context, index) => SizedBox(height: 10),);
          }
        ),
      ),

    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text("Select Time Slot",style: AppFontStyle.text_18_600(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),),
    );
  }
}
