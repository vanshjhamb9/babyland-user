import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/post_pregnancy/charts/recovery_trend_chart.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/post_pregnancy/widgets/recovery_insight_cards.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class _PostpartumRecoveryAnalyticsSheetBody extends StatelessWidget {
  final ScrollController scrollController;
  final PostpartumRecoverySnapshot snapshot;
  final PostpregnancyProvider taskProvider;
  final String? userId;

  const _PostpartumRecoveryAnalyticsSheetBody({
    required this.scrollController,
    required this.snapshot,
    required this.taskProvider,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PostpregnancyProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            color: DashboardTheme.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: _sheetChildren(context, provider),
          ),
        );
      },
    );
  }

  List<Widget> _sheetChildren(BuildContext context, PostpregnancyProvider provider) {
    return [
      Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DashboardTheme.stroke,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recovery Analytics',
            style: AppFontStyle.text_18_400(
              fontFamily: AppFontFamily.gilroySemiBold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      Text(
        'Personalized from your daily logs, hydration, mood & recovery tasks',
        style: AppFontStyle.text_12_400(
          fontFamily: AppFontFamily.gilroyRegular,
          color: DashboardTheme.textSecondary,
        ),
      ),
      const SizedBox(height: 20),
      _SummaryRow(snapshot: snapshot),
      const SizedBox(height: 16),
      RecoveryTrendChart(points: snapshot.weeklyTrend),
      const SizedBox(height: 16),
      _PillarRow(snapshot: snapshot),
      const SizedBox(height: 16),
      Text(
        'Insights',
        style: AppFontStyle.text_15_400(
          fontFamily: AppFontFamily.gilroySemiBold,
        ),
      ),
      const SizedBox(height: 8),
      RecoveryInsightCards(insights: snapshot.insights),
      const SizedBox(height: 16),
      Text(
        'Daily recovery actions',
        style: AppFontStyle.text_15_400(
          fontFamily: AppFontFamily.gilroySemiBold,
        ),
      ),
      const SizedBox(height: 8),
      ...List.generate(
        provider.getRecoveryApiData?.data?.tasks?.tasks?.length ?? 0,
        (index) {
          final tasks = provider.getRecoveryApiData?.data?.tasks?.tasks?[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _recoveryCheckboxTile(
              title: capitalizeFirstLetter(tasks?.task ?? ''),
              subtitle: DateFormat('yyyy-MM-dd').format(
                DateTime.tryParse(tasks?.dateAssigned ?? '') ?? DateTime.now(),
              ),
              value: (tasks?.completed ?? false)
                  ? true
                  : provider.selectedIndexes.contains(index),
              onChanged: (val) async {
                if (tasks?.completed == false && val == true) {
                  provider.toggleRecoveryIndex(index);
                  await provider.recoveryTaskApi(
                    completed: true,
                    id: userId,
                    dateAssigned: tasks?.dateAssigned ?? '',
                    dateCompleted: tasks?.dateCompleted ?? '',
                    dueDate: tasks?.dueDate ?? '',
                    task: tasks?.task ?? '',
                  );
                }
              },
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.postpartumRecoveryLogView);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonClr1,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            'Full recovery assessment',
            style: AppFontStyle.text_14_400(
              fontFamily: AppFontFamily.gilroyBold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    ];
  }
}

/// Full recovery analytics bottom sheet with trend chart, insights, and tasks.
class PostpartumRecoveryAnalyticsSheet {
  PostpartumRecoveryAnalyticsSheet._();

  static Future<void> show(
    BuildContext context, {
    required PostpartumRecoverySnapshot snapshot,
    required PostpregnancyProvider taskProvider,
    String? userId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => _PostpartumRecoveryAnalyticsSheetBody(
          scrollController: scrollController,
          snapshot: snapshot,
          taskProvider: taskProvider,
          userId: userId,
        ),
      ),
    );
  }
}

Widget _recoveryCheckboxTile({
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool?> onChanged,
}) {
  return AppContainer(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    radius: 8,
    color: AppColors.white,
    isBordered: true,
    child: Row(
      children: [
        GradientCheckbox(value: value, onChanged: onChanged, size: 28),
        SBox(w: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFontStyle.text_14_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
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
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final PostpartumRecoverySnapshot snapshot;

  const _SummaryRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DashboardTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${snapshot.overallScore.round()}%',
                style: AppFontStyle.text_32_400(
                  fontFamily: AppFontFamily.gilroyBold,
                  color: AppColors.buttonClr1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.weeklyDeltaPercent >= 0
                      ? '+${snapshot.weeklyDeltaPercent.round()}% vs earlier this week'
                      : '${snapshot.weeklyDeltaPercent.round()}% vs earlier this week',
                  style: AppFontStyle.text_12_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                    color: DashboardTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GradientProgressBar(
            progress: snapshot.overallScore.clamp(0, 100),
            height: 8,
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  final PostpartumRecoverySnapshot snapshot;

  const _PillarRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pillar('Physical', snapshot.physicalScore, Icons.healing_outlined),
        const SizedBox(width: 8),
        _pillar('Uterine', snapshot.uterineScore, Icons.opacity_outlined),
        const SizedBox(width: 8),
        _pillar('Energy', snapshot.energyScore, Icons.bolt_outlined),
      ],
    );
  }

  Widget _pillar(String label, double score, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: DashboardTheme.cardDecoration(),
        child: Column(
          children: [
            Icon(icon, size: 20, color: DashboardTheme.accentRose),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppFontStyle.text_11_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: DashboardTheme.textSecondary,
              ),
            ),
            Text(
              '${score.round()}%',
              style: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
