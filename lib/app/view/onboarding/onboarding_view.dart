
import 'package:babyland/app/controller/onboarding/onboarding_provider.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatelessWidget {
  final PageController _pageController = PageController();

  OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ChangeNotifierProvider<OnboardingProvider>(
        create: (context) {
          return OnboardingProvider();
        },
        child: SafeArea(
          child: Consumer<OnboardingProvider>(
            builder: (context, provider, _) {
              return  Stack(
                children: [

                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: provider.onboardingData.length,
                          onPageChanged: (value) {
                            provider.updateIndex(value);
                          },
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ClipPath(
                                  clipper: BottomCurveClipper(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.52,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.pinkPurple,
                                    ),
                                    child: Padding(
                                      padding:  EdgeInsets.only(top:120),
                                      child: Center(
                                        child: CustomImage(
                                          path: provider.onboardingData[index]['image'] ?? "",
                                          h: 300,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(provider.onboardingData[index]['title'] ?? "",
                                    style: AppFontStyle.text_28_400(color: AppColors.black,fontFamily: AppFontFamily.gilroySemiBold),
                                  maxLines: 5,
                                  textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                  child: Text(provider.onboardingData[index]['description'] ?? "",
                                    style: AppFontStyle.text_14_400(color: AppColors.textLightClr,fontFamily: AppFontFamily.gilroyRegular),
                                    maxLines: 5,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          provider.onboardingData.length,
                              (index1) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: index1 == provider.currentIndex ? 30 : 8,
                            decoration: BoxDecoration(
                              color: index1 == provider.currentIndex ?  AppColors.buttonClr1 :AppColors.greyStroke,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Button(
                          onTap: () {
                            if(provider.currentIndex < provider.onboardingData.length -1){
                              _pageController.animateToPage(provider.currentIndex+1, duration: Duration(microseconds: 100), curve: Curves.easeInOut);
                            }else{
                              UserPreference.saveIsFirstTime(false).then((value) {
                                Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.letsGetStartedView);
                              },);
                            }
                          },
                          width: double.infinity,
                          child: Center(child: Text(provider.currentIndex == 4 ? "Let’s get started" : "Continue",style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyBold,color: AppColors.white),)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                  Positioned(
                    right :16,
                    top:16,
                    child: InkWell(
                      onTap:(){
                        UserPreference.saveIsFirstTime(false).then((value) {
                          Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.letsGetStartedView);
                        },);
                      },
                      child: Text(
                        "Skip",
                        style: AppFontStyle.text_16_400(
                          color:  AppColors.textClr,
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
