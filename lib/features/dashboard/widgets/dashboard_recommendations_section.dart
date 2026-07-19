import 'package:babyland/app/controller/pregnancy_flow/model/pregnancy_data_model.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_section_header.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:flutter/material.dart';

/// Tips from API recommendations + pregnancy AI insights.
class DashboardRecommendationsSection extends StatelessWidget {
  final List<AiData>? pregnancyInsights;

  const DashboardRecommendationsSection({
    super.key,
    this.pregnancyInsights,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Recommendations & tips',
          subtitle: 'Personalized ideas for this stage',
        ),
        FutureBuilder<List<Recommendation>>(
          future: sl.dashboardService.getRecommendations(days: 14),
          builder: (context, snap) {
            final apiItems = snap.data ?? const <Recommendation>[];
            final insightTiles = (pregnancyInsights ?? [])
                .where((e) => (e.message ?? '').trim().isNotEmpty)
                .take(4)
                .toList();

            if (snap.connectionState == ConnectionState.waiting && apiItems.isEmpty && insightTiles.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (apiItems.isEmpty && insightTiles.isEmpty) {
              return DashboardSoftCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: DashboardTheme.accentRose.withValues(alpha: 0.9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No tips yet',
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                              color: DashboardTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check back after your next log — we’ll surface gentle suggestions here.',
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
              );
            }

            return Column(
              children: [
                for (final r in apiItems.take(5)) ...[
                  DashboardSoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 22, color: DashboardTheme.textSecondary.withValues(alpha: 0.85)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroySemiBold,
                                  color: DashboardTheme.textPrimary,
                                ),
                              ),
                              if (r.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  r.description,
                                  style: AppFontStyle.text_12_400(
                                    fontFamily: AppFontFamily.gilroyRegular,
                                    color: DashboardTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final ai in insightTiles) ...[
                  DashboardSoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.spa_outlined, size: 22, color: DashboardTheme.accentRose.withValues(alpha: 0.95)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ai.message ?? '',
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: DashboardTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
