import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';

/// Quick AI suggestion chips for the AI assistant.
///
/// Displays tappable chip suggestions like:
/// - "Is nausea normal?"
/// - "Pregnancy diet tips"
/// - "Baby development this week"
class AiSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onChipTapped;

  const AiSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onChipTapped,
  });

  static const defaultSuggestions = [
    'Is nausea normal?',
    'Pregnancy diet tips',
    'Baby development this week',
    'Safe exercises for pregnancy',
    'When to call the doctor',
    'Managing back pain',
  ];

  @override
  Widget build(BuildContext context) {
    final chips = suggestions.isEmpty ? defaultSuggestions : suggestions;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onChipTapped(chips[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.buttonClr2.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonClr2.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppColors.buttonClr2.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chips[index],
                    style: AppFontStyle.text_13_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textClr,
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
