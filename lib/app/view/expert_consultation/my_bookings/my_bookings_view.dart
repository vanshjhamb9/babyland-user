import 'package:babyland/app/agora/video_call_controller.dart';
import 'package:babyland/app/agora/video_call_screen.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/texttield_title.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/accesscontextmanager/v1.dart';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controller/experts_consultation/experts_consultation_controller.dart';
import '../../../controller/experts_consultation/model/booking_data_model.dart';
import '../../../data/response/status.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({super.key});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().getBookingApi(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingController>();
    final apiData = provider.bookingApiData;

    return Scaffold(
      appBar: CustomAppBar(
        isIosBackBtn: true,
        title: Text(
          "My Bookings",
          style: AppFontStyle.text_18_600(
            fontFamily: AppFontFamily.gilroyMedium,
            color: AppColors.textClr,
          ),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            AppContainer(
              radius: 12,
              color: AppColors.lightWhite,
              child: Row(
                children: List.generate(2, (index) {
                  final titles = ["Upcoming", "Past"];
                  final isSelected = provider.selectedTabIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => provider.setSelectedTab(index),
                      child: AppContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        radius: 12,
                        color: isSelected ? AppColors.white : AppColors.lightWhite,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Center(
                          child: Text(
                            titles[index],
                            style: AppFontStyle.text_16_600(
                              fontFamily: isSelected ? AppFontFamily.gilroyMedium : AppFontFamily.gilroyRegular,
                              color: AppColors.textClr,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: switch (provider.bookingApiData?.status) {
                ApiStatus.LOADING => Center(
                  child: _buildShimmerList() ,
                ),

                ApiStatus.COMPLETED => _buildBookingsList(apiData?.data?.bookings ?? [], provider.selectedTabIndex),

                ApiStatus.ERROR => Center(
                  child: Text(
                    provider.bookingApiData?.message ?? "Something went wrong",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

                _ => const SizedBox(), // null / default
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, int selectedTabIndex) {

    if (bookings.isEmpty) {
      return const CustomNoDataFound(isClr: false);
    }

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking =bookings[index];
        return Card(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AppContainer(
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Order ID: ${booking.sId ?? 'N/A'}",
                  style: AppFontStyle.text_16_600(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order Date: ${_formatDateTime(booking.date)} - ${booking.time ?? ''}",
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomImage(
                      path: ImageConstants.networkImageDemo,
                      h: 64,
                      w: 64,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                booking.doctorId?.name?.capitalizeFirst() ?? "", // Replace with real doctor name if available
                                style: AppFontStyle.text_16_600(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.textClr,
                                ),
                              ),
                              Spacer(),
                              InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => VideoCallScreen()));
                                },
                                child: Icon(Icons.video_camera_back_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Specialty", // Replace with doctor specialty if available
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: AppColors.textClr,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: AppColors.black),
                              const SizedBox(width: 4),
                              Text(
                                "1.0 km away",
                                style: AppFontStyle.text_13_400(
                                  fontFamily: AppFontFamily.gilroyRegular,
                                  color: AppColors.textClr,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.star, color: AppColors.orangeClr, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                "4.8",
                                style: AppFontStyle.text_13_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.textClr,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (selectedTabIndex == 0) Row(
                  children: [
                    Expanded(
                      child: AppContainer(
                        onTap: () => context.read<ExpertConsultationProvider>().cancelBookingApi(id: booking.sId ?? ""),
                        radius: 12,
                        color: AppColors.greyLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: context.read<ExpertConsultationProvider>().cancelBooking?.status != ApiStatus.LOADING ? customLoading(color: AppColors.primary) : Text(
                            "Cancel",
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.textClr,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        height: 44,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.doctorProfileView,arguments: {
                          "doctorId" : booking.doctorId ?? "",
                        }),
                        child: Center(
                          child: Text(
                            "View Details",
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ) else Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.recordsView,
                            arguments: {
                              'doctorId': booking.doctorId ?? "",
                            },
                          );
                        },
                        child: AppContainer(
                          radius: 12,
                          color: AppColors.greyLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              "Write a Review",
                              style: AppFontStyle.text_16_500(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.textClr,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        height: 44,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.doctorProfileView,arguments: {
                          "doctorId" : booking.doctorId ?? "",
                        }),
                        child: Center(
                          child: Text(
                            "Book Again",
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              // Add layout placeholders similar to your real UI
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "-";
    return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  }
}
