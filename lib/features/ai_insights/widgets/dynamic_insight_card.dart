import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/features/ai_insights/controllers/dynamic_ai_insights_controller.dart';
import 'package:flutter/material.dart';

/// Card for one insight: emoji/icon + title + description.
class DynamicInsightCard extends StatelessWidget {
  const DynamicInsightCard({super.key, required this.entry});

  final DynamicInsightEntry entry;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final emoji = item.emoji?.trim();
    final hasEmoji = emoji != null && emoji.isNotEmpty;

    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      color: _backgroundFor(entry.categoryKey),
      borderColor: _borderFor(entry.categoryKey),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _iconBg(entry.categoryKey),
              borderRadius: BorderRadius.circular(14),
            ),
            child: hasEmoji
                ? Text(emoji, style: const TextStyle(fontSize: 26))
                : Icon(
                    _iconFor(entry.categoryKey),
                    color: _accent(entry.categoryKey),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? 'Insight',
                  style: AppFontStyle.text_16_600(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description ?? '',
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _backgroundFor(String category) {
    switch (category) {
      case 'nutrition':
        return AppColors.lightGreen.withValues(alpha: 0.35);
      case 'exercise':
        return AppColors.lightBlue.withValues(alpha: 0.4);
      case 'precautions':
        return AppColors.lightYellow.withValues(alpha: 0.45);
      case 'wellness':
        return const Color(0xFFFFF0F5);
      default:
        return AppColors.white;
    }
  }

  Color _borderFor(String category) {
    switch (category) {
      case 'nutrition':
        return AppColors.lightGreen;
      case 'exercise':
        return AppColors.lightBlue;
      case 'precautions':
        return AppColors.lightYellow;
      case 'wellness':
        return const Color(0xFFFFD6E8);
      default:
        return AppColors.borderColor;
    }
  }

  Color _iconBg(String category) {
    return _accent(category).withValues(alpha: 0.12);
  }

  Color _accent(String category) {
    switch (category) {
      case 'nutrition':
        return AppColors.green;
      case 'exercise':
        return const Color(0xFF0066CC);
      case 'precautions':
        return AppColors.orangeClr;
      case 'wellness':
        return AppColors.darkBrown;
      default:
        return AppColors.buttonClr2;
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'nutrition':
        return Icons.restaurant_menu_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'precautions':
        return Icons.health_and_safety_outlined;
      case 'wellness':
        return Icons.spa_rounded;
      default:
        return Icons.auto_awesome;
    }
  }
}
