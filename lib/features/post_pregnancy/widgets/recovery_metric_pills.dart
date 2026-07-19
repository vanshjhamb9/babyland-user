import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:flutter/material.dart';

class RecoveryMetricPills extends StatelessWidget {
  final List<RecoveryBreakdownMetric> metrics;

  const RecoveryMetricPills({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.take(6).map(_pill).toList(),
    );
  }

  Widget _pill(RecoveryBreakdownMetric m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardTheme.accentLavender.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardTheme.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(m.iconKey), size: 16, color: DashboardTheme.accentRose),
          const SizedBox(width: 6),
          Text(
            m.label,
            style: AppFontStyle.text_11_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            m.unit == 'days'
                ? '${m.value.toInt()} ${m.unit}'
                : '${m.value.round()}${m.unit == '/10' ? m.unit : m.unit}',
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: DashboardTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'hydration':
        return Icons.water_drop_outlined;
      case 'mood':
        return Icons.favorite_border;
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'pain':
        return Icons.healing_outlined;
      case 'feeding':
        return Icons.child_care_outlined;
      case 'streak':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.trending_up;
    }
  }
}
