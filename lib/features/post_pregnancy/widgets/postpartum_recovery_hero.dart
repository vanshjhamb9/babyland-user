import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/post_pregnancy/widgets/postpartum_dashboard_card.dart';
import 'package:babyland/features/post_pregnancy/widgets/recovery_metric_pills.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostpartumRecoveryHero extends StatelessWidget {
  final PostpartumRecoverySnapshot? snapshot;
  final bool isLoading;
  final VoidCallback onViewAnalytics;
  final VoidCallback onLogProgress;

  const PostpartumRecoveryHero({
    super.key,
    required this.snapshot,
    required this.isLoading,
    required this.onViewAnalytics,
    required this.onLogProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && snapshot == null) {
      return PostpartumDashboardCard(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: const SizedBox(height: 120, width: double.infinity),
        ),
      );
    }

    final s = snapshot ?? PostpartumRecoverySnapshot.empty();
    final score = s.overallScore;
    final hasData = s.hasAnyLogs || s.hasClinicalData || score > 0;
    final delta = s.weeklyDeltaPercent;
    final deltaText = delta >= 0
        ? '+${delta.round()}% this week'
        : '${delta.round()}% this week';

    return PostpartumDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.buttonClr.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Icon(Icons.favorite, size: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recovery Progress',
                  style: AppFontStyle.text_16_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAnalytics,
                child: Text(
                  'Analytics',
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.buttonClr1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData) ...[
            Text(
              'Start logging your recovery journey',
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroySemiBold,
                color: DashboardTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track hydration, mood, sleep and symptoms daily to unlock personalized recovery analytics.',
              style: AppFontStyle.text_12_400(
                fontFamily: AppFontFamily.gilroyRegular,
                color: DashboardTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogProgress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonClr1,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Log Daily Progress',
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyBold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '${(v * 100).round()}%',
                    style: AppFontStyle.text_32_400(
                      fontFamily: AppFontFamily.gilroyBold,
                      color: AppColors.buttonClr1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall recovery',
                        style: AppFontStyle.text_12_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                          color: DashboardTheme.textSecondary,
                        ),
                      ),
                      if (s.recoveryStreakDays > 0)
                        Text(
                          '${s.recoveryStreakDays}-day streak · $deltaText',
                          style: AppFontStyle.text_11_400(
                            fontFamily: AppFontFamily.gilroyRegular,
                            color: DashboardTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientProgressBar(progress: score.clamp(0, 100), height: 8),
            const SizedBox(height: 8),
            Text(
              'Score blends mood, hydration, sleep, symptoms, tasks & daily logs.',
              style: AppFontStyle.text_11_400(
                fontFamily: AppFontFamily.gilroyRegular,
                color: DashboardTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks ${s.taskCompletionPercent.round()}%',
                  style: AppFontStyle.text_11_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: DashboardTheme.textSecondary,
                  ),
                ),
                Text(
                  '${s.logsThisWeek}/7 days logged',
                  style: AppFontStyle.text_11_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: DashboardTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RecoveryMetricPills(metrics: s.breakdown),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewAnalytics,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.buttonClr1,
                      side: BorderSide(color: AppColors.buttonClr1.withValues(alpha: 0.5)),
                    ),
                    child: const Text('View trends'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLogProgress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonClr1,
                    ),
                    child: const Text('Log today'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
