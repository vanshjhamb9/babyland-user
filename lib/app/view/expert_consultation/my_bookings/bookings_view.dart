import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_family.dart';
import '../../../theme/font_style.dart';
import '../../../widgets/general_exception.dart';
import '../../../widgets/print.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
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

      // ✅ Use existing provider (no new instance)
      final provider = context.read<ExpertConsultationProvider>();
      provider.doctorDetailApiData(doctorId: doctorId ?? "");

      pt("appointmentTime: $time >>> appointmentDate: $date >>> doctorId: $doctorId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),
      body: Consumer<ExpertConsultationProvider>(
        builder: (context, provider, _) {
          // ✅ Handle all API states like your doctor screen
          return switch (provider.doctorApiData?.status) {
            ApiStatus.LOADING => _buildLoadingShimmer(),
            ApiStatus.COMPLETED => _buildSuccessUI(provider),
            ApiStatus.ERROR => GeneralExceptionWidget(
              onPress: () => provider.doctorDetailApiData(doctorId: doctorId ?? ""),
            ),
            _ => _buildLoadingShimmer(),
          };
        },
      ),
    );
  }

  // Shimmer loading
  Widget _buildLoadingShimmer() {
    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradient: AppColors.backGroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Doctor card shimmer
          Container(
            height: 120,
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.buttonClr,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 20),
          // Price shimmer
          ...List.generate(4, (i) => Container(
            height: 20,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: Colors.grey[300],
          )),
        ],
      ),
    );
  }

  // Success UI with doctor data
  Widget _buildSuccessUI(ExpertConsultationProvider provider) {
    final data = provider.doctorApiData?.data?.data?.first;
    double total = (data?.doctorDetails?.consultationFee ?? 0) + 10.0;

    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradient: AppColors.backGroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor info card
          AppContainer(
            radius: 12,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            gradient: AppColors.buttonClr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomImage(
                  path: ImageConstants.networkImageDemo,
                  h: 88,
                  w: 88,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data?.name?.toString() ?? "Doctor Name",
                        style: AppFontStyle.text_16_600(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Specialty",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.white,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.star, color: AppColors.orangeClr, size: 18),
                          SizedBox(width: 2),
                          Text(
                            data?.doctorDetails?.totalReviewCount?.toString() ?? "0",
                            style: AppFontStyle.text_14_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.white),
                          SizedBox(width: 4),
                          Text(
                            "1 hour consultation",
                            style: AppFontStyle.text_16_500(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),

          // Appointment Cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Appointment Cost",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                "\$${data?.doctorDetails?.consultationFee?.toString() ?? '0'}",
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          Text(
            "Consultation fee for 1 hour",
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyRegular,
              color: AppColors.textLightClr,
            ),
          ),
          SizedBox(height: 14),

          // Admin Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Admin Fee",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                "\$10.00",
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Coupon
          CustomTextFormField(
            height: 60,
            borderColor: AppColors.borderColor,
            labelText: "Enter Coupon",
            suffix: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: AppContainer(
                gradient: AppColors.buttonClr,
                radius: 8,
                width: 120,
                child: Center(
                  child: Text(
                    "Apply",
                    style: AppFontStyle.text_16_500(
                      fontFamily: AppFontFamily.gilroyBold,
                      color: AppColors.textClr,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 26),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: AppFontStyle.text_16_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
              Text(
                "\$${total.toStringAsFixed(0)}",
                style: AppFontStyle.text_18_500(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          // RazorPay
          AppContainer(
            radius: 8,
            color: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: InkWell(
              onTap: () => provider.toggleRazorPay(),
              child: Row(
                children: [
                  CustomImage(path: ImageConstants.razorpayLogo),
                  SizedBox(width: 8),
                  Text(
                    "Razor Pay",
                    style: AppFontStyle.text_18_500(
                      fontFamily: AppFontFamily.gilroySemiBold,
                      color: AppColors.textClr,
                    ),
                  ),
                  Spacer(),
                  Transform.scale(
                    scale: 1.4,
                    child: Radio<bool>(
                      value: true,
                      groupValue: provider.isRazorPaySelected ? true : null,
                      onChanged: (_) => provider.toggleRazorPay(),
                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.buttonClr1;
                        }
                        return Colors.grey.shade400;
                      }),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacer(),

          // Add New Card
          Button(
            borderRadius: 8,
            gradient: LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImage(path: ImageConstants.card),
                SizedBox(width: 12),
                Text(
                  "Add New Card",
                  style: AppFontStyle.text_18_500(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          // Next Button
          Button(
            onTap: () => provider.addBookingApi(date: date ?? "", time: time ?? ""),
            borderRadius: 8,
            child: provider.addBooking?.status == ApiStatus.LOADING
                ? customLoading()
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Next",
                  style: AppFontStyle.text_18_500(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.white),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text(
        "My Booking",
        style: AppFontStyle.text_18_600(
          color: AppColors.textClr,
          fontFamily: AppFontFamily.gilroyMedium,
        ),
      ),
    );
  }
}
