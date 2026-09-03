import 'package:babyland/app/controller/experts_consultation/model/doctor_data_model.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:intl/intl.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';

class DoctorProfileView extends StatefulWidget {
  const DoctorProfileView({super.key});

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  String doctorId = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final raw = args?['doctorId'];
      doctorId = raw is String
          ? raw
          : (raw is Map ? (raw['_id'] ?? raw['id'])?.toString() : null) ?? "";
      pt(name: "doctor id", doctorId);
      if (doctorId.isNotEmpty) {
        context.read<ExpertConsultationProvider>().doctorDetailApiData(
          doctorId: doctorId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      body: Consumer<ExpertConsultationProvider>(
        builder: (context, provider, _) {
          final doctorData =
              (provider.doctorApiData?.data?.data != null &&
                  provider.doctorApiData!.data!.data!.isNotEmpty)
              ? provider.doctorApiData!.data!.data!.first
              : null;
          return SafeArea(
            child: AppContainer(
              gradient: AppColors.backGroundColor,
              // padding: EdgeInsets.symmetric(horizontal: 14),
              child: RefreshIndicator(
                onRefresh: () =>
                    provider.doctorDetailApiData(doctorId: doctorId),
                child: switch (provider.doctorApiData?.status) {
                  ApiStatus.LOADING => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: doctorShimmer(),
                  ),

                  ApiStatus.COMPLETED =>
                    doctorData == null ||
                            (provider.doctorApiData?.data?.data?.isEmpty ??
                                false)
                        ? CustomNoDataFound(isClr: false)
                        : body(context, doctorData, provider),

                  ApiStatus.ERROR => GeneralExceptionWidget(
                    onPress: () =>
                        provider.doctorDetailApiData(doctorId: doctorId),
                  ),
                  _ => SizedBox(),
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<ExpertConsultationProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppContainer(
                    radius: 20,
                    color: AppColors.grey.withAlpha(80),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomImage(path: ImageConstants.chatIcon),
                    ),
                  ),
                  Button(
                    onTap: () async {
                      final checkout = context
                          .read<ConsultationCheckoutController>();

                      pt("this is date ${provider.selectedTimeIndex}");
                      pt("this is time ${provider.selectedIndex}");

                      if (provider.selectedIndex == -1) {
                        AppPopUp.showToast(
                          message: "Please select date...",
                          lineColor: AppColors.red,
                        );
                      } else if (provider.selectedTimeIndex == -1) {
                        AppPopUp.showToast(
                          message: "Please select time..",
                          lineColor: AppColors.red,
                        );
                      } else if (doctorId.isEmpty) {
                        AppPopUp.showToast(
                          message: "Doctor not found.",
                          lineColor: AppColors.red,
                        );
                      } else if (provider.selectedDate == null) {
                        AppPopUp.showToast(
                          message: "Please select a date...",
                          lineColor: AppColors.red,
                        );
                      } else {
                        pt("this is date ${provider.selectedDate}");
                        pt("this is time ${provider.selectedTime}");
                        provider.setSelectedDoctorId(doctorId);
                        checkout.clearForNewFlow();

                        final dateStr = provider.formatDate(
                          provider.selectedDate!,
                        );
                        final timeStr = provider.selectedTime ?? "";

                        final locked = await checkout.requestSlotLock(
                          doctorId: doctorId,
                          slotDate: dateStr,
                          slotTime: timeStr,
                        );
                        if (!context.mounted) return;
                        if (!locked.ok) {
                          AppPopUp.showToast(
                            message:
                                locked.message ??
                                "Unable to reserve this slot. Try another time.",
                            lineColor: AppColors.red,
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookingsView,
                          arguments: {
                            'appointmentDate': provider.selectedDate
                                ?.toString(),
                            'appointmentTime': timeStr,
                            'doctorId': doctorId.toString(),
                          },
                        );
                      }
                    },
                    width: mediaQueryW(context) * 0.75,
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Book Appointment",
                          style: AppFontStyle.text_16_600(
                            color: AppColors.white,
                            fontFamily: AppFontFamily.gilroySemiBold,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget body(
    BuildContext context,
    Doctor? doctorData,
    ExpertConsultationProvider provider,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CustomImage(
                path: ImageConstants.networkImageDemo,
                w: mediaQueryW(context),
              ),
              appbar(),
            ],
          ),
          SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  capitalizeFirstLetter(doctorData?.name ?? ""),
                  style: AppFontStyle.text_18_600(
                    color: AppColors.textClr,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.orangeClr, size: 15),
                    SizedBox(width: 2),
                    Text(
                      "${doctorData?.doctorDetails?.totalAvgRating}",
                      style: AppFontStyle.text_12_400(
                        color: AppColors.textClr,
                        fontFamily: AppFontFamily.gilroySemiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cardiologist",
                  style: AppFontStyle.text_12_400(
                    color: AppColors.black,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${doctorData?.doctorDetails?.consultationFee}",
                      style: AppFontStyle.text_18_600(
                        color: AppColors.textClr,
                        fontFamily: AppFontFamily.gilroyMedium,
                      ),
                    ),
                    Text(
                      "Consultation Fee",
                      style: AppFontStyle.text_12_400(
                        color: AppColors.black,
                        fontFamily: AppFontFamily.gilroyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "Description",
              style: AppFontStyle.text_14_600(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "Dedicated and experienced [specialty] with a passion for providing compassionate, patient-centered care. With [number] years in the field, Dr. [Name] combines cutting-edge medical knowledge with a commitment to understanding each patient's unique needs. ",
              maxLines: 100,
              style: AppFontStyle.text_13_400(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "Select Appointment Date ",
              style: AppFontStyle.text_14_600(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(30, (index) {
                DateTime date = provider.today.add(Duration(days: index));
                String dayName = DateFormat('E').format(date);
                String dayNumber = DateFormat('d').format(date);

                bool isSelected = index == provider.selectedIndex;

                return GestureDetector(
                  onTap: () {
                    provider.setSelectedIndex(index);
                    provider.pickDate(date);
                  },
                  child: AppContainer(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 14 : 8,
                      top: 10,
                      bottom: 10,
                    ),
                    padding: EdgeInsets.all(8),
                    radius: 4,
                    gradient: isSelected
                        ? AppColors.buttonClr
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade300,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: AppFontStyle.text_11_400(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.textClr,
                              fontFamily: isSelected
                                  ? AppFontFamily.gilroySemiBold
                                  : AppFontFamily.gilroyMedium,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            dayNumber,
                            style: AppFontStyle.text_14_600(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.textClr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              "Select Appointment Time",
              style: AppFontStyle.text_14_600(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
          SizedBox(height: 8),
          // DOC-01/DOC-02: real available slots from API.
          // Route through the endpoint-agnostic state slot so the live-slots
          // flag (§8) covers this widget too.
          Builder(
            builder: (_) {
              final useLive = ExpertConsultationProvider.useLiveSlotsEndpoint;
              final ApiStatus? slotStatus = useLive
                  ? provider.liveSlots?.status
                  : provider.getAvailableSlot?.status;
              final List<({String time, bool bookable})> slots = useLive
                  ? (provider.liveSlots?.data?.slots
                            .map((s) => (time: s.time, bookable: s.isBookable))
                            .toList() ??
                        const [])
                  : (provider.getAvailableSlot?.data?.data
                            ?.map(
                              (d) => (
                                time: d.time ?? '',
                                bookable: d.status == true,
                              ),
                            )
                            .toList() ??
                        const []);
              final bookableSlots = slots.where((s) => s.bookable).toList();

              // No date selected yet
              if (provider.selectedDate == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "Select a date to see available slots",
                    style: AppFontStyle.text_12_400(
                      color: AppColors.textLightClr,
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                );
              }

              // Loading shimmer
              if (slotStatus == ApiStatus.LOADING) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      4,
                      (i) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: AppContainer(
                          margin: EdgeInsets.only(
                            left: i == 0 ? 14 : 8,
                            top: 10,
                            bottom: 10,
                          ),
                          width: 80,
                          height: 36,
                          radius: 4,
                          color: Colors.grey.shade300,
                          child: const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                );
              }

              // No slots available
              if (bookableSlots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "No slots available for this date",
                    style: AppFontStyle.text_12_400(
                      color: AppColors.textLightClr,
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                );
              }

              // Render real slots
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: bookableSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    final isSelected = index == provider.selectedTimeIndex;
                    return GestureDetector(
                      onTap: () {
                        provider.setSelectedTimeIndex(index);
                        provider.pickTime(slot.time);
                      },
                      child: AppContainer(
                        margin: EdgeInsets.only(
                          left: index == 0 ? 14 : 8,
                          top: 10,
                          bottom: 10,
                        ),
                        padding: const EdgeInsets.all(8),
                        radius: 4,
                        gradient: isSelected
                            ? AppColors.buttonClr
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            slot.time,
                            style: AppFontStyle.text_11_400(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.textClr,
                              fontFamily: isSelected
                                  ? AppFontFamily.gilroySemiBold
                                  : AppFontFamily.gilroyMedium,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_vert, color: AppColors.black),
        ),
      ],
    );
  }

  Widget doctorShimmer() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 20),

          // Name & Rating
          Container(height: 20, width: 180, color: Colors.grey.shade300),
          SizedBox(height: 10),
          Container(height: 14, width: 120, color: Colors.grey.shade300),

          SizedBox(height: 20),

          // Description title
          Container(height: 18, width: 140, color: Colors.grey.shade300),
          SizedBox(height: 10),

          // Description text
          ...List.generate(
            10,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 12,
                width: double.infinity,
                color: Colors.grey.shade300,
              ),
            ),
          ),

          SizedBox(height: 20),

          // Date selector
          Container(height: 18, width: 180, color: Colors.grey.shade300),
          SizedBox(height: 14),
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),

          SizedBox(height: 20),

          // Time selector
          Container(height: 18, width: 180, color: Colors.grey.shade300),
          SizedBox(height: 14),
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
