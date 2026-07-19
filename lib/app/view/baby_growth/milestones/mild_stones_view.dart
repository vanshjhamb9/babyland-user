import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class MildStonesView extends StatefulWidget {
  const MildStonesView({super.key});

  @override
  State<MildStonesView> createState() => _MildStonesViewState();
}

class _MildStonesViewState extends State<MildStonesView> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<BabyGrowthProvider>().geMildStoneDetails();
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          "Milestones",
          style: AppFontStyle.text_20_400(
            fontFamily: AppFontFamily.gilroySemiBold,
            color: AppColors.textClr,
          ),
        ),
      ),
      body: Consumer<BabyGrowthProvider>(
        builder: (context, provider, _) {
          switch (provider.milestonesData?.status) {
            case ApiStatus.LOADING:
              return milestoneShimmer();

            case ApiStatus.ERROR:
              return GeneralExceptionWidget(
                onPress: () => provider.geMildStoneDetails(),
              );

            case ApiStatus.COMPLETED:
              return body(provider);

            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Button(
            onTap: ()async{
            final result =await  Navigator.pushNamed(context, AppRoutes.addMildStones);
            if(result == true){
              context.read<BabyGrowthProvider>().geMildStoneDetails();
            }
            },
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add,color: AppColors.white),
                SizedBox(width: 4),
                Text("Add New milestones",style:AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white)),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget body(BabyGrowthProvider provider) {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: RefreshIndicator(
        onRefresh: () {
          return provider.geMildStoneDetails();
        },
        child: (provider.milestonesData?.data?.data?.isEmpty ?? true) ? CustomNoDataFound(isClr: false) :  ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 14),
            itemCount: provider.milestonesData?.data?.data?.length ?? 0,
          itemBuilder: (context, index) {
          return AppContainer(
            radius: 14,
            color: AppColors.white,
            padding: EdgeInsets.all(12),
            isBordered: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                CustomImage(
                  path: provider.milestonesData?.data?.data?[index].photo ?? "",
                  h: 70,
                  w: 72,
                  borderRadius: BorderRadius.circular(8),
                ),
                SizedBox(width: 10),

                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        capitalizeFirstLetter(provider.milestonesData?.data?.data?[index].title ?? ""),
                        style: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.textClr,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),

                      // Note
                      Text(
                        provider.milestonesData?.data?.data?[index].note ?? "",
                        style: AppFontStyle.text_11_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),

                      // Date
                      Text(
                        formatDate(provider.milestonesData?.data?.data?[index].date ?? ""),
                        style: AppFontStyle.text_11_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textClr,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(height: 6),
        ),
      )
    );
  }




  Widget milestoneShimmer() {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: AppColors.buttonClr1.withAlpha(100)),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image shimmer
                  Container(
                    height: 70,
                    width: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text shimmer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey,
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
