import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../models/ai_insight_model.dart';

/// A beautiful card widget for displaying a single AI insight.
class InsightCard extends StatelessWidget {
  final AiInsightModel insight;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      onTap: onTap,
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: _getBackgroundColor(),
      borderColor: _getBorderColor(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: AppFontStyle.text_16_600(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.textClr,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getTagColor(),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _getTagText(),
                        style: AppFontStyle.text_10_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: _getIconColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  insight.description,
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (insight.type) {
      case 'growth':
        return Icons.child_care;
      case 'nutrition':
        return Icons.restaurant_menu;
      case 'exercise':
        return Icons.fitness_center;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'development':
        return Icons.timeline;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getBackgroundColor() {
    switch (insight.type) {
      case 'growth':
        return AppColors.lightPurple.withValues(alpha: 0.3);
      case 'nutrition':
        return AppColors.lightGreen.withValues(alpha: 0.4);
      case 'exercise':
        return AppColors.lightBlue.withValues(alpha: 0.4);
      case 'medical':
        return AppColors.lightYellow.withValues(alpha: 0.4);
      case 'development':
        return const Color(0xFFFFF0F5);
      default:
        return AppColors.white;
    }
  }

  Color _getBorderColor() {
    switch (insight.type) {
      case 'growth':
        return AppColors.lightPurple;
      case 'nutrition':
        return AppColors.lightGreen;
      case 'exercise':
        return AppColors.lightBlue;
      case 'medical':
        return AppColors.lightYellow;
      case 'development':
        return const Color(0xFFFFD6E8);
      default:
        return AppColors.borderColor;
    }
  }

  Color _getIconColor() {
    switch (insight.type) {
      case 'growth':
        return AppColors.purpleClr;
      case 'nutrition':
        return AppColors.green;
      case 'exercise':
        return const Color(0xFF0066CC);
      case 'medical':
        return AppColors.orangeClr;
      case 'development':
        return AppColors.darkBrown;
      default:
        return AppColors.buttonClr2;
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withValues(alpha: 0.12);
  }

  Color _getTagColor() {
    return _getIconColor().withValues(alpha: 0.1);
  }

  String _getTagText() {
    switch (insight.type) {
      case 'growth':
        return 'Growth';
      case 'nutrition':
        return 'Nutrition';
      case 'exercise':
        return 'Exercise';
      case 'medical':
        return 'Medical';
      case 'development':
        return 'Development';
      default:
        return 'Insight';
    }
  }
}
