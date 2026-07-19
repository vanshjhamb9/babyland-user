import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/button.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostpartumRecoveryLogView extends StatefulWidget {
  const PostpartumRecoveryLogView({super.key});

  @override
  State<PostpartumRecoveryLogView> createState() => _PostpartumRecoveryLogViewState();
}

class _PostpartumRecoveryLogViewState extends State<PostpartumRecoveryLogView> {
  final PageController _pageController = PageController();
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PostpregnancyProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: CustomAppBar(
            centerTitle: true,
            title: Text(
              "Recovery Track & Scale",
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroySemiBold,
                color: AppColors.black,
              ),
            ),
          ),
          body: AppContainer(
            gradient: AppColors.backGroundColor,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProgressIndicator(),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (v) => setState(() => _stepIndex = v),
                    children: [
                      _buildPhysicalHealingStep(provider),
                      _buildUterineRecoveryStep(provider),
                      _buildEnergyStrengthStep(provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(provider),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: 40,
          decoration: BoxDecoration(
            color: index <= _stepIndex ? AppColors.buttonClr1 : AppColors.greyStroke,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFontStyle.text_22_600(color: AppColors.textClr)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppFontStyle.text_14_400(color: AppColors.textLightClr)),
          const SizedBox(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPhysicalHealingStep(PostpregnancyProvider provider) {
    return _buildStepContainer(
      title: "Physical Healing",
      subtitle: "How is your body healing today?",
      children: [
        _buildLabel("Pain Level (0-10)"),
        Slider(
          value: provider.painLevel.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.buttonClr1,
          label: provider.painLevel.toString(),
          onChanged: (v) => provider.updatePhysical(pain: v.round()),
        ),
        _buildChoiceGroup(
          label: "Wound Healing",
          options: ["Poor", "Okay", "Good"],
          selected: provider.woundHealing,
          onSelect: (v) => provider.updatePhysical(wound: v),
        ),
        _buildChoiceGroup(
          label: "Swelling",
          options: ["High", "Mild", "None"],
          selected: provider.swelling,
          onSelect: (v) => provider.updatePhysical(swell: v),
        ),
        _buildChoiceGroup(
          label: "Mobility",
          options: ["Limited", "Moderate", "Normal"],
          selected: provider.mobility,
          onSelect: (v) => provider.updatePhysical(mob: v),
        ),
      ],
    );
  }

  Widget _buildUterineRecoveryStep(PostpregnancyProvider provider) {
    return _buildStepContainer(
      title: "Uterine Recovery",
      subtitle: "Tracking uterine involution and comfort.",
      children: [
        _buildChoiceGroup(
          label: "Cramps",
          options: ["Severe", "Mild", "None"],
          selected: provider.cramps,
          onSelect: (v) => provider.updateUterine(cramp: v),
        ),
        _buildChoiceGroup(
          label: "Belly Reduction",
          options: ["No change", "Slow", "Good progress"],
          selected: provider.bellyReduction,
          onSelect: (v) => provider.updateUterine(belly: v),
        ),
      ],
    );
  }

  Widget _buildEnergyStrengthStep(PostpregnancyProvider provider) {
    return _buildStepContainer(
      title: "Energy & Strength",
      subtitle: "How are your energy levels today?",
      children: [
        _buildChoiceGroup(
          label: "Energy Level",
          options: ["Low", "Moderate", "High"],
          selected: provider.energyLevel,
          onSelect: (v) => provider.updateEnergy(energy: v),
        ),
        _buildChoiceGroup(
          label: "Fatigue",
          options: ["High", "Medium", "Low"],
          selected: provider.fatigue,
          onSelect: (v) => provider.updateEnergy(fat: v),
        ),
        _buildChoiceGroup(
          label: "Daily Activity Ability",
          options: ["Limited", "Moderate", "Normal"],
          selected: provider.dailyActivity,
          onSelect: (v) => provider.updateEnergy(activity: v),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: AppFontStyle.text_16_400(
          fontFamily: AppFontFamily.gilroySemiBold,
          color: AppColors.textClr,
        ),
      ),
    );
  }

  Widget _buildChoiceGroup({
    required String label,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Wrap(
          spacing: 10,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelect(opt),
              selectedColor: AppColors.buttonClr1,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textClr,
                fontFamily: AppFontFamily.gilroyMedium,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.buttonClr1 : AppColors.greyStroke,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(PostpregnancyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Button(
        height: 56,
        onTap: () {
          if (_stepIndex < 2) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            provider.submitRecoveryLog(
              date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
            );
          }
        },
        child: provider.recoveryLogStatus?.status == ApiStatus.LOADING
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _stepIndex == 2 ? "Finish & Save" : "Next Step",
                style: AppFontStyle.text_16_400(
                  fontFamily: AppFontFamily.gilroyBold,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
