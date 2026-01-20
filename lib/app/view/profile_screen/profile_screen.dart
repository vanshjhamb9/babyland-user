import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_preference.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/view/basic_information/stages_view.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final Stages? stage;
  const ProfileScreen({super.key,this.stage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        isLeading: false,
        title: Text(
          "Profile",
          style: AppFontStyle.text_24_400(
            color: AppColors.black,
            fontFamily: AppFontFamily.gilroyMedium,
          ),
        ),
      ),
      body: Consumer<GetUserProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  provider.getUser();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    buildProfileCard(provider),
                    const SizedBox(height: 20),
                    buildTiles(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- PROFILE CARD ----------------
  Widget buildProfileCard(GetUserProvider provider) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.profileUpdateScreen),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.textLightClr.withAlpha(40),
              child: Center(
                child: Text(provider.userData?.data?.user?.user?.name?[0] ?? "",
                  style: AppFontStyle.text_40_600(
                    color: AppColors.black,
                    fontFamily: AppFontFamily.gilroyRegular,
                  ),
                )  ?? const Icon(Icons.person, size: 38, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),

            // USER DETAILS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.userData?.data?.user?.user?.name ?? "",
                  style: AppFontStyle.text_20_500(
                    color: AppColors.black,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.userData?.data?.user?.user?.email ?? "",
                  style: AppFontStyle.text_14_400(
                    color: AppColors.textLightClr,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  // ---------------- MENU TILES ----------------
  Widget buildTiles() {
    List<String> titles = ["Stage", "Subscription","Doctors","My Booking","Terms of Service", "Privacy Policy","Refund Policy","Shipping Policy" ,"Log Out"];

    List<IconData> icons = [
      Icons.flag_rounded, // FIXED: Icons.stage DOES NOT EXIST
      Icons.card_membership,
      Icons.local_hospital,// Better icon for subscription
      Icons.save,// Better icon for subscription
      Icons.description_rounded,       // TERMS OF SERVICE
      Icons.privacy_tip_rounded,       // PRIVACY POLICY
      Icons.receipt_long_rounded,      // REFUND POLICY
      Icons.local_shipping_rounded,
      Icons.logout_rounded,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: titles.length,
        separatorBuilder: (_, __) => Divider(color: AppColors.borderColor),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            leading: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    AppColors.buttonClr1.withValues(alpha: 0.9),
                    AppColors.buttonClr2.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Icon(
                icons[index],
                size: 26,
                color: Colors.white, // Must be white for gradient effect
              ),
            ),

            title: Text(
              titles[index],
              style: AppFontStyle.text_16_400(
                color: AppColors.black,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              if(index == 0){
                Navigator.push(context, MaterialPageRoute(builder: (context) => StagesView(fromProfile: true,),));
              }else if(index == 1){
                switch(widget.stage!) {
                  case Stages.PREPREGRANCY:
                    Navigator.pushNamed(context, AppRoutes.prePreSubscriptionView);
                    break;
                  case Stages.PREGRANCY:
                    Navigator.pushNamed(context, AppRoutes.preSubscriptionView);
                    break;
                  case Stages.POSTPREGRANCY:
                    Navigator.pushNamed(context, AppRoutes.postPreSubscriptionView);
                    break;
                }
              }else if (index == 2) {
                Navigator.pushNamed(context, AppRoutes.allDoctorView);
              }else if (index == 3) {
                Navigator.pushNamed(context, AppRoutes.myBookingsView);
              }else if (index == 4) {
                Navigator.pushNamed(context, AppRoutes.termOfServicesScreen);
              }else if (index == 5) {
                Navigator.pushNamed(context, AppRoutes.privacyPolicy);
              }else if (index == 6) {
                Navigator.pushNamed(context, AppRoutes.refundPolicyScreen);
              }else if (index == 7) {
                Navigator.pushNamed(context, AppRoutes.shippingPolicyScreen);
              }else if (index == 8) {
                showLogoutDialog();
              }
            },
          );
        },
      ),
    );
  }

  // ---------------- LOGOUT POPUP ----------------
  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON BOX
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(100),
                  child: AppContainer(
                    padding: const EdgeInsets.all(16),
                    shape: BoxShape.circle,
                    gradient: AppColors.buttonClr,
                    child: Icon(
                      Icons.logout,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  "Log Out",
                  style: AppFontStyle.text_20_500(
                    color: AppColors.black,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),

                const SizedBox(height: 8),

                // MESSAGE
                Text(
                  "Are you sure you want to log out?",
                  textAlign: TextAlign.center,
                  style: AppFontStyle.text_14_400(
                    color: AppColors.textLightClr,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),

                const SizedBox(height: 20),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: Button(
                        text: "No",
                        onTap: () => Navigator.pop(context),
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        text: "Yes",
                        onTap: ()async {
                          await UserPreference.clearAllLocalData();
                          await SecureStorage.clearAll();
                          Navigator.pushNamedAndRemoveUntil(navigatorKey.currentContext!, AppRoutes.signInView, (route) => false);
                        },
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
