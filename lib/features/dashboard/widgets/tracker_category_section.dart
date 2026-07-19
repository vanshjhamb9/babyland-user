import 'package:babyland/app/navbar/pregnancy/navbar_controller.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/ai_insights/controllers/dynamic_ai_insights_controller.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_section_header.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens AI Insights with the matching category chip selected.
class TrackerCategorySection extends StatelessWidget {
  final Future<DashboardData>? dashboardFuture;

  const TrackerCategorySection({
    super.key,
    required this.dashboardFuture,
  });

  void _openInsights(BuildContext context, DynamicInsightCategory category) {
    context.read<DynamicAiInsightsController>().selectCategory(category);
    context.read<NavBarProvider>().setSelectedIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Insights',
          subtitle:
              'Personalized tips by topic — tap to open ${AppConstants.aiAssistantDisplayName} Insights',
        ),
        FutureBuilder<DashboardData>(
          future: dashboardFuture,
          builder: (context, snap) {
            final sleepMin = snap.hasData ? snap.data!.healthSummary.sleep.lastNight : 0;
            final sleepHint = sleepMin > 0
                ? '${sleepMin ~/ 60}h ${sleepMin % 60}m last night'
                : 'Rest & recovery tips';
            return Column(
              children: [
                _CategoryRow(
                  icon: Icons.favorite_outline,
                  title: 'Health insight',
                  subtitle: 'Holistic tips — mood, hydration & balance',
                  color: DashboardTheme.accentLavender,
                  onTap: () => _openInsights(context, DynamicInsightCategory.all),
                ),
                const SizedBox(height: 8),
                _CategoryRow(
                  icon: Icons.restaurant_outlined,
                  title: 'Nutrition insight',
                  subtitle: 'Meals & nutrients for you and baby',
                  color: DashboardTheme.accentPeach,
                  onTap: () => _openInsights(context, DynamicInsightCategory.nutrition),
                ),
                const SizedBox(height: 8),
                _CategoryRow(
                  icon: Icons.nightlight_outlined,
                  title: 'Sleep insight',
                  subtitle: sleepHint,
                  color: const Color(0xFFE3F2FD),
                  onTap: () => _openInsights(context, DynamicInsightCategory.wellness),
                ),
                const SizedBox(height: 8),
                _CategoryRow(
                  icon: Icons.directions_run_outlined,
                  title: 'Activity insight',
                  subtitle: 'Gentle movement & exercise guidance',
                  color: const Color(0xFFE8F5E9),
                  onTap: () => _openInsights(context, DynamicInsightCategory.exercise),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: DashboardTheme.textPrimary.withValues(alpha: 0.85)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFontStyle.text_15_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: DashboardTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DashboardTheme.textSecondary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
