import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_section_header.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:flutter/material.dart';

/// Quick stats: water, sleep, activity — uses [DashboardData] when available.
class TodaySummarySection extends StatelessWidget {
  final Future<DashboardData>? dashboardFuture;

  const TodaySummarySection({super.key, required this.dashboardFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Today',
          subtitle: 'A snapshot of how you’re caring for yourself',
        ),
        FutureBuilder<DashboardData>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SummarySkeleton();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return DashboardSoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_outlined, color: DashboardTheme.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(height: 8),
                    Text(
                      'We couldn’t load today’s summary',
                      style: AppFontStyle.text_14_400(
                        fontFamily: AppFontFamily.gilroySemiBold,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pull to refresh — your trackers will appear here.',
                      style: AppFontStyle.text_12_400(
                        fontFamily: AppFontFamily.gilroyRegular,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            final h = snapshot.data!.healthSummary;
            final waterL = h.hydration.today / 1000.0;
            final sleepMin = h.sleep.lastNight;
            final sleepLabel = sleepMin > 0
                ? '${sleepMin ~/ 60}h ${sleepMin % 60}m'
                : '—';
            final activityCount = h.symptoms.activeCount;
            final activityLabel = '$activityCount';
            final activityUnit = activityCount == 1
                ? 'symptom noted'
                : 'symptoms noted';

            return DashboardSoftCard(
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.water_drop_outlined,
                      label: 'Water',
                      value: '${waterL.toStringAsFixed(1)} L',
                      unit: 'goal ${(h.hydration.goal / 1000).toStringAsFixed(1)} L',
                    ),
                  ),
                  Container(width: 1, height: 52, color: DashboardTheme.stroke),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.bedtime_outlined,
                      label: 'Sleep',
                      value: sleepLabel,
                      unit: 'last night',
                    ),
                  ),
                  Container(width: 1, height: 52, color: DashboardTheme.stroke),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.directions_walk_outlined,
                      label: 'Activity',
                      value: activityLabel,
                      unit: activityUnit,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: DashboardTheme.accentRose.withValues(alpha: 0.95)),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppFontStyle.text_11_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFontStyle.text_14_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: DashboardTheme.textPrimary,
            ),
          ),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppFontStyle.text_10_400(
              fontFamily: AppFontFamily.gilroyRegular,
              color: DashboardTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: DashboardTheme.cardDecoration(),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
