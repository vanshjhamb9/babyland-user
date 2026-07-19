import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/about_section.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          'About Us',
          style: AppFontStyle.text_20_400(
            fontFamily: AppFontFamily.gilroySemiBold,
            color: AppColors.black,
          ),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Babyland',
                style: AppFontStyle.text_16_600(
                  fontFamily: AppFontFamily.gilroyBold,
                  color: AppColors.textClr,
                ).copyWith(overflow: TextOverflow.visible),
                softWrap: true,
              ),
              const SizedBox(height: 16),
              const AboutSection(
                description:
                    'The Babyland is a holistic women-and-child wellness ecosystem built to support women through every stage of life—from preconception to pregnancy, postpartum, and early childhood. Focused on preventing and managing lifestyle-based disorders.',
              ),
              const AboutSection(
                description:
                    'We combine healthcare, nutrition, emotional wellbeing, and everyday essentials into one integrated platform. The Babyland is designed to simplify a journey that is often fragmented, confusing, and overwhelming for women and families.',
              ),
              const AboutSection(
                description:
                    'At the heart of The Babyland is a belief: care should be continuous, personalized, and rooted in both science and empathy.',
              ),
              const AboutSection(
                title: 'What We Offer',
                description: 'Through our platform, we offer:',
                bulletPoints: [
                  'IRA - your AI companion for AI-powered health insights and early risk detection with Integrated Health & Lifestyle Trackers',
                  'Personalized programs for fertility, pregnancy, postpartum, and baby care',
                  'Access to trusted experts across medical, nutrition, and wellness domains',
                  'Safe, natural, and thoughtfully designed products for mothers and babies',
                ],
              ),
              const AboutSection(
                description:
                    'We are building more than an app—we are creating a support system that understands a woman’s body, emotions, and evolving needs.',
              ),
              const AboutSection(
                description:
                    'The Babyland bridges the gap between clinical care and everyday living, ensuring that no women feels lost, unheard, or unsupported at any stage.',
              ),
              const AboutSection(
                description:
                    'We’re here to support and care for you—like a kangaroo does—keeping you and your little one safe, close, and nurtured at every stage.',
              ),
              const Divider(height: 40, thickness: 1, color: AppColors.borderColor),
              Text(
                'Medical Disclaimer: This information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or another qualified health provider with any questions you may have regarding a medical condition.',
                style: AppFontStyle.text_11_400(
                  fontFamily: AppFontFamily.gilroyRegular,
                  color: AppColors.textLightClr,
                ).copyWith(overflow: TextOverflow.visible, height: 1.5),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
