import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';

/// Filter chip row for insight types.
class InsightFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const InsightFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const _filters = [
    {'key': 'all', 'label': 'All', 'icon': Icons.dashboard},
    {'key': 'growth', 'label': 'Growth', 'icon': Icons.child_care},
    {'key': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant_menu},
    {'key': 'exercise', 'label': 'Exercise', 'icon': Icons.fitness_center},
    {'key': 'medical', 'label': 'Medical', 'icon': Icons.medical_services_outlined},
    {'key': 'development', 'label': 'Development', 'icon': Icons.timeline},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final key = filter['key'] as String;
          final isSelected = selectedFilter == key;

          return GestureDetector(
            onTap: () => onFilterChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.buttonClr : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? AppColors.white : AppColors.textLightClr,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: AppFontStyle.text_12_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: isSelected ? AppColors.white : AppColors.textLightClr,
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
}
