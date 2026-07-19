import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../models/timeline_week_model.dart';

/// A single timeline card widget with expand/collapse.
class TimelineCard extends StatelessWidget {
  final TimelineWeekModel week;
  final bool isExpanded;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const TimelineCard({
    super.key,
    required this.week,
    required this.isExpanded,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Timeline Rail ─────────────────────
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Top connector line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: AppColors.buttonClr2.withValues(alpha: 0.3),
                  ),
                // Dot
                Container(
                  width: isExpanded ? 18 : 14,
                  height: isExpanded ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isExpanded ? AppColors.buttonClr : null,
                    color: isExpanded
                        ? null
                        : AppColors.buttonClr2.withValues(alpha: 0.3),
                    border: isExpanded
                        ? null
                        : Border.all(
                            color: AppColors.buttonClr2.withValues(alpha: 0.5),
                            width: 2,
                          ),
                  ),
                  child: isExpanded
                      ? const Center(
                          child: Icon(Icons.child_care,
                              size: 10, color: AppColors.white),
                        )
                      : null,
                ),
                // Bottom connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.buttonClr2.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Card Content ──────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.buttonClr2.withValues(alpha: 0.06)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? AppColors.buttonClr2.withValues(alpha: 0.3)
                          : AppColors.borderColor,
                    ),
                    boxShadow: isExpanded
                        ? [
                            BoxShadow(
                              color: AppColors.buttonClr2.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  isExpanded ? AppColors.buttonClr : null,
                              color: isExpanded
                                  ? null
                                  : AppColors.buttonClr2.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Week ${week.week}',
                              style: AppFontStyle.text_12_600(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: isExpanded
                                    ? AppColors.white
                                    : AppColors.buttonClr2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '🍼 ${week.babySizeComparison}',
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyMedium,
                              color: AppColors.textLightClr,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textLightClr,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Baby size: ${week.babySize}',
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: AppColors.textLightClr,
                        ),
                      ),

                      // ─── Expanded Content ──────────────
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.borderColor),
                        const SizedBox(height: 12),

                        // Body Changes
                        _buildDetailSection(
                          icon: Icons.pregnant_woman,
                          title: 'Body Changes',
                          content: week.bodyChanges,
                          color: AppColors.buttonClr2,
                        ),
                        const SizedBox(height: 10),

                        // Medical Checkups
                        if (week.medicalCheckups.isNotEmpty)
                          _buildListSection(
                            icon: Icons.medical_services_outlined,
                            title: 'Medical Checkups',
                            items: week.medicalCheckups,
                            color: AppColors.red,
                          ),
                        if (week.medicalCheckups.isNotEmpty)
                          const SizedBox(height: 10),

                        // Recommended Activities
                        if (week.recommendedActivities.isNotEmpty)
                          _buildListSection(
                            icon: Icons.fitness_center,
                            title: 'Recommended Activities',
                            items: week.recommendedActivities,
                            color: AppColors.green,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFontStyle.text_13_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textClr,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFontStyle.text_13_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: AppFontStyle.text_13_400(
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
        ),
      ],
    );
  }
}
