import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/view/baby_growth/vaccianations/controller/vaccianations_controller.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../widgets/general_exception.dart';

class VaccinationView extends StatelessWidget {
  VaccinationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VaccianationController>(
        create: (context) {
          final provider = VaccianationController();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.getVaccinationApi();
          });
          return provider;
        },
        builder: (context,_) {
        return Scaffold(
          appBar: CustomAppBar(
            centerTitle: true,
            title: Text(
              "Vaccination",
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroySemiBold,
              ),
            ),
          ),
          body: Consumer<VaccianationController>(
            builder: (context, provider, _) {
              final status = provider.vaccinationData?.status;
              return switch (status) {
                ApiStatus.LOADING => vaccinationShimmer(),
                ApiStatus.ERROR => GeneralExceptionWidget(onPress: () => provider.getVaccinationApi(),),
                ApiStatus.COMPLETED => body(context),
                _ => const SizedBox.shrink(),
              };
            },
          ),
        );
      }
    );
  }

  Widget body(BuildContext context) {
    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14),
      gradient: AppColors.backGroundColor,
      child: Consumer<VaccianationController>(
        builder: (context,provider,_) {
          return Column(
            children: [
              AppContainer(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                radius: 8,
                color: AppColors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (index) => Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              "1",
                              style: AppFontStyle.text_32_400(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: index == 0
                                    ? AppColors.green
                                    : index == 1
                                    ? AppColors.orangeClr
                                    : AppColors.red,
                              ),
                            ),
                            Text(
                              index == 0
                                  ? "Completed"
                                  : index == 1
                                  ? "Due Soon"
                                  : "Overdue",
                              style: AppFontStyle.text_14_400(
                                fontFamily: AppFontFamily.gilroySemiBold,
                              ),
                            ),
                          ],
                        ),
                        if (index == 0 || index == 1) ...[
                          SizedBox(width: 25),
                          AppContainer(
                            width: 1,
                            height: mediaQueryH(context) * 0.05,
                            color: AppColors.greyLight,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 22),
              Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.getVaccinationApi(),
                child: ListView.separated(
                  physics: AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                    itemCount: provider.vaccinationData?.data?.vaccinations?.length ?? 0,
                  itemBuilder: (context, index) {
                  final vaccinations = provider.vaccinationData?.data?.vaccinations?[index];
                  return   AppContainer(
                    radius: 8,
                    color: AppColors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppContainer(
                                radius: 100,
                                color: vaccinations?.completed == true ? AppColors.lightGreen : AppColors.lightYellow,
                                // color: listData[index]['status'] == "Completed" ? AppColors.lightGreen : AppColors.lightYellow,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(child: Icon(
                                    vaccinations?.completed == true ? Icons.done : Icons.access_time_sharp,
                                    color: vaccinations?.completed == true ? AppColors.green : AppColors.orangeClr,)),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vaccinations?.vaccine ?? "",
                                    maxLines: 10,
                                    style: AppFontStyle.text_14_400(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: vaccinations?.completed != true  ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                                    children: [
                                      if(vaccinations?.completed != true )
                                      Text("Due Date: ${DateFormat('MMM d, yyyy').format(
                                          DateTime.parse(vaccinations?.dueDate ?? '')
                                      )
                                      }",
                                        maxLines: 10,
                                        style: AppFontStyle.text_11_400(
                                          fontFamily: AppFontFamily.gilroyMedium,
                                          color: AppColors.textLightClr,
                                        ),
                                      ),
                                      AppContainer(
                                        radius: 100,
                                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                                        color:  vaccinations?.status.toString() == "completed" ?
                                        AppColors.lightGreen : AppColors.lightYellow,
                                        child: Text(
                                          vaccinations?.status.toString() == "completed" ? "Completed" : "Due" ,
                                          style: AppFontStyle.text_12_400(
                                            fontFamily: AppFontFamily.gilroyMedium,
                                            color:vaccinations?.status.toString() == "completed" ?
                                            AppColors.green : AppColors.orangeClr,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if( vaccinations?.status != "completed")...[
                                  SizedBox(height: 12),
                                  InkWell(
                                    child: AppContainer(
                                      radius: 100,
                                      width: 170,
                                      height: 35,
                                      color: AppColors.textClr,
                                      padding: EdgeInsets.symmetric(horizontal: 8,vertical: 6),
                                      child:provider.updateVaccinationData?.status == ApiStatus.LOADING && index ==  provider.selectedIndex ? customLoading() :    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.done,color: AppColors.white,size: 16),
                                          SizedBox(width: 6),
                                          Text("Mark as complete",
                                            style: AppFontStyle.text_14_400(
                                              fontFamily: AppFontFamily.gilroyMedium,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      provider.updateSelectedIndex(index);
                                      if(provider.updateVaccinationData?.status != ApiStatus.LOADING) {
                                        provider.updateVaccinationApi(provider.vaccinationData?.data?.vaccinations?[index].sId ?? "");
                                      }
                                    },
                                  ),
                                  ],
                                ],
                              ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  ),
              ),
            ),
              SizedBox(height: 10),
            ],
          );
        }
      ),
    );
  }

  Widget vaccinationShimmer() {
    return AppContainer(
      padding: EdgeInsets.symmetric(horizontal: 14),
      gradient: AppColors.backGroundColor,
      child: Column(
        children: [
          // ----------------- HEADER SHIMMER -----------------
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: AppContainer(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 8,
              color: AppColors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  3,
                      (index) => Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 10,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                      if (index != 2) ...[
                        SizedBox(width: 25),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 22),

          // ----------------- LIST SHIMMER -----------------
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (_, __) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: AppContainer(
                    radius: 8,
                    color: AppColors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circle Icon Placeholder
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),

                        // Text placeholders
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: double.infinity,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 10,
                                width: 160,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 12),
                              Container(
                                height: 28,
                                width: 120,
                                color: Colors.grey.shade300,
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
          ),

          SizedBox(height: 10),
        ],
      ),
    );
  }
}
