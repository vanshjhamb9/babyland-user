import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../controller/experts_consultation/model/doctor_data_model.dart';
import '../../widgets/text.dart';
import '../../widgets/sizedbox.dart';
import '../../widgets/validation.dart';

class AllDoctorView extends StatefulWidget {
  const AllDoctorView({super.key});

  @override
  State<AllDoctorView> createState() => _AllDoctorViewState();
}

class _AllDoctorViewState extends State<AllDoctorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpertConsultationProvider>();
      provider.doctorDetailApiData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isIosBackBtn: true,
        title: Text(
          "Doctors",
          style: AppFontStyle.text_18_600(
            fontFamily: AppFontFamily.gilroyMedium,
          ),
        ),
      ),
      body: Consumer<ExpertConsultationProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            gradient: AppColors.backGroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH FIELD
        /*        CustomTextFormField                (
                  controller: provider.searchController,
                  borderColor: AppColors.borderColor,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.search, color: AppColors.purpleClr, size: 20),
                  ),
                  hintText: "Search doctors...",
                  onChanged: (value) {
                    provider.searchDoctors(value);
                  },
                ),*/
                // SEARCH FIELD
                CustomTextFormField(
                  controller: provider.searchController,
                  borderColor: AppColors.borderColor,
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.search, color: AppColors.purpleClr, size: 20),
                  ),
                  hintText: "Search doctors...",
                  onChanged: (value) {
                    // Debounced search will handle this
                    pt(value);
                    provider.searchDoctors(value);
                  },
                  // Optional: Add clear button
                  suffix: provider.searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      provider.searchController.clear();
                      provider.searchDoctors('');
                    },
                  )
                      : null,
                ),
                const SizedBox(height: 16),

                // FILTER BUTTONS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      provider.btnList.length,
                          (index) {
                        final isSelected = provider.selectedBtn == index;
                        return GestureDetector(
                          onTap: () {
                            provider.setSelectedBtn(index);
                            if(index == 1) {
                              provider.doctorDetailApiData(date: DateTime.now());
                            }else {
                              provider.doctorDetailApiData();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AppContainer(
                              gradient: isSelected
                                  ? AppColors.buttonClr
                                  : LinearGradient(colors: [AppColors.white, AppColors.white]),
                              radius: 100,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomImage(
                                    path: provider.btnList[index]['image'] ?? "",
                                    h: 14,
                                    w: 14,
                                    color: isSelected ? AppColors.white : AppColors.buttonClr1,
                                  ),
                                  const SizedBox(width: 10),
                                  GradientText(
                                    provider.btnList[index]['title'] ?? "",
                                    style: AppFontStyle.text_14_500(
                                      fontFamily:
                                      isSelected ? AppFontFamily.gilroyBold : AppFontFamily.gilroySemiBold,
                                      color: isSelected ? AppColors.white : AppColors.buttonClr1,
                                    ),
                                    gradient: !isSelected
                                        ? AppColors.buttonClr
                                        : LinearGradient(colors: [AppColors.white, AppColors.white]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // DOCTOR LIST
// DOCTOR LIST
                Expanded(
                  child: Builder(
                    builder: (_) {
                      switch (provider.doctorApiData?.status) {
                      // LOADING
                        case ApiStatus.LOADING:
                          return _buildShimmerList();

                      // COMPLETED
                        case ApiStatus.COMPLETED:
                        // Get the doctors to display
                          List<Doctor> doctorsToDisplay = [];

                          // Check filtered doctors first
                          if (provider.filteredDoctors != null && provider.filteredDoctors!.isNotEmpty) {
                            doctorsToDisplay = provider.filteredDoctors!;
                          }
                          // If no filtered doctors, check if search is active
                          else if (provider.searchController.text.isNotEmpty) {
                            // Search is active but no results
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 60, color: AppColors.buttonClr1),
                                  SizedBox(height: 16),
                                  Text(
                                    "No doctors found",
                                    style: AppFontStyle.text_16_600(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textClr,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Try a different search term",
                                    style: AppFontStyle.text_14_400(
                                      fontFamily: AppFontFamily.gilroyRegular,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // If no filters and no search, use all doctors
                          else if (provider.doctorApiData?.data?.data != null) {
                            doctorsToDisplay = provider.doctorApiData!.data!.data!;
                          }

                          if (doctorsToDisplay.isEmpty) {
                            return Center(child: CustomNoDataFound());
                          }

                          return RefreshIndicator(
                            onRefresh: () => provider.doctorDetailApiData(),
                            child: ListView.separated(
                              itemCount: doctorsToDisplay.length,
                              separatorBuilder: (_, __) => SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final doctor = doctorsToDisplay[index];
                                return Card(
                                  surfaceTintColor: AppColors.transparent,
                                  color: AppColors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: AppContainer(
                                    radius: 16,
                                    width: MediaQuery.of(context).size.width,
                                    color: AppColors.white,
                                    padding: EdgeInsets.all(14),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                CustomImage(
                                                  path: ImageConstants.networkImageDemo,
                                                  h: 64,
                                                  w: 64,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                Positioned(
                                                  right: -8,
                                                  bottom: -6,
                                                  child: AppContainer(
                                                    height: 24,
                                                    width: 24,
                                                    radius: 100,
                                                    border: Border.all(color: AppColors.white, width: 2),
                                                    color: doctor.isVerified == false
                                                        ? AppColors.buttonClr1
                                                        : AppColors.greenLight,
                                                    child: Icon(
                                                      doctor.isVerified == false ? Icons.pause : Icons.done,
                                                      color: AppColors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 15),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  capitalizeFirstLetter(doctor.name ?? ""),
                                                  style: AppFontStyle.text_18_600(
                                                    fontFamily: AppFontFamily.gilroyMedium,
                                                    color: AppColors.textClr,
                                                  ),
                                                ),
                                                GradientText(
                                                  "Specialization",
                                                  gradient: AppColors.buttonClr,
                                                  style: AppFontStyle.text_14_600(
                                                    fontFamily: AppFontFamily.gilroyMedium,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Row(
                                                      children: List.generate(
                                                        5,
                                                            (_) => Icon(
                                                          Icons.star,
                                                          color: AppColors.starYellow,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "4.9 (127 reviews)",
                                                      style: AppFontStyle.text_14_400(
                                                        fontFamily: AppFontFamily.gilroyRegular,
                                                        color: AppColors.textClr,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_filled,
                                                      color: AppColors.buttonClr1,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "Next available: Today 2:30 PM",
                                                      style: AppFontStyle.text_14_400(
                                                        fontFamily: AppFontFamily.gilroyRegular,
                                                        color: AppColors.textClr,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 15),
                                        Button(
                                          padding: EdgeInsets.zero,
                                          onTap: () async {
                                            await UserLocalData.saveDoctorId(doctor.sId ?? "");
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.doctorProfileView,
                                              arguments: {
                                                "doctorId": doctor.sId
                                              },
                                            );
                                            provider.setSelectedDoctorId(doctor.sId ?? "");
                                          },
                                          borderRadius: 12,
                                          width: MediaQuery.of(context).size.width,
                                          height: 46,
                                          child: Text(
                                            "Book Now",
                                            style: AppFontStyle.text_18_400(
                                              fontFamily: AppFontFamily.gilroySemiBold,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );

                      // ERROR
                        case ApiStatus.ERROR:
                          return GeneralExceptionWidget(
                            onPress: () => provider.doctorDetailApiData(),
                          );

                        default:
                          return SizedBox();
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // SHIMMER LOADING
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
            ),
          ),
        );
      },
    );
  }
}
