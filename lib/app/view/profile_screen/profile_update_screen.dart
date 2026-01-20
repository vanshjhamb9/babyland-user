import 'dart:io';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  File? profileImage;
  final picker = ImagePicker();

  // Medical conditions map
  Map<String, bool> conditions = {
    "PCOS": false,
    "PMS": false,
    "Endometriosis": false,
    "Thyroid Issues": false,
    "Diabetes": false,
    "Hypertension": false,
  };

  @override
  void initState() {
    super.initState();
    final user = context.read<GetUserProvider>().userData?.data?.user;

    nameController = TextEditingController(text: user?.user?.name ?? "");
    emailController = TextEditingController(text: user?.user?.email ?? "");

    // Initialize conditions from user data
    if (user?.user?.conditions != null) {
      conditions["PCOS"] = user!.user?.conditions!.pCOS ?? false;
      conditions["PMS"] = user.user?.conditions!.pMS ?? false;
      conditions["Endometriosis"] = user.user?.conditions!.endometriosis ?? false;
      conditions["Thyroid Issues"] = user.user?.conditions!.thyroidIssues ?? false;
      conditions["Diabetes"] = user.user?.conditions!.diabetes ?? false;
      conditions["Hypertension"] = user.user?.conditions!.hypertension ?? false;
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  void updateProfile() async {
    final provider = context.read<GetUserProvider>();
    final name = nameController.text.trim();

    if (name.isEmpty) {
      AppPopUp.showToast(message: "Please enter your name");
      return;
    }

    // Send conditions normally: selected = true, unselected = false
    final condData = {
      "PCOS": conditions["PCOS"] ?? false,
      "PMS": conditions["PMS"] ?? false,
      "Endometriosis": conditions["Endometriosis"] ?? false,
      "ThyroidIssues": conditions["Thyroid Issues"] ?? false,
      "Diabetes": conditions["Diabetes"] ?? false,
      "Hypertension": conditions["Hypertension"] ?? false,
    };

    try {
      await provider.updateUserProfile(
        name: name,
        conditions: condData,
        profileImage: profileImage,
      );
    } catch (e) {
      AppPopUp.showToast(message: "Failed to update profile: $e");
    }
  }

  Widget buildConditionBox(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          conditions[title] = !isSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.buttonClr : null,
          border: Border.all(color: AppColors.buttonClr1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppFontStyle.text_14_400(
            color: isSelected ? AppColors.white : AppColors.textClr,
            fontFamily: AppFontFamily.gilroyMedium,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          "Update Profile",
          style: AppFontStyle.text_24_400(
            color: AppColors.black,
            fontFamily: AppFontFamily.gilroyMedium,
          ),
        ),
      ),
      body: Consumer<GetUserProvider>(
        builder: (context, provider, _) {
          final user = provider.userData?.data?.user;

          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Image Picker
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImage != null
                              ? FileImage(profileImage!)
                              : (user?.user?.name != null
                              ? NetworkImage(
                              "https://ui-avatars.com/api/?name=${user!.user?.name}") as ImageProvider
                              : const AssetImage('assets/profile_placeholder.png')),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.buttonClr
                              ),
                              child: const Icon(Icons.edit, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  CustomTextFormField(
                    controller: nameController,
                    hintText: "Enter your name",
                    borderColor: AppColors.borderColor,
                  ),
                  const SizedBox(height: 16),

                  // Email (read-only)
                  CustomTextFormField(
                    controller: emailController,
                    hintText: "Email",
                    // enabled: false,
                    readOnly: true,
                    borderColor: AppColors.borderColor,
                  ),
                  const SizedBox(height: 16),

                  // Medical Conditions
                  Text("Medical Conditions", style: AppFontStyle.text_16_500(color: AppColors.textClr)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: conditions.keys
                        .map((title) => buildConditionBox(title, conditions[title]!))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // Update Button
                  Button(
                    onTap: updateProfile,
                    child:provider.updateProfileData?.status == ApiStatus.LOADING ? customLoading() : Text("Update Profile",style:AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
