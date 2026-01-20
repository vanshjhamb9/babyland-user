import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
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
import '../../../widgets/print.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {

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
    return ChangeNotifierProvider<ExpertConsultationProvider>(
      create: (context) => ExpertConsultationProvider(),
      builder: (context, child) =>  Scaffold(
        appBar: appbar(),
        body: Consumer<ExpertConsultationProvider>(
          builder: (context,provider,_) {
            return AppContainer(
              padding: EdgeInsets.symmetric(horizontal: 14,vertical: 10),
              gradient: AppColors.backGroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppContainer(
                    radius: 12,
                    padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                    gradient: AppColors.buttonClr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomImage(path: ImageConstants.networkImageDemo,h: 88,w: 88,borderRadius: BorderRadius.circular(8),),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Doctor Name",style: AppFontStyle.text_16_600(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.white),),
                              SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Specialty",style: AppFontStyle.text_15_400(fontFamily: AppFontFamily.gilroyMedium,color: AppColors.white)),
                                  Spacer(),
                                  Icon(Icons.star,color: AppColors.orangeClr,size: 18),
                                  SizedBox(width: 2),
                                  Text("4.8",style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.white))
                                ],
                              ),
                              SizedBox(height:8),
                              Row(
                                children: [
                                  Icon(Icons.access_time,size: 18,color: AppColors.white),
                                  SizedBox(width: 4),
                                  Text("1 hour consulation",style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Appointment Cost",style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                      Text("\$156.00",style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                    ],
                  ),
                  Text("Consultation fee for 1 hour",style: AppFontStyle.text_12_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textLightClr)),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Admin Fee",style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                      Text("\$10.00",style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                    ],
                  ),
                  SizedBox(height: 8),
                  CustomTextFormField(
                    height: 60,
                    borderColor: AppColors.borderColor,
                    labelText: "Enter Coupon",
                    suffix: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8,horizontal: 8),
                      child: AppContainer(
                        gradient: AppColors.buttonClr,
                        radius: 8,
                        width: 120,
                        child: Center(child: Text("Apply",style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroyBold,color: AppColors.textClr))),
                      ),
                    ),
                  ),
                  SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total",style: AppFontStyle.text_16_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                      Text("\$140.00",style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                    ],
                  ),
                  SizedBox(height: 18),
            Consumer<ExpertConsultationProvider>(
            builder: (context, provider, _) {
              return AppContainer(
                radius: 8,
                color: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: InkWell(
                  onTap: () {
                    // Tap the whole tile toggles selection
                    provider.toggleRazorPay();
                  },
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
                          // groupValue must be `true` when selected, `null` when not selected
                          groupValue: provider.isRazorPaySelected ? true : null,
                          onChanged: (_) {
                            // Radio gets toggled through provider
                            provider.toggleRazorPay();
                          },
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                (states) {
                              if (states.contains(MaterialState.selected)) {
                                return AppColors.buttonClr1;
                              }
                              return Colors.grey.shade400;
                            },
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
                  Spacer(),
                  Button(
                    borderRadius: 8,
                    gradient: LinearGradient(colors:  [Colors.grey.shade300, Colors.grey.shade300]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImage(path: ImageConstants.card),
                        SizedBox(width: 12),
                        Text("Add New Card",style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.textClr)),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Button(
                    onTap: () {
                      provider.addBookingApi(date:date ?? "" ,time: time ?? "");
                      // showBookingSuccessDialog(context);
                    },
                    borderRadius: 8,
                    child:provider.addBooking?.status == ApiStatus.LOADING ? customLoading() :  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Next",style: AppFontStyle.text_18_500(fontFamily: AppFontFamily.gilroySemiBold,color: AppColors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,size: 18,color: AppColors.white),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  CustomAppBar appbar() {
    return CustomAppBar(
      backgroundClr: AppColors.transparent,
      isIosBackBtn: true,
      title: Text("My Booking",style: AppFontStyle.text_18_600(color: AppColors.textClr,fontFamily: AppFontFamily.gilroyMedium),),
    );
  }

}
