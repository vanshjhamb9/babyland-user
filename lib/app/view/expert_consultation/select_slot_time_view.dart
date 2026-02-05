import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/experts_consultation/model/availableslotdatamodel.dart';
import '../../data/response/status.dart';
import '../../widgets/general_exception.dart'; // Assuming you have CustomNoDataFound too
import '../../widgets/custom_no_data_found.dart'; // Add if missing

class SelectSlotTimeView extends StatefulWidget {
  const SelectSlotTimeView({super.key});

  @override
  State<SelectSlotTimeView> createState() => _SelectSlotTimeViewState();
}

class _SelectSlotTimeViewState extends State<SelectSlotTimeView> {
  String? time;
  String? date;
  String? doctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      date = args?['appointmentDate'];
      time = args?['appointmentTime'];
      doctorId = args?['doctorId'];
      context.read<ExpertConsultationProvider>().getAvailableSlotApiData(date: DateTime.parse(date.toString()));
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
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: () => provider.getAvailableSlotApiData(date:DateTime.parse(date.toString())),
              child: switch (provider.getAvailableSlot?.status) {
                ApiStatus.LOADING => _buildShimmerLoading(),
                ApiStatus.COMPLETED => _buildCompletedUI(provider),
                ApiStatus.ERROR => GeneralExceptionWidget(
                  onPress: () => provider.getAvailableSlotApiData(date: DateTime.parse(date.toString())),
                ),
                _ => const SizedBox(),
              },
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading UI
  Widget _buildShimmerLoading() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) => AppContainer(
        radius: 8,
        padding: const EdgeInsets.all(12),
        color: AppColors.white,
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 14, width: 80, color: Colors.white),
                  Container(height: 20, width: 20, color: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      height: 30,
                      width: 80,
                      color: Colors.white,
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }

  // Handle completed state - check empty data
  Widget _buildCompletedUI(ExpertConsultationProvider provider) {
    final model = provider.getAvailableSlot?.data;
    if (model?.data == null || model!.data!.isEmpty) {
      return CustomNoDataFound(isClr: false);
    }
    return _buildSlotsList(provider, model);
  }

  // Dynamic slots list from API data
  Widget _buildSlotsList(ExpertConsultationProvider provider, AvailableSlotDataModel model) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: 1,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            final isCardSelected = provider.slotIndex != -1;
            final isTimeSelected = isCardSelected && provider.selectedShiftIndex[provider.slotIndex] != -1;
            if (isCardSelected && isTimeSelected) {
              Navigator.pushNamed(context, AppRoutes.bookingsView, arguments: {
                'appointmentDate': date?.toString(),
                'appointmentTime': time?.toString(),
                'doctorId': doctorId?.toString(),
              });
            } else {
              AppPopUp.showToast(message: "Please select date & time slot", lineColor: AppColors.red);
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
                Text(
                  provider.formatDateMMMMddyyyy(DateTime.parse(date.toString())),
                  style: AppFontStyle.text_16_600(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.getDayName(DateTime.parse(date.toString())),
                      style: AppFontStyle.text_12_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textLightClr,
                      ),
                    ),
                    GradientCheckbox(
                      value: provider.slotIndex == index ? provider.isSelectedTimeSlot : false,
                      onChanged: (val) => provider.setIsSelectedTimeSlot(val, index),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: model.data!
                        .asMap()
                        .entries
                        .where((entry) => entry.value.status == true) // Only available slots
                        .map((entry) {
                      final slotIndex = entry.key;
                      final datum = entry.value;
                      final isSelectedShift = provider.getShiftIndexForSlot(index) == slotIndex;
                      final isSlotSelected = provider.slotIndex == index && provider.isSelectedTimeSlot;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: InkWell(
                          highlightColor: AppColors.transparent,
                          splashColor: AppColors.transparent,
                          onTap: isSlotSelected ? () => provider.setShiftIndex(slotIndex, index) : null,
                          child: Opacity(
                            opacity: isSlotSelected ? 1.0 : 0.5,
                            child: AppContainer(
                              radius: 4,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              gradient: isSelectedShift && isSlotSelected
                                  ? AppColors.buttonClr
                                  : LinearGradient(
                                colors: [Colors.grey.shade100, Colors.grey.shade200],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              child: Text(
                                datum.time ?? "",
                                style: AppFontStyle.text_12_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: isSelectedShift && isSlotSelected ? AppColors.white : AppColors.textLightClr,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text(
        "Select Time Slot",
        style: AppFontStyle.text_18_600(
          color: AppColors.textClr,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}
