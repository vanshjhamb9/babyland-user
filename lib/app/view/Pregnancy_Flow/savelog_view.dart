import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/app/navbar/post_pregnancy/post_pregnancy_navbar_controller.dart';
import 'package:babyland/app/navbar/pregnancy/navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/button.dart';

class SaveLogView extends StatefulWidget {
  const SaveLogView({super.key});

  @override
  State<SaveLogView> createState() => _SaveLogViewState();
}

class _SaveLogViewState extends State<SaveLogView> {
  String flowType = "";
  bool prePregnancyFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      flowType = args?['flowType'] ?? "";
      prePregnancyFlow = args?['prePregnancyFlow'];
      pt("flowtype $flowType");
      pt("prePregnancyFlow $prePregnancyFlow");
    },);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      body: AppContainer(
        color: AppColors.backgroundClr,
        gradient: AppColors.backGroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: width * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               CustomImage(
                  path: "assets/images/done.png",
                  scale: width < 360 ? 6 : 5,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: height * 0.035),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Text(
                    "We've analyzed your day – insights are ready!",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppFontStyle.text_22_400(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ).copyWith(
                      fontSize: width * 0.055,
                    ),
                  ),
                ),

                SizedBox(height: height * 0.04),

                 Consumer<NavBarProvider>(
                   builder: (context,provider,_) {
                     return Button(
                       onTap: () {
                         pt("flowtype $flowType");
                         pt("prePregnancyFlow $prePregnancyFlow");

                         if(flowType == "pregnancyFlow"){
                           Navigator.pushNamed(context, AppRoutes.navbarView);
                           provider.setSelectedIndex(2);
                         }else if(flowType == "postPregnancy" && prePregnancyFlow == false){
                           Navigator.pushNamed(context, AppRoutes.postPregnancyNavbarView);
                           context.read<PostPregnancyNavBarProvider>().setSelectedIndex(2);
                         } else if(flowType != "postPregnancyFlow") {
                           Navigator.pushNamed(context, AppRoutes.navbarView);
                           provider.setSelectedIndex(2);
                         }
                       },
                       height: height * 0.07,
                       child: Text(
                         "View ${AppConstants.aiAssistantDisplayName} Insights",
                         style: AppFontStyle.text_15_400(
                           fontFamily: AppFontFamily.gilroyBold,
                           color: AppColors.white,
                         ).copyWith(
                           fontSize: width * 0.045,
                         ),
                       ),
                     );
                   }
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
