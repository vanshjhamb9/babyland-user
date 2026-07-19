import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_section_header.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:flutter/material.dart';

class PostpartumRecoveryDashboard extends StatelessWidget {
  final Future<DashboardData>? dashboardFuture;
  final PostpartumRecoverySnapshot? recoverySnapshot;

  const PostpartumRecoveryDashboard({
    super.key,
    required this.dashboardFuture,
    this.recoverySnapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: 'Recovery Score™',
            subtitle: 'Clinically validated postpartum recovery tracking',
          ),
          if (recoverySnapshot != null &&
              (recoverySnapshot!.hasAnyLogs || recoverySnapshot!.overallScore > 0))
            _OverallHero(snapshot: recoverySnapshot!)
          else
            FutureBuilder<DashboardData>(
              future: dashboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _RecoverySkeleton();
                }

                final summary = snapshot.data?.healthSummary.postpartumRecovery;
                if (snapshot.hasError || summary == null) {
                  return _EmptyRecoveryCard();
                }

                final overall = summary.overallScore > 0
                    ? summary.overallScore
                    : (summary.physicalHealingScore +
                            summary.uterineRecoveryScore +
                            summary.energyStrengthScore) /
                        3.0;

                return Column(
                  children: [
                    DashboardSoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${overall.round()}%',
                                style: AppFontStyle.text_24_400(
                                  fontFamily: AppFontFamily.gilroyBold,
                                  color: AppColors.buttonClr1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Overall recovery',
                                style: AppFontStyle.text_12_400(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: DashboardTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ScoreTile(
                                  icon: Icons.healing_outlined,
                                  label: 'Physical',
                                  score: summary.physicalHealingScore,
                                  status: summary.physicalStatus ?? 'Normal',
                                  color: _getStatusColor(summary.physicalHealingScore),
                                ),
                              ),
                              Container(width: 1, height: 60, color: DashboardTheme.stroke),
                              Expanded(
                                child: _ScoreTile(
                                  icon: Icons.opacity_outlined,
                                  label: 'Uterine',
                                  score: summary.uterineRecoveryScore,
                                  status: summary.uterineStatus ?? 'Normal',
                                  color: _getStatusColor(summary.uterineRecoveryScore),
                                ),
                              ),
                              Container(width: 1, height: 60, color: DashboardTheme.stroke),
                              Expanded(
                                child: _ScoreTile(
                                  icon: Icons.bolt_outlined,
                                  label: 'Energy',
                                  score: summary.energyStrengthScore,
                                  status: summary.energyStatus ?? 'Strong',
                                  color: _getStatusColor(summary.energyStrengthScore),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _LogActionsRow(),
                        ],
                      ),
                    ),
                    if (snapshot.hasData &&
                        snapshot.data!.aiInsights.any((i) => i.category == 'recovery'))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _RecoveryAiInsight(
                          insight: snapshot.data!.aiInsights.firstWhere(
                            (i) => i.category == 'recovery',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _OverallHero extends StatelessWidget {
  final PostpartumRecoverySnapshot snapshot;

  const _OverallHero({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return DashboardSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${snapshot.overallScore.round()}%',
                style: AppFontStyle.text_24_400(
                  fontFamily: AppFontFamily.gilroyBold,
                  color: AppColors.buttonClr1,
                ),
              ),
              const SizedBox(width: 8),
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
                    if (snapshot.weeklyDeltaPercent.abs() >= 1)
                      Text(
                        snapshot.weeklyDeltaPercent >= 0
                            ? '+${snapshot.weeklyDeltaPercent.round()}% this week'
                            : '${snapshot.weeklyDeltaPercent.round()}% this week',
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
          Row(
            children: [
              Expanded(
                child: _ScoreTile(
                  icon: Icons.healing_outlined,
                  label: 'Physical',
                  score: snapshot.physicalScore,
                  status: _statusLabel(snapshot.physicalScore),
                  color: _color(snapshot.physicalScore),
                ),
              ),
              Container(width: 1, height: 60, color: DashboardTheme.stroke),
              Expanded(
                child: _ScoreTile(
                  icon: Icons.opacity_outlined,
                  label: 'Uterine',
                  score: snapshot.uterineScore,
                  status: _statusLabel(snapshot.uterineScore),
                  color: _color(snapshot.uterineScore),
                ),
              ),
              Container(width: 1, height: 60, color: DashboardTheme.stroke),
              Expanded(
                child: _ScoreTile(
                  icon: Icons.bolt_outlined,
                  label: 'Energy',
                  score: snapshot.energyScore,
                  status: _statusLabel(snapshot.energyScore),
                  color: _color(snapshot.energyScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _LogActionsRow(),
        ],
      ),
    );
  }

  static String _statusLabel(double score) {
    if (score >= 80) return 'Strong';
    if (score >= 50) return 'Building';
    return 'Monitor';
  }

  static Color _color(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _LogActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.postpartumJournal),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note, size: 20, color: AppColors.buttonClr1),
                const SizedBox(width: 8),
                Text(
                  'Daily journal',
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.buttonClr1,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(width: 1, height: 24, color: DashboardTheme.stroke),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.postpartumRecoveryLogView),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assessment_outlined, size: 20, color: AppColors.buttonClr1),
                const SizedBox(width: 8),
                Text(
                  'Full assessment',
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: AppColors.buttonClr1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRecoveryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            color: DashboardTheme.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your recovery journey',
            style: AppFontStyle.text_14_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: DashboardTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track hydration, mood, sleep and symptoms daily to unlock your personalized Recovery Score™ and trend analytics.',
            style: AppFontStyle.text_12_400(
              fontFamily: AppFontFamily.gilroyRegular,
              color: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.postpartumJournal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonClr1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.postpartumRecoveryLogView),
              child: Text(
                'Full recovery assessment',
                style: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                  color: AppColors.buttonClr1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;
  final String status;
  final Color color;

  const _ScoreTile({
    required this.icon,
    required this.label,
    required this.score,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppFontStyle.text_12_400(
            fontFamily: AppFontFamily.gilroyMedium,
            color: DashboardTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.round()}%',
          style: AppFontStyle.text_18_400(
            fontFamily: AppFontFamily.gilroyBold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFontStyle.text_10_400(
              fontFamily: AppFontFamily.gilroySemiBold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryAiInsight extends StatelessWidget {
  final AIInsight insight;

  const _RecoveryAiInsight({required this.insight});

  @override
  Widget build(BuildContext context) {
    return DashboardSoftCard(
      color: DashboardTheme.accentRose.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: DashboardTheme.accentRose, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroySemiBold,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
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
}

class _RecoverySkeleton extends StatelessWidget {
  const _RecoverySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: DashboardTheme.cardDecoration(),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
