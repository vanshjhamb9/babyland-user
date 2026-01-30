import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/storage/user_local_data.dart';

class StagesView extends StatefulWidget {
  final bool? fromProfile;
   const StagesView({super.key,this.fromProfile});

  @override
  State<StagesView> createState() => _StagesViewState();
}

class _StagesViewState extends State<StagesView> {
  final List<Map<String,String>> stagesList = [
    {"title":"Pre-Pregnancy","image":ImageConstants.prePregnancy1},
    {"title":"Pregnancy","image":ImageConstants.pregnancy},
    {"title":"Post-Pregnancy","image":ImageConstants.postPregnancy},
  ];


  bool fromLoginScreen = false;
  bool back = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('fromLoginScreen')) {
        fromLoginScreen = args['fromLoginScreen'] ?? false;
        back = args['back'] ?? false;

      }
      pt("fromLoginScreen--------------->>>> $fromLoginScreen");
      pt("back--------------->>>> $back");
      pt("fromprofile--------------->>>> ${widget.fromProfile}");
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Column(
          children: [
            CustomAppBar(
              isLeading: back,
              centerTitle: true,
              title: Text(
                "What Stage are you In ?",
                style: AppFontStyle.text_20_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
              backgroundClr: AppColors.transparent,
            ),
           ListView.separated(
             physics: NeverScrollableScrollPhysics(),
             shrinkWrap: true,
               itemBuilder: (context, index) {
                 return  Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 14),
                   child: GestureDetector(
                     /*onTap: () {
                       if(fromLoginScreen){
                         switch(index){
                           case 0 :
                             //pregnancy
                             Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
                           case 1 :
                             //pre pregnancy
                             Navigator.pushNamed(context, AppRoutes.pregnancyView);
                           case 2 :
                             // post pregnancy
                             Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
                         }
                         context.read<GetUserProvider>().getUser();
                       }else if(fromProfile){
                         switch(index){
                           case 0 :
                           //pregnancy
                             Navigator.pushNamedAndRemoveUntil(context, AppRoutes.navbarPrePregancyView,(route) => false,);
                           case 1 :
                           //pre pregnancy
                             Navigator.pushNamedAndRemoveUntil(context, AppRoutes.pregnancyView,(route) => false,);
                           case 2 :
                           // post pregnancy
                             Navigator.pushNamedAndRemoveUntil(context, AppRoutes.combinedBabyDetailScreen,(route) => false,);
                         }
                       }
                       else {
                         Navigator.pushNamed(context, AppRoutes.processingDetailsView, arguments: {"index": index});
                         context.read<GetUserProvider>().getUser();
                       }
                     },*/
                     onTap: () async {
                       // Save timestamp when user makes a selection
                       await UserLocalData.saveLastStageScreenShown();
                       await UserLocalData.saveStep(index.toString());

                       if (fromLoginScreen) {
                         switch (index) {
                           case 0: // Pre-Pregnancy
                             Navigator.pushNamed(context, AppRoutes.navbarPrePregancyView);
                             break;

                           case 1: // Pregnancy
                             Navigator.pushNamed(context, AppRoutes.pregnancyView);
                             break;

                           case 2: // Post-Pregnancy
                             Navigator.pushNamed(context, AppRoutes.combinedBabyDetailScreen);
                             break;
                         }

                         context.read<GetUserProvider>().getUser();
                       }

                       else if (widget.fromProfile == true) {
                         switch (index) {
                           case 0: // Pre-Pregnancy
                             Navigator.pushNamedAndRemoveUntil(
                               context,
                               AppRoutes.navbarPrePregancyView,
                                   (route) => false,
                             );
                             break;

                           case 1: // Pregnancy
                             Navigator.pushNamedAndRemoveUntil(
                               context,
                               AppRoutes.pregnancyView,
                                   (route) => false,
                             );
                             break;

                           case 2: // Post-Pregnancy
                             Navigator.pushNamedAndRemoveUntil(
                               context,
                               AppRoutes.combinedBabyDetailScreen,
                                   (route) => false,
                             );
                             break;
                         }
                       }

                       else {
                         // Default flow → Send index to next screen
                         Navigator.pushNamed(
                           context,
                           AppRoutes.processingDetailsView,
                           arguments: {"index": index},
                         );

                         context.read<GetUserProvider>().getUser();
                       }
                     },
                       child: AppContainer(
                       height: 105,
                       color: AppColors.white,
                       radius: 8,
                       isBordered: true,
                       child: Row(
                         children: [
                           Padding(
                             padding:index ==0 ? EdgeInsets.symmetric(vertical: 16,horizontal: 8) : EdgeInsets.symmetric(vertical: 8.0),
                             child: CustomImage(path: stagesList[index]['image'] ?? "",),
                           ),
                           Text(stagesList[index]['title'] ?? "",style: AppFontStyle.text_15_400(color: AppColors.textClr,fontFamily: AppFontFamily.gilroySemiBold),),
                           Spacer(),
                           Icon(Icons.arrow_forward_ios,size: 16,),
                           SizedBox(width: 16),
                         ],
                       )
                     ),
                   ),
                 );
               },
               separatorBuilder: (context, index) => SizedBox(height: 15),
               itemCount: stagesList.length,
           ),
          ],
        ),
      ),
    );
  }
}
