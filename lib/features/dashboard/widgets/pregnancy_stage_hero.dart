import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Top “Current stage” card: week, trimester, growth message, progress.
class PregnancyStageHero extends StatelessWidget {
  final String currentWeek;
  final String trimester;
  final String expectedDueDate;
  final String fetalGrowthStage;
  final String? fetalSizeLine;
  final double progressPercent;

  const PregnancyStageHero({
    super.key,
    required this.currentWeek,
    required this.trimester,
    required this.expectedDueDate,
    required this.fetalGrowthStage,
    this.fetalSizeLine,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final weekNum = int.tryParse(currentWeek) ?? 0;
    final friendlyWeek = weekNum > 0 ? 'Week $currentWeek' : 'Your journey';
    final subtitle = fetalGrowthStage.isNotEmpty
        ? 'Week $currentWeek – $fetalGrowthStage'
        : '$friendlyWeek – Baby is growing well';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DashboardTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: DashboardTheme.softPinkGradient,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white.withValues(alpha: 0.95), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You're doing great 💕",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppFontStyle.text_18_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: Colors.white,
            ),
          ),
          if (fetalSizeLine != null && fetalSizeLine!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              fetalSizeLine!,
              style: AppFontStyle.text_13_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: 'Trimester $trimester', icon: Icons.layers_outlined),
              if (expectedDueDate.isNotEmpty)
                _Chip(
                  text: 'Due ${_formatDue(expectedDueDate)}',
                  icon: Icons.calendar_month_outlined,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GradientProgressBar(
                  progress: progressPercent,
                  height: 10,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${progressPercent.toStringAsFixed(0)}%',
                style: AppFontStyle.text_12_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDue(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('d MMM yyyy').format(parsed);
    }
    return raw;
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
