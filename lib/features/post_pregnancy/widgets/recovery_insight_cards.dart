import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';

class RecoveryInsightCards extends StatelessWidget {
  final List<RecoveryInsight> insights;

  const RecoveryInsightCards({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: insights.map((i) {
        final color = switch (i.tone) {
          InsightTone.positive => Colors.green.shade700,
          InsightTone.attention => Colors.orange.shade800,
          InsightTone.neutral => DashboardTheme.accentRose,
        };
        final bg = switch (i.tone) {
          InsightTone.positive => Colors.green.withValues(alpha: 0.06),
          InsightTone.attention => Colors.orange.withValues(alpha: 0.06),
          InsightTone.neutral => DashboardTheme.accentRose.withValues(alpha: 0.06),
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DashboardSoftCard(
            color: bg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.title,
                        style: AppFontStyle.text_14_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: DashboardTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i.body,
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyRegular,
                          color: DashboardTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
