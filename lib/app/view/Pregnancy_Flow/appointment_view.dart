import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/images.dart';
import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';
import '../../widgets/custom_image.dart';

class AppointmentView extends StatefulWidget {
  const AppointmentView({super.key});

  @override
  State<AppointmentView> createState() => _AppointmentViewState();
}

class _AppointmentViewState extends State<AppointmentView> {
  @override
  void initState() {
    super.initState();
    // Fetch appointment data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PregnancyController>(context, listen: false).getAppointmentApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PregnancyController>(
      builder: (context, provider, _) {
        if (provider.isLoadingData) {
          return Scaffold(
            appBar: CustomAppBar(
              title: Text("Add Appointment",
                style: AppFontStyle.text_20_400(
                    color: AppColors.textClr,
                    fontFamily: AppFontFamily.gilroyBold),
              ),
              centerTitle: true,
              // actions: [
              //   Padding(
              //     padding: const EdgeInsets.only(right: 24.0),
              //     child: CustomImage(path: "assets/images/mic.png", scale: 5),
              //   ),
              // ],
            ),
            body: AppContainer(
              color: AppColors.backgroundClr,
              gradient: AppColors.backGroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming Appointments",
                      style: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.black),
                    ),
                    const SizedBox(height: 18),
                    // Build shimmer placeholders (e.g. 3 items)
                    _buildShimmerItem(),
                    const SizedBox(height: 12),
                    _buildShimmerItem(),
                    const SizedBox(height: 12),
                    _buildShimmerItem(),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.appointmentApiData?.status == false) {
          // Show Error if API failed
          return Scaffold(
            appBar: CustomAppBar(
              title: Text("Add Appointment",
                style: AppFontStyle.text_20_400(
                    color: AppColors.textClr,
                    fontFamily: AppFontFamily.gilroyBold),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: CustomImage(path: "assets/images/mic.png", scale: 5),
                ),
              ],
            ),
            body: Center(
              child: Text(
                provider.appointmentApiData?.message ?? "Something went wrong!",
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }

         final appointments = provider.appointmentApiData?.data?.data ?? [];

        return Scaffold(
          appBar: CustomAppBar(
            title: Text(
              "Add Appointment",
              style: AppFontStyle.text_20_400(
                color: AppColors.textClr,
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
            centerTitle: true,
            // actions: [
            //   Padding(
            //     padding: const EdgeInsets.only(right: 24.0),
            //     child: CustomImage(path: "assets/images/mic.png", scale: 5),
            //   ),
            // ],
          ),
          body: AppContainer(
            color: AppColors.backgroundClr,
            gradient: AppColors.backGroundColor,
            child: RefreshIndicator(
              onRefresh: () =>provider.getAppointmentApi(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upcoming Appointments",
                      style: AppFontStyle.text_16_400(
                        fontFamily: AppFontFamily.gilroySemiBold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    appointments.isEmpty
                        ? CustomNoDataFound(isClr: false,heightBox: SBox(h: 50),)
                        : Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppContainer(
                              color: AppColors.white,
                              radius: 8,
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CustomImage(
                                          path: ImageConstants.scan, scale: 4),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment.title ?? "",
                                            style: AppFontStyle.text_15_400(
                                                fontFamily:
                                                AppFontFamily.gilroySemiBold),
                                          ),
                                          const SizedBox(height: 7),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "${provider.formatApiDate(appointment.date.toString())} - ${appointment.time ?? ""}",
                                                style: AppFontStyle.text_13_400(
                                                  fontFamily:
                                                  AppFontFamily.gilroyMedium,
                                                  color: AppColors.textLightClr,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  CustomImage(
                                    path: appointment.reminder == true
                                        ? ImageConstants.notification
                                        : ImageConstants.notificationoff,
                                    scale: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
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
                onTap: () async{
                  final result = await Navigator.pushNamed(context, AppRoutes.addReminderView);
                  if (result == true) {
                    Provider.of<PregnancyController>(context, listen: false).getAppointmentApi();
                  }
                },
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: AppColors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Add Appointment",
                      style: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroyBold, color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerItem() {
    return AppContainer(
      color: AppColors.white,
      radius: 8,
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 120,
                      height: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 18,
              height: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

}
