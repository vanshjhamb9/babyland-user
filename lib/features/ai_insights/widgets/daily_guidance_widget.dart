import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/text.dart';
import '../../../core/constants/app_constants.dart';
import '../models/ai_insight_model.dart';

/// Daily AI Guidance widget — refreshes once per day, cached offline.
class DailyGuidanceWidget extends StatelessWidget {
  final AiDailyGuidance? guidance;
  final bool isLoading;

  const DailyGuidanceWidget({
    super.key,
    this.guidance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer();

    if (guidance == null || guidance!.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppContainer(
      radius: 20,
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.buttonClr2.withValues(alpha: 0.08),
          AppColors.buttonClr1.withValues(alpha: 0.06),
        ],
      ),
      borderColor: AppColors.buttonClr2.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonClr,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      "Today's ${AppConstants.aiAssistantDisplayName} guidance",
                      gradient: AppColors.buttonClr,
                      style: AppFontStyle.text_18_600(
                        fontFamily: AppFontFamily.gilroyBold,
                      ),
                    ),
                    if (guidance!.greeting != null)
                      Text(
                        guidance!.greeting!,
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recommendations
          ...guidance!.recommendations.asMap().entries.map(
                (entry) => _buildRecommendationItem(entry.value, entry.key),
              ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text, int index) {
    final icons = [
      Icons.water_drop_outlined,
      Icons.directions_walk,
      Icons.restaurant_outlined,
      Icons.bedtime_outlined,
      Icons.medication_outlined,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.buttonClr1.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icons[index % icons.length],
              size: 16,
              color: AppColors.buttonClr2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textClr,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: AppContainer(
        radius: 20,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
