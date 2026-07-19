import 'dart:io';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/app/controller/baby_growth/baby_growth_controller.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/data/network/end_points.dart';
import 'package:intl/intl.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController weightController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController medicalHistoryController;
  
  // Pregnancy specific
  late TextEditingController conceptionDateController;
  
  // Post-Pregnancy specific
  late TextEditingController babyNameController;
  late TextEditingController babyDobController;
  late TextEditingController babyGenderController; // "Male", "Female", "Prefer not to say"

  File? profileImage;
  final picker = ImagePicker();
  String? currentStage; // "0" = Pre, "1" = Preg, "2" = Post

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
    _loadStage();
    final user = context.read<GetUserProvider>().userData?.data?.user;

    nameController = TextEditingController(text: user?.user?.name ?? "");
    emailController = TextEditingController(text: user?.user?.email ?? "");
    phoneController = TextEditingController(text: user?.user?.phone ?? "");
    weightController = TextEditingController(text: user?.user?.weight ?? "");
    ageController = TextEditingController(text: user?.user?.age ?? "");
    heightController = TextEditingController(text: user?.user?.height ?? "");
    medicalHistoryController = TextEditingController(text: user?.user?.medicalHistory ?? "");
    
    // Initialize stage specific controllers
    String? concDate = user?.user?.pregnancyStartDate;
    if (concDate == null && user?.pregnancyTracker != null) {
      concDate = user?.pregnancyTracker!['pregnancyStartDate']?.toString() ??
                 user?.pregnancyTracker!['conception_date']?.toString();
    }
    if (concDate != null && concDate.isNotEmpty) {
      try {
        if (concDate.contains('T')) {
          concDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(concDate));
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(concDate)) {
          // already yyyy-mm-dd format
        } else {
          try {
             concDate = DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(concDate));
          } catch (_) {}
        }
      } catch (_) {}
    }
    conceptionDateController = TextEditingController(text: concDate ?? "");
    babyNameController = TextEditingController();
    babyDobController = TextEditingController();
    babyGenderController = TextEditingController();

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

  Future<void> _loadStage() async {
    String? step = await UserLocalData.getStep();
    
    setState(() {
      currentStage = step;
    });
  }

  bool isPickingImage = false;

  Future<void> pickImage() async {
    if (isPickingImage) return;
    try {
      isPickingImage = true;
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      isPickingImage = false;
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.buttonClr1, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: AppColors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonClr1, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void updateProfile() async {
    final provider = context.read<GetUserProvider>();
    final pregnancyProvider = context.read<PregnancyController>();
    final babyGrowthProvider = context.read<BabyGrowthProvider>();
    final name = nameController.text.trim();

    if (name.isEmpty) {
      AppPopUp.showToast(message: "Please enter your name");
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty || !isValidPhone(phone, isRequired: true)) {
      AppPopUp.showToast(
        message: "Please enter a valid phone number (8–15 digits).",
      );
      return;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty && !isValidEmail(email)) {
      AppPopUp.showToast(message: "Please enter a valid email address.");
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
      // Create base update
      await provider.updateUserProfile(
        name: name,
        email: emailController.text.toString().trim(),
        phone: phone,
        weight: weightController.text.toString().trim(),
        age: ageController.text.toString().trim(),
        height: heightController.text.toString().trim(),
        conditions: condData,
        profileImage: profileImage,
      );
      
      // Handle stage specific updates
      if (currentStage == "1") { // Pregnancy
          if(conceptionDateController.text.isNotEmpty) {
             await pregnancyProvider.updatePregnancyDate(date: conceptionDateController.text.toString());
          }
      } else if (currentStage == "2") { // Post-Pregnancy
          if(babyNameController.text.isNotEmpty && babyDobController.text.isNotEmpty && babyGenderController.text.isNotEmpty) {
             await babyGrowthProvider.updateBabyDetails(
                 babyName: babyNameController.text.toString(),
                 dob: babyDobController.text.toString(),
                 gender: babyGenderController.text.toString()
             );
          }
      }
      
    } catch (e) {
      AppPopUp.showToast(message: "Failed to update profile: $e");
    }
  }

  /// Offline-safe placeholder (avoids external avatar URLs that fail DNS).
  Widget _nameInitialAvatar(String? name, {double size = 100}) {
    final n = (name ?? 'User').trim();
    final letter = n.isNotEmpty ? n[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: AppColors.greyStroke,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppFontStyle.text_24_400(
          color: AppColors.black,
          fontFamily: AppFontFamily.gilroyMedium,
        ).copyWith(fontSize: size * 0.32),
      ),
    );
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
          color: isSelected ? AppColors.white : Colors.white,
          gradient: isSelected ? AppColors.buttonClr : null,
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.buttonClr1),
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children, Color iconColor = AppColors.buttonClr1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24), // Use theme color or custom
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFontStyle.text_18_600(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroyBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          "Edit Profile",
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Image Picker
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.transparent,
                              child: ClipOval(
                                child: Builder(
                                  builder: (context) {
                                    if (profileImage != null) {
                                      return CustomImage(
                                        path: profileImage!.path,
                                        w: 100,
                                        h: 100,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      String? profilePic = user?.user?.profilePicture;
                                      if (profilePic != null && profilePic.isNotEmpty) {
                                         if (!profilePic.startsWith('http')) {
                                            final uri = Uri.parse(EndPoints.baseUrl);
                                            final rootUrl = "${uri.scheme}://${uri.host}"; 
                                            String cleanPath = profilePic.replaceAll('\\', '/');
                                            if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                                            profilePic = "$rootUrl/$cleanPath";
                                         }
                                         return CustomImage(
                                            path: profilePic,
                                            w: 100,
                                            h: 100,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, _) =>
                                                _nameInitialAvatar(user?.user?.name),
                                         );
                                      } else {
                                         return _nameInitialAvatar(user?.user?.name);
                                      }
                                    }
                                  }
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.buttonClr,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Information
                    _buildSectionCard(
                      title: "Contact Information",
                      icon: Icons.assignment_ind_rounded,
                      iconColor: Color(0xFF9C27B0), // Purple-ish
                      children: [
                        Text("Name", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: nameController,
                          hintText: "Enter your name",
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        
                        Text("Phone Number", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: phoneController,
                          hintText: "Phone Number",
                          textInputType: TextInputType.phone,
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                          suffix: Icon(Icons.phone, color: AppColors.buttonClr1),
                        ),
                        const SizedBox(height: 16),
                        
                        Text("Email Address", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: emailController,
                          hintText: "Email",
                          // readOnly: true,
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                          suffix: Icon(Icons.email, color: AppColors.buttonClr1),
                        ),
                      ],
                    ),

                    // Health Information
                    _buildSectionCard(
                      title: "Health Information",
                      icon: Icons.favorite_rounded,
                      iconColor: Color(0xFFE91E63), // Pink/Red
                      children: [
                        Text("Age", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: ageController,
                          hintText: "Enter your age",
                          textInputType: TextInputType.number,
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        const SizedBox(height: 16),

                        Text("Height", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                        CustomTextFormField(
                          controller: heightController,
                          hintText: "Enter height in cm",
                          textInputType: TextInputType.number,
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                          suffix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text("cm", style: AppFontStyle.text_14_400(color: AppColors.textClr)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text("Current Weight", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 8),
                         CustomTextFormField(
                          controller: weightController,
                          hintText: "55",
                          textInputType: TextInputType.number,
                          borderColor: AppColors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          filled: true,
                          fillColor: Colors.white,
                          suffix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text("kg", style: AppFontStyle.text_14_400(color: AppColors.textClr)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text("Medical Conditions", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: conditions.keys
                              .map((title) => buildConditionBox(title, conditions[title]!))
                              .toList(),
                        ),
                      ],
                    ),
                    
                    // Medical History / Stage Details
                    if (currentStage == "1") ...[ // Pregnancy
                      _buildSectionCard(
                        title: "Medical History",
                        icon: Icons.favorite, 
                        iconColor: Color(0xFFE91E63),
                        children: [
                          Text("Conception Date", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                          const SizedBox(height: 8),
                          CustomTextFormField(
                            controller: conceptionDateController,
                            hintText: "DD-MM-YYYY",
                            readOnly: true,
                            onTap: () => _selectDate(context, conceptionDateController),
                            borderColor: AppColors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            filled: true,
                            fillColor: Colors.white,
                            suffix: Icon(Icons.calendar_today, color: AppColors.buttonClr1, size: 20),
                          ),
                        ],
                      ),
                    ],

                    if (currentStage == "2") ...[ // Post-Pregnancy
                       _buildSectionCard(
                        title: "Baby Details",
                         icon: Icons.child_care,
                         iconColor: Color(0xFFE91E63),
                        children: [
                          Text("Baby Name", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                          const SizedBox(height: 8),
                           CustomTextFormField(
                            controller: babyNameController,
                            hintText: "Baby Name",
                            borderColor: AppColors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          
                          Text("Baby DOB", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                          const SizedBox(height: 8),
                          CustomTextFormField(
                            controller: babyDobController,
                            hintText: "DD-MM-YYYY",
                            readOnly: true,
                            onTap: () => _selectDate(context, babyDobController),
                            borderColor: AppColors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            filled: true,
                            fillColor: Colors.white,
                            suffix: Icon(Icons.calendar_today, color: AppColors.buttonClr1, size: 20),
                          ),
                          const SizedBox(height: 16),
                          
                          Text("Gender", style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
                          const SizedBox(height: 8),
                          CustomTextFormField(
                            controller: babyGenderController,
                            hintText: "Male / Female",
                            borderColor: AppColors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Update Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonClr,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.buttonClr1.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: updateProfile,
                        child: provider.updateProfileData?.status == ApiStatus.LOADING
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                "Update Profile",
                                style: AppFontStyle.text_16_600(
                                  color: Colors.white,
                                  fontFamily: AppFontFamily.gilroyBold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
