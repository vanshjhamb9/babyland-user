import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/features/ai_insights/controllers/dynamic_ai_insights_controller.dart';
import 'package:flutter/material.dart';

/// Horizontal scroll chips: All, Nutrition, Exercise, Precautions, Wellness.
class DynamicInsightCategoryChips extends StatelessWidget {
  const DynamicInsightCategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DynamicInsightCategory selected;
  final ValueChanged<DynamicInsightCategory> onSelected;

  static const _categories = DynamicInsightCategory.values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = selected == cat;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.buttonClr : null,
                  color: isSelected ? null : AppColors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: AppColors.textClr.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  cat.label,
                  style: AppFontStyle.text_13_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textLightClr,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
