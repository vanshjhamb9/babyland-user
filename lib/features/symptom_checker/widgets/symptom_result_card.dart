import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../core/constants/app_constants.dart';
import '../models/symptom_check_model.dart';

/// Displays the AI symptom analysis result.
class SymptomResultCard extends StatelessWidget {
  final SymptomCheckResult result;

  const SymptomResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppConstants.aiAssistantDisplayName} Analysis',
          style: AppFontStyle.text_18_600(
            fontFamily: AppFontFamily.gilroyBold,
            color: AppColors.textClr,
          ),
        ),
        const SizedBox(height: 12),

        // ─── Risk Level ────────────────────────
        _buildRiskLevelCard(),
        const SizedBox(height: 12),
        if (result.alertMessage != null && result.alertMessage!.isNotEmpty) ...[
          AppContainer(
            radius: 12,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF0F0),
            borderColor: const Color(0xFFFFCDD2),
            child: Text(
              result.alertMessage!,
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroySemiBold,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ─── Possible Causes ───────────────────
        _buildSection(
          title: 'Possible Causes',
          icon: Icons.search,
          iconColor: AppColors.purpleClr,
          bgColor: AppColors.lightPurple.withValues(alpha: 0.3),
          items: result.possibleCauses,
        ),
        const SizedBox(height: 12),

        // ─── Recommended Actions ───────────────
        _buildSection(
          title: 'Recommended Actions',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.green,
          bgColor: AppColors.lightGreen.withValues(alpha: 0.4),
          items: result.recommendedActions,
        ),
        const SizedBox(height: 12),

        // ─── When to Contact Doctor ────────────
        AppContainer(
          radius: 16,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFFFF0F0),
          borderColor: const Color(0xFFFFCDD2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emergency_outlined,
                      color: AppColors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'When to Contact Doctor',
                    style: AppFontStyle.text_15_600(
                      fontFamily: AppFontFamily.gilroySemiBold,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                result.whenToContactDoctor,
                style: AppFontStyle.text_14_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
        ),

        // ─── Raw Response (if fallback) ────────
        if (result.rawResponse.isNotEmpty &&
            result.possibleCauses.length == 1 &&
            result.possibleCauses.first == 'See detailed analysis below') ...[
          const SizedBox(height: 12),
          AppContainer(
            radius: 16,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            borderColor: AppColors.borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Analysis',
                  style: AppFontStyle.text_15_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.rawResponse,
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textClr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRiskLevelCard() {
    Color riskColor;
    IconData riskIcon;
    final riskTag = result.riskTag.toLowerCase();
    final riskLower = result.riskLevel.toLowerCase();

    if (riskTag == 'critical') {
      riskColor = AppColors.red;
      riskIcon = Icons.error_outline;
    } else if (riskTag == 'high' ||
        riskLower.contains('high') ||
        riskLower.contains('severe')) {
      riskColor = AppColors.red;
      riskIcon = Icons.warning_amber;
    } else if (riskTag == 'medium' ||
        riskLower.contains('moderate') ||
        riskLower.contains('medium')) {
      riskColor = AppColors.yellow;
      riskIcon = Icons.info_outline;
    } else {
      riskColor = AppColors.green;
      riskIcon = Icons.check_circle_outline;
    }

    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          riskColor.withValues(alpha: 0.08),
          riskColor.withValues(alpha: 0.03),
        ],
      ),
      borderColor: riskColor.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(riskIcon, color: riskColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Level',
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.riskLevel,
                  style: AppFontStyle.text_18_600(
                    fontFamily: AppFontFamily.gilroyBold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: bgColor,
      borderColor: iconColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppFontStyle.text_15_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppFontStyle.text_14_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textClr,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
