import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/ai_assistant/ai_assistant_controller.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/font_family.dart';
import '../theme/font_style.dart';
import '../widgets/container.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_image.dart';


class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final String? percentage;
  final VoidCallback? onAskPressed;
  final bool showBackButton;

  const ProfileHeader({
    super.key,
    this.subtitle,
    this.percentage,
    this.onAskPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      toolbarHeight: 100,
      isLeading: showBackButton,
      title: Consumer<GetUserProvider>(
        builder: (context,provider,_) {
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("${provider.userData?.data?.user?.user?.name ?? ""} 👋", style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroyMedium),),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStageColor(provider.currentStageLabel).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getStageColor(provider.currentStageLabel).withOpacity(0.5)),
                      ),
                      child: Text(
                        provider.currentStageLabel,
                        style: AppFontStyle.text_10_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: _getStageColor(provider.currentStageLabel),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(subtitle ?? "Track your cycle and stay healthy", style: AppFontStyle.text_12_400(fontFamily: AppFontFamily.gilroyRegular,color: AppColors.textClr),),
              ],
            ),
          );
        }
      ),
      actions: [
        Consumer<AiAssistantProvider>(
          builder: (context,provider,_) {
            return InkWell(
              onTap: () async{
                Navigator.pushNamed(context, AppRoutes.aiAssistantView);
                await SecureStorage.clearConversationId();
                // await provider.createChatRoomApi();
              },
              child: AppContainer(
                radius: 100,
                gradient: AppColors.backGroundColor.withOpacity(0.05),
                borderColor: AppColors.buttonClr1,
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3.5),
                child: Row(
                  children: [
                    Text("Ask AI", style: AppFontStyle.text_14_400(fontFamily: AppFontFamily.gilroyMedium),),
                    SizedBox(width: 5),
                    CustomImage(path: ImageConstants.start,scale: 4,)
                  ],
                ),
              ),
            );
          }
        ),
        SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () {
                // Navigator.pushNamed(context, AppRoutes.allDoctorView);
              },
              child: AppContainer(
                gradient: AppColors.buttonClr,
                radius: 100,
                padding: EdgeInsets.all(1),
                child: (context.read<GetUserProvider>().userData?.data?.user?.user?.profilePicture?.isEmpty ?? false) ? Icon(Icons.person)  : CustomImage(
                  h: 40,
                  w: 40,
                  borderRadius: BorderRadius.circular(100),
                  path:context.read<GetUserProvider>().userData?.data?.user?.user?.profilePicture ?? "https://i.pravatar.cc/300",),
              ),
            ),
            Positioned(
              bottom: -10,
              child:  Consumer<GetUserProvider>(
                  builder: (context,provider,_) {
                  return AppContainer(
                    color: AppColors.white,
                    borderColor: AppColors.buttonClr1,
                    radius: 100,
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                    child: Text("${provider.userData?.data?.user?.profileCompletion ?? "0"}%", style: AppFontStyle.text_10_400(fontFamily: AppFontFamily.gilroyMedium),),
                  );
                }
              ),
            )
          ],
        ),
        SizedBox(width: 14),
      ],
    );
  }

  Color _getStageColor(String label) {
    switch (label) {
      case "Pregnancy":
        return AppColors.buttonClr2; // Pink
      case "Post-pregnancy":
        return AppColors.green; // Green
      case "Pre-pregnancy":
        return AppColors.blue; // Blue
      default:
        return AppColors.buttonClr1; // Orange
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}
