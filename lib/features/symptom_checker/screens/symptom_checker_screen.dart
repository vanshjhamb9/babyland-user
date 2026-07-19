import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/text.dart';
import '../controllers/symptom_checker_controller.dart';
import '../widgets/symptom_result_card.dart';

/// AI Symptom Checker screen.
///
/// Users enter symptoms and receive AI-powered analysis.
class SymptomCheckerScreen extends StatelessWidget {
  const SymptomCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, color: AppColors.buttonClr2, size: 22),
            const SizedBox(width: 8),
            GradientText(
              'Symptom Checker',
              gradient: AppColors.buttonClr,
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<SymptomCheckerController>(
        builder: (context, controller, _) {
          return AppContainer(
            gradient: AppColors.backGroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Input Section ─────────────────────
                  _buildInputSection(context, controller),
                  const SizedBox(height: 16),

                  // ─── Selected Symptoms ─────────────────
                  if (controller.symptoms.isNotEmpty) ...[
                    Text(
                      'Your Symptoms',
                      style: AppFontStyle.text_16_600(
                        fontFamily: AppFontFamily.gilroySemiBold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.symptoms.map((symptom) {
                        return Chip(
                          label: Text(
                            symptom,
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.white,
                            ),
                          ),
                          backgroundColor: AppColors.buttonClr2,
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.white,
                          ),
                          onDeleted: () => controller.removeSymptom(symptom),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Common Symptoms ───────────────────
                  Text(
                    'Common Symptoms',
                    style: AppFontStyle.text_14_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textLightClr,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SymptomCheckerController.commonSymptoms.map((s) {
                      final isSelected = controller.symptoms.contains(s);
                      return GestureDetector(
                        onTap: () => isSelected
                            ? controller.removeSymptom(s)
                            : controller.addSymptom(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.buttonClr2.withValues(alpha: 0.12)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.buttonClr2
                                  : AppColors.borderColor,
                            ),
                          ),
                          child: Text(
                            s,
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: isSelected
                                  ? AppColors.buttonClr2
                                  : AppColors.textClr,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ─── Check Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonClr,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () => controller.checkSymptoms(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: controller.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: AppColors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Analyze Symptoms',
                                    style: AppFontStyle.text_16_600(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // ─── Error ─────────────────────────────
                  if (controller.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        controller.error!,
                        style: AppFontStyle.text_13_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.red,
                        ),
                      ),
                    ),

                  // ─── Result ────────────────────────────
                  if (controller.result != null) ...[
                    const SizedBox(height: 24),
                    SymptomResultCard(result: controller.result!),
                  ],

                  // ─── Disclaimer ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppContainer(
                      radius: 12,
                      padding: const EdgeInsets.all(14),
                      color: AppColors.lightYellow.withValues(alpha: 0.5),
                      borderColor: AppColors.yellow.withValues(alpha: 0.3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.orangeClr,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This AI analysis is for informational purposes only '
                              'and is not a substitute for professional medical advice. '
                              'Always consult your healthcare provider.',
                              style: AppFontStyle.text_12_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.orangeClr,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection(
      BuildContext context, SymptomCheckerController controller) {
    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      borderColor: AppColors.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What symptoms are you experiencing?',
            style: AppFontStyle.text_16_600(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: AppColors.textClr,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your symptoms below or tap common ones',
            style: AppFontStyle.text_13_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.symptomInput,
                  decoration: InputDecoration(
                    hintText: 'e.g., headache, nausea...',
                    hintStyle: AppFontStyle.text_14_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: AppColors.buttonClr2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                  onSubmitted: (val) => controller.addSymptom(val),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => controller.addSymptom(controller.symptomInput.text),
                child: AppContainer(
                  gradient: AppColors.buttonClr,
                  radius: 100,
                  padding: const EdgeInsets.all(14),
                  child: const Icon(Icons.add, color: AppColors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
