import 'package:babyland/app/controller/basic_information/basic_profile_provider.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BasicProfileView extends StatefulWidget {
  const BasicProfileView({super.key});

  @override
  State<BasicProfileView> createState() => _BasicProfileViewState();
}

class _BasicProfileViewState extends State<BasicProfileView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BasicProfileProvider>(
      create: (context) => BasicProfileProvider(),
      child: Consumer<BasicProfileProvider>(
        builder: (context, provider, _) {
          return WillPopScope(
            onWillPop: () async {
              if (provider.currentIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
                return false;
              }
              return true;
            },
            child: Scaffold(
              body: AppContainer(
                gradient: AppColors.backGroundColor,
                child: Column(
                  children: [
                    CustomAppBar(
                      centerTitle: true,
                      leading: provider.currentIndex > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                      title: Text(
                        "Tell us about yourself",
                        style: AppFontStyle.text_20_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                        ),
                      ),
                      backgroundClr: AppColors.transparent,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: 25,
                          decoration: BoxDecoration(
                            color: index <= provider.currentIndex
                                ? AppColors.buttonClr1
                                : AppColors.greyStroke,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (value) {
                          provider.changeIndex(value);
                        },
                        children: [
                          _buildNameStep(provider),
                          _buildAgeStep(provider),
                          _buildHeightStep(provider),
                          _buildWeightStep(provider),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomBtn(provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFontStyle.text_24_400(
              color: AppColors.textClr,
              fontFamily: AppFontFamily.gilroySemiBold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppFontStyle.text_16_400(
              color: AppColors.textLightClr,
              fontFamily: AppFontFamily.gilroyRegular,
            ),
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildNameStep(BasicProfileProvider provider) {
    return _buildStepContainer(
      title: "What’s your name? *",
      subtitle: "Personalize your journey with us.",
      child: CustomTextFormField(
        controller: provider.nameController,
        hintText: "Enter your name",
        borderColor: AppColors.borderColor,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _nextPage(provider),
      ),
    );
  }

  Widget _buildAgeStep(BasicProfileProvider provider) {
    return _buildStepContainer(
      title: "How old are you? *",
      subtitle: "This helps us provide age-appropriate insights.",
      child: CustomTextFormField(
        controller: provider.ageController,
        hintText: "Enter your age",
        borderColor: AppColors.borderColor,
        textInputType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _nextPage(provider),
      ),
    );
  }

  Widget _buildHeightStep(BasicProfileProvider provider) {
    return _buildStepContainer(
      title: "What’s your height? *",
      subtitle: "This helps in calculating your health metrics.",
      child: CustomTextFormField(
        controller: provider.heightController,
        hintText: "Enter height (in cm)",
        borderColor: AppColors.borderColor,
        textInputType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _nextPage(provider),
      ),
    );
  }

  Widget _buildWeightStep(BasicProfileProvider provider) {
    return _buildStepContainer(
      title: "What’s your weight? *",
      subtitle: "To track your wellness journey effectively.",
      child: CustomTextFormField(
        controller: provider.weightController,
        hintText: "Enter weight (in kg)",
        borderColor: AppColors.borderColor,
        textInputType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => provider.submitProfile(context),
      ),
    );
  }

  void _nextPage(BasicProfileProvider provider) {
    if (provider.currentIndex < 3) {
      // Basic validation for current field
      bool isValid = false;
      if (provider.currentIndex == 0 && provider.nameController.text.isNotEmpty) isValid = true;
      if (provider.currentIndex == 1 && provider.ageController.text.isNotEmpty) isValid = true;
      if (provider.currentIndex == 2 && provider.heightController.text.isNotEmpty) isValid = true;

      if (isValid) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill the mandatory field")),
        );
      }
    }
  }

  Widget _buildBottomBtn(BasicProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.backGroundColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Button(
        height: 58,
        onTap: () {
          if (provider.currentIndex < 3) {
            _nextPage(provider);
          } else {
            provider.submitProfile(context);
          }
        },
        child: provider.updateProfileData?.status == ApiStatus.LOADING
            ? customLoading(color: AppColors.white)
            : Text(
                provider.currentIndex == 3 ? "Submit" : "Continue",
                style: AppFontStyle.text_16_400(
                  fontFamily: AppFontFamily.gilroyBold,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
