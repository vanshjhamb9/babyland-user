import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/view/basic_information/stages_view.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/profile_photo_picker.dart';
import 'package:babyland/app/widgets/user_avatar.dart';
import 'package:babyland/core/auth/app_google_sign_in.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../groups/saved_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Stages? stage;
  const ProfileScreen({super.key,this.stage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? currentStageName;

  @override
  void initState() {
    super.initState();
    _loadCurrentStage();
  }

  Future<void> _openSubscription(BuildContext context) async {
    Navigator.pushNamed(context, AppRoutes.subscriptionScreen);
  }

  Future<void> _loadCurrentStage() async {
    final step = await UserLocalData.getStep();
    if (step != null && step.isNotEmpty) {
      final stageIndex = int.tryParse(step);
      setState(() {
        switch (stageIndex) {
          case 0:
            currentStageName = "Pre-Pregnancy";
            break;
          case 1:
            currentStageName = "Pregnancy";
            break;
          case 2:
            currentStageName = "Post-Pregnancy";
            break;
          default:
            currentStageName = "Not Selected";
        }
      });
    } else {
      setState(() {
        currentStageName = "Not Selected";
      });
    }
  }
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
                  provider.getUser(force: true);
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
    final user = provider.userData?.data?.user?.user;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.profileUpdateScreen),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => showProfilePhotoPicker(context),
              child: Stack(
                children: [
                  UserAvatar(
                    size: 70,
                    imageUrl: user?.profilePicture,
                    name: user?.name,
                    stage: user?.stage,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ProfilePhotoBadge(size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // USER DETAILS
            Expanded(
              child: Column(
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
    const titles = [
      "Stage",
      "Subscription",
      "Saved Posts",
      "Shop Products",
      "About Us",
      "Doctors",
      "My Booking",
      "Terms of Service",
      "Privacy Policy",
      "Refund Policy",
      "Shipping Policy",
      "Delete Account",
      "Log Out",
    ];

    const icons = [
      Icons.flag_rounded,
      Icons.card_membership,
      Icons.bookmarks_rounded,
      Icons.shopping_bag_rounded,
      Icons.info_outline_rounded,
      Icons.local_hospital,
      Icons.event_available_rounded,
      Icons.description_rounded,
      Icons.privacy_tip_rounded,
      Icons.receipt_long_rounded,
      Icons.local_shipping_rounded,
      Icons.delete_forever_rounded,
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
                color: Colors.white,
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
            onTap: () async {
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StagesView(
                      fromProfile: true,
                      isUpdateFlow: true,
                    ),
                  ),
                ).then((_) {
                  _loadCurrentStage();
                });
              } else if (index == 1) {
                await _openSubscription(context);
              } else if (index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPostsScreen()));
              } else if (index == 3) {
                Navigator.pushNamed(context, AppRoutes.shopScreen);
              } else if (index == 4) {
                Navigator.pushNamed(context, AppRoutes.aboutUsView);
              } else if (index == 5) {
                Navigator.pushNamed(context, AppRoutes.allDoctorView);
              } else if (index == 6) {
                Navigator.pushNamed(context, AppRoutes.myBookingsView);
              } else if (index == 7) {
                Navigator.pushNamed(context, AppRoutes.termOfServicesScreen);
              } else if (index == 8) {
                Navigator.pushNamed(context, AppRoutes.privacyPolicy);
              } else if (index == 9) {
                Navigator.pushNamed(context, AppRoutes.refundPolicyScreen);
              } else if (index == 10) {
                Navigator.pushNamed(context, AppRoutes.shippingPolicyScreen);
              } else if (index == 11) {
                showDeleteAccountDialog();
              } else if (index == 12) {
                showLogoutDialog();
              }
            },
          );
        },
      ),
    );
  }

  // ---------------- DELETE ACCOUNT ----------------
  void showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    var deleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return PopScope(
            canPop: !deleting,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: AppContainer(
                        padding: const EdgeInsets.all(16),
                        shape: BoxShape.circle,
                        gradient: AppColors.buttonClr,
                        child: const Icon(
                          Icons.delete_forever,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Delete Account",
                      style: AppFontStyle.text_20_500(
                        color: AppColors.black,
                        fontFamily: AppFontFamily.gilroyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This permanently deletes your account and associated personal data. This cannot be undone.\n\nType DELETE to confirm.",
                      textAlign: TextAlign.center,
                      style: AppFontStyle.text_14_400(
                        color: AppColors.textLightClr,
                        fontFamily: AppFontFamily.gilroyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmController,
                      enabled: !deleting,
                      decoration: const InputDecoration(
                        hintText: 'DELETE',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Button(
                            text: "Cancel",
                            onTap: deleting
                                ? null
                                : () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Button(
                            text: deleting ? "…" : "Delete",
                            onTap: deleting
                                ? null
                                : () async {
                                    if (confirmController.text.trim() !=
                                        'DELETE') {
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Type DELETE to confirm',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setDialogState(() => deleting = true);
                                    try {
                                      final res =
                                          await repository.deleteAccount();
                                      if (res.success == false) {
                                        setDialogState(() => deleting = false);
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(dialogContext)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              res.message ??
                                                  'Could not delete account',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    } catch (e) {
                                      setDialogState(() => deleting = false);
                                      if (!dialogContext.mounted) return;
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not delete account: $e',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await SecureStorage.clearAll();
                                    await UserLocalData.clearAllLocalData();
                                    await UserPreference
                                        .saveSavedCommunityPostIds([]);
                                    try {
                                      await AppGoogleSignIn.signOut();
                                    } catch (_) {}
                                    await sl.authService.logout();
                                    if (!dialogContext.mounted) return;
                                    Navigator.pushNamedAndRemoveUntil(
                                      navigatorKey.currentContext!,
                                      AppRoutes.signInView,
                                      (route) => false,
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(confirmController.dispose);
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
                            await SecureStorage.clearAll();
                            await UserLocalData.clearAllLocalData();
                            await UserPreference.saveSavedCommunityPostIds([]);
                            try {
                              await AppGoogleSignIn.signOut();
                            } catch (_) {}
                            await sl.authService.logout();
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              navigatorKey.currentContext!,
                              AppRoutes.signInView,
                              (route) => false,
                            );
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