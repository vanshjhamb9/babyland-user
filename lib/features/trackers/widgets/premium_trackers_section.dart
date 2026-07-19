import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:provider/provider.dart';

import 'package:babyland/core/error/error_handler.dart';
import 'package:babyland/core/theme/premium_app_theme.dart';
import '../utils/tracker_math.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/post_pregnancy/data/postpartum_logs_merge.dart';
import 'package:babyland/features/post_pregnancy/state/postpartum_dashboard_notifier.dart';
import 'postpartum_recovery_dashboard.dart';

import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';

/// Adds premium Hydration + Mental Health cards and "Your Trends" charts
/// *below existing dashboard content* in each stage.
class PremiumTrackersSection extends StatefulWidget {
  final TrackerStageType stageType;

  /// When set (e.g. from [PregnancyHomeView]), avoids duplicate dashboard API calls.
  final Future<DashboardData>? sharedDashboardFuture;

  /// Pre-computed postpartum recovery analytics for Recovery Score™ UI.
  final PostpartumRecoverySnapshot? recoverySnapshot;

  /// Increment after mood/hydration/log saves to reload charts.
  final int refreshToken;

  const PremiumTrackersSection({
    super.key,
    required this.stageType,
    this.sharedDashboardFuture,
    this.recoverySnapshot,
    this.refreshToken = 0,
  });

  @override
  State<PremiumTrackersSection> createState() =>
      _PremiumTrackersSectionState();
}

class _PremiumTrackersSectionState extends State<PremiumTrackersSection> {
  Future<HydrationTrendData>? _hydrationTrendFuture;
  Future<MentalTrendData>? _mentalTrendFuture;
  Future<DashboardData>? _dashboardFuture;
  Future<int>? _todayMentalScoreFuture;

  static int _moodScoreFromLog(Data? log) => moodScoreFromLog(log);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    setState(() {
      _hydrationTrendFuture = _loadHydrationTrend();
      _mentalTrendFuture = _loadMentalTrend();
      _dashboardFuture = widget.sharedDashboardFuture ?? sl.dashboardService.refresh();
      _todayMentalScoreFuture = _loadTodayMentalScore();
    });
  }

  Future<int> _loadTodayMentalScore() async {
    // For post-stage, we call API. For pre/pregnancy, we read from provider.
    if (widget.stageType == TrackerStageType.post) {
      try {
        final repo = context.read<Repository>();
        final now = DateTime.now();
        final apiDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, now.day));
        final res = await repo.getPostpartumLogs(params: {'date': apiDate});
        final first = res.data?.isNotEmpty == true ? res.data!.first : null;
        return _moodScoreFromLog(first);
      } catch (_) {
        return 0;
      }
    } else if (widget.stageType == TrackerStageType.pre) {
      final provider = context.read<CycleCalenderProvider>();
      final mood = provider.dashboardMoodApiData?.data?.data?.mood ?? '';
      return TrackerMath.moodToScore(mood);
    } else {
      final provider = context.read<PregnancyController>();
      final mood = provider.pregnancyApiData?.data?.data?.data?.mood ?? '';
      return TrackerMath.moodToScore(mood);
    }
  }

  @override
  void didUpdateWidget(covariant PremiumTrackersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stageType != widget.stageType ||
        oldWidget.refreshToken != widget.refreshToken) {
      _loadAllData();
    }
  }

  int _lastDashboardGeneration = -1;

  Future<HydrationTrendData> _loadHydrationTrend() async {
    try {
      final now = DateTime.now();
      final days = TrackerMath.lastNDays(now, count: 7);
      final from = days.first;
      final to = days.last.add(const Duration(hours: 23, minutes: 59));

      final resp = await sl.healthTrackerService.getHydrationLogs(
        from: from,
        to: to,
        page: 1,
        limit: 200,
      );

      // Group amount by day.
      final map = <String, int>{};
      for (final log in resp.data) {
        final d = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final key = TrackerMath.dayKey(d);
        map[key] = (map[key] ?? 0) + log.amountMl;
      }

      final series = days.map((d) => map[TrackerMath.dayKey(d)] ?? 0).toList();

      return HydrationTrendData(days: days, seriesMl: series);
    } catch (e) {
      ErrorHandler.logError(e);
      return HydrationTrendData(days: TrackerMath.lastNDays(DateTime.now()), seriesMl: List.filled(7, 0));
    }
  }

  Future<MentalTrendData> _loadMentalTrend() async {
    final now = DateTime.now();
    final days = TrackerMath.lastNDays(now, count: 7);

    try {
      switch (widget.stageType) {
        case TrackerStageType.pre:
          return await _loadPreMentalTrend(days);
        case TrackerStageType.pregnancy:
          return await _loadPregnancyMentalTrend(days);
        case TrackerStageType.post:
          return await _loadPostMentalTrend(days);
      }
    } catch (e) {
      ErrorHandler.logError(e);
      return MentalTrendData(
        days: days,
        seriesScore: List.filled(7, 0),
      );
    }
  }

  Future<MentalTrendData> _loadPreMentalTrend(List<DateTime> days) async {
    final repo = context.read<Repository>();

    // Existing endpoint expects date as `dd-MM-yyyy` in query.
    // We'll call once per day (7 calls).
    final futures = days.map((d) async {
      final ddMmYyyy = TrackerMath.formatDdMmYyyy(d);
      final apiDate = _formatDdMmYyyyToApi(ddMmYyyy);
      final resp = await repo.getMenstrualLogs(params: {'date': apiDate});

      final first = resp.data?.isNotEmpty == true ? resp.data!.first : null;
      return _moodScoreFromLog(first);
    }).toList();

    final scores = await Future.wait<int>(futures);
    return MentalTrendData(days: days, seriesScore: scores);
  }

  Future<MentalTrendData> _loadPregnancyMentalTrend(List<DateTime> days) async {
    final repo = context.read<Repository>();
    final provider = context.read<PregnancyController>();
    final scores = await _fetchDailyMoodScores(
      days,
      (date) => repo.getPregnancyLogs(params: {'date': date}),
    );
    if (scores.any((s) => s > 0)) {
      return MentalTrendData(days: days, seriesScore: scores);
    }

    // Fallback: in-memory tracker logs on pregnancy home.
    final dailyLogs =
        provider.pregnancyApiData?.data?.data?.data?.tracker?.dailyLogs ?? [];
    final byDate = <String, int>{};
    for (final log in dailyLogs) {
      final parsed = TrackerMath.parseDateAny(log.date);
      if (parsed == null) continue;
      byDate[TrackerMath.dayKey(parsed)] = TrackerMath.moodToScore(log.mood);
    }
    final series = days.map((d) => byDate[TrackerMath.dayKey(d)] ?? 0).toList();
    return MentalTrendData(days: days, seriesScore: series);
  }

  Future<MentalTrendData> _loadPostMentalTrend(List<DateTime> days) async {
    try {
      final repo = context.read<Repository>();
      final scores = await _fetchDailyMoodScores(
        days,
        (date) => repo.getPostpartumLogs(params: {'date': date}),
        tryAlternateDateFormat: true,
      );
      if (scores.any((s) => s > 0)) {
        return MentalTrendData(days: days, seriesScore: scores);
      }

      final res = await repo.getPostpartumLogs();
      final byDate = <String, int>{};
      for (final log in res.data ?? []) {
        final parsed = TrackerMath.parseDateAny(log.date);
        if (parsed == null) continue;
        byDate[TrackerMath.dayKey(parsed)] = TrackerMath.moodToScore(log.mood);
      }
      final series = days.map((d) => byDate[TrackerMath.dayKey(d)] ?? 0).toList();
      if (series.any((s) => s > 0)) {
        return MentalTrendData(days: days, seriesScore: series);
      }
    } catch (_) {
      // Fallback to Hive if backend is unavailable
    }

    final raw = UserPreference.getPostMentalHealthLogs();
    final byDate = <String, int>{};
    for (final e in raw) {
      if (e['date'] == null) continue;
      final parsed = TrackerMath.parseDateAny(e['date'].toString());
      if (parsed == null) continue;
      final scoreRaw = e['score'];
      final score = scoreRaw is num
          ? scoreRaw.toInt()
          : int.tryParse(scoreRaw?.toString() ?? '') ?? 0;
      byDate[TrackerMath.dayKey(parsed)] = score;
    }

    final series = days.map((d) => byDate[TrackerMath.dayKey(d)] ?? 0).toList();
    return MentalTrendData(days: days, seriesScore: series);
  }

  Future<List<int>> _fetchDailyMoodScores(
    List<DateTime> days,
    Future<MenstrualLogsListModel> Function(String apiDate) fetcher, {
    bool tryAlternateDateFormat = false,
  }) async {
    final futures = days.map((d) async {
      final isoDate = DateFormat('yyyy-MM-dd').format(d);
      final legacyDate = DateFormat('dd-MM-yyyy').format(d);
      try {
        var res = await fetcher(isoDate);
        var first = res.data?.isNotEmpty == true ? res.data!.first : null;
        var score = _moodScoreFromLog(first);
        if (score <= 0 && tryAlternateDateFormat) {
          res = await fetcher(legacyDate);
          first = res.data?.isNotEmpty == true ? res.data!.first : null;
          score = _moodScoreFromLog(first);
        }
        return score;
      } catch (_) {
        return 0;
      }
    });
    return Future.wait(futures);
  }

  String _formatDdMmYyyyToApi(String ddMmYyyy) {
    try {
      final inputFormat = DateFormat('dd-MM-yyyy');
      final outputFormat = DateFormat('yyyy-MM-dd');
      final parsedDate = inputFormat.parse(ddMmYyyy);
      return outputFormat.format(parsedDate);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stageType == TrackerStageType.post) {
      final gen = context.watch<PostpartumDashboardNotifier>().dataGeneration;
      if (gen != _lastDashboardGeneration) {
        _lastDashboardGeneration = gen;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadAllData();
        });
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Column(
            key: const ValueKey<String>('premium_blocks_v2'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.stageType == TrackerStageType.post) ...[
                PostpartumRecoveryDashboard(
                  dashboardFuture: _dashboardFuture,
                  recoverySnapshot: widget.recoverySnapshot,
                ),
                const SizedBox(height: 16),
              ],
              _buildHydrationBlock(context),
              const SizedBox(height: 16),
              _buildMentalBlock(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHydrationBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumHydrationCard(
            dashboardFuture: _dashboardFuture,
            onAddWater: () async {
              final ok = await Navigator.pushNamed(
                context,
                AppRoutes.addHydrationView,
                arguments: {'stage': widget.stageType.name},
              );
              if (ok == true && mounted) {
                _loadAllData();
                if (widget.stageType == TrackerStageType.post) {
                  await _refreshPostpartumDashboard(context);
                }
              }
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<HydrationTrendData>(
            future: _hydrationTrendFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _chartShimmer(height: 210);
              }
              if (!snapshot.hasData || (snapshot.data?.seriesMl.isEmpty ?? true)) {
                return _emptyChart(
                  title: 'Water intake (last 7 days, litres)',
                  subtitle: 'No hydration trend yet — start tracking your water intake 💧',
                );
              }
              return PremiumHydrationTrendChart(data: snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMentalBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumMentalHealthCard(
            stageType: widget.stageType,
            scoreFuture: _todayMentalScoreFuture,
            onLogMood: () async {
              final ok = await Navigator.pushNamed(
                context,
                AppRoutes.addMentalHealthView,
                arguments: {'stage': widget.stageType.name},
              );
              if (ok == true && mounted) {
                _loadAllData();
                if (widget.stageType == TrackerStageType.post) {
                  await _refreshPostpartumDashboard(context);
                }
              }
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<MentalTrendData>(
            future: _mentalTrendFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _chartShimmer(height: 210);
              }
              if (!snapshot.hasData) {
                return _emptyChart(
                  title: 'Mood & wellbeing (last 7 days)',
                  subtitle: 'Could not load mood history. Pull to refresh.',
                );
              }
              return PremiumMentalHealthTrendChart(
                data: snapshot.data!,
                stageType: widget.stageType,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chartShimmer({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _emptyChart({required String title, required String subtitle}) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStylesPremium.body(
              color: AppColorsPremium.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStylesPremium.caption(
              color: AppColorsPremium.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _refreshPostpartumDashboard(BuildContext context) async {
  try {
    final pp = context.read<PostpregnancyProvider>();
    await pp.getDashboardLogsApi();
    await context.read<PostpartumDashboardNotifier>().refresh(
      recoveryTask: pp.getRecoveryApiData?.data,
      dashboardLogs: pp.dashboardLogsApiData?.data,
      force: true,
    );
  } catch (_) {}
}

class HydrationTrendData {
  final List<DateTime> days;
  final List<int> seriesMl;

  HydrationTrendData({
    required this.days,
    required this.seriesMl,
  });
}

class MentalTrendData {
  final List<DateTime> days;
  final List<int> seriesScore; // 1-10

  MentalTrendData({
    required this.days,
    required this.seriesScore,
  });
}

class DailyLogScore {
  final int score;
  DailyLogScore({required this.score});
}

class PremiumHydrationCard extends StatelessWidget {
  final Future<DashboardData>? dashboardFuture;
  final VoidCallback onAddWater;

  const PremiumHydrationCard({
    super.key,
    this.dashboardFuture,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
        future: dashboardFuture ?? sl.dashboardService.getDashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final summary = data?.healthSummary.hydration;

          if (snapshot.connectionState == ConnectionState.waiting || summary == null) {
            return _hydrationSkeleton();
          }

          if (summary.today <= 0) {
            return _emptyHydrationCard(onAddWater: onAddWater);
          }

          final ratio = summary.goal <= 0 ? 0.0 : (summary.today / summary.goal).clamp(0.0, 1.0);

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColorsPremium.hydrationGradient,
              borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              boxShadow: [AppShadowPremium.softShadow()],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Hydration',
                          style: AppTextStylesPremium.h2(color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      summary.trend,
                      style: AppTextStylesPremium.caption(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0, end: ratio),
                    builder: (context, value, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 112,
                            width: 112,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 9,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${summary.today} ml',
                                style: AppTextStylesPremium.h3(color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'of ${summary.goal} ml',
                                style: AppTextStylesPremium.caption(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                _PremiumScaleButton(
                  text: '+ Add Water',
                  onTap: onAddWater,
                ),
              ],
            ),
          );
        },
    );
  }

  Widget _hydrationSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColorsPremium.hydrationGradient,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
    );
  }

  Widget _emptyHydrationCard({required VoidCallback onAddWater}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColorsPremium.hydrationGradient,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Colors.white.withValues(alpha: 0.95), size: 26),
              const SizedBox(width: 10),
              Text(
                'Hydration',
                style: AppTextStylesPremium.h2(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Start tracking your water intake 💧',
            style: AppTextStylesPremium.body(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 14),
          _PremiumScaleButton(
            text: '+ Add Water',
            onTap: onAddWater,
          ),
        ],
      ),
    );
  }
}

class PremiumMentalHealthCard extends StatelessWidget {
  final TrackerStageType stageType;
  final Future<int>? scoreFuture;
  final VoidCallback onLogMood;

  const PremiumMentalHealthCard({
    super.key,
    required this.stageType,
    this.scoreFuture,
    required this.onLogMood,
  });

  int _scoreFromMood(String? mood) => TrackerMath.moodToScore(mood);

  String _emojiFromScore(int score) => TrackerMath.scoreToEmoji(score);

  @override
  Widget build(BuildContext context) {
    // For pre + pregnancy, we can read from providers synchronously.
    int immediateScore = 0;
    String mood = '';
    if (stageType == TrackerStageType.pre) {
      final provider = context.read<CycleCalenderProvider>();
      mood = provider.dashboardMoodApiData?.data?.data?.mood ?? '';
      immediateScore = _scoreFromMood(mood);
    } else if (stageType == TrackerStageType.pregnancy) {
      final provider = context.read<PregnancyController>();
      mood = provider.pregnancyApiData?.data?.data?.data?.mood ?? '';
      immediateScore = _scoreFromMood(mood);
    }

    return FutureBuilder<int>(
        future: scoreFuture ?? Future.value(immediateScore),
        builder: (context, snapshot) {
          final score = snapshot.data ?? 0;
          if (!snapshot.hasData && stageType == TrackerStageType.post) {
            return _mentalSkeleton();
          }

          if (score <= 0) {
            return _emptyMentalCard(onLogMood: onLogMood);
          }

          final emoji = _emojiFromScore(score);
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColorsPremium.mentalGradient,
              borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              boxShadow: [AppShadowPremium.softShadow()],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_alt_rounded, color: Colors.white.withValues(alpha: 0.95), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Mental Health',
                          style: AppTextStylesPremium.h2(color: Colors.white),
                        ),
                      ],
                    ),
                    Text(
                      '${score.clamp(1, 10)}/10',
                      style: AppTextStylesPremium.caption(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 900),
                        tween: Tween<double>(begin: 0.95, end: 1.02),
                        curve: Curves.easeInOut,
                        builder: (context, v, _) {
                          return Transform.scale(
                            scale: v,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Feeling ${TrackerMath.scoreToMood(score)}',
                        style: AppTextStylesPremium.body(color: Colors.white, ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score/10',
                        style: AppTextStylesPremium.h2(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PremiumBounceScaleButton(
                  text: '+ Log Mood',
                  onTap: onLogMood,
                ),
              ],
            ),
          );
        },
    );
  }

  Widget _mentalSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColorsPremium.mentalGradient,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
    );
  }

  Widget _emptyMentalCard({required VoidCallback onLogMood}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColorsPremium.mentalGradient,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: Colors.white.withValues(alpha: 0.95), size: 26),
              const SizedBox(width: 10),
              Text(
                'Mental Health',
                style: AppTextStylesPremium.h2(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Log your mood to see insights 🧠',
            style: AppTextStylesPremium.body(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 14),
          _PremiumBounceScaleButton(
            text: '+ Log Mood',
            onTap: onLogMood,
          ),
        ],
      ),
    );
  }
}

class PremiumHydrationTrendChart extends StatelessWidget {
  final HydrationTrendData data;
  const PremiumHydrationTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final seriesL = data.seriesMl.map((ml) => ml / 1000.0).toList();
    final maxY = max(0.25, seriesL.reduce(max));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 0.35)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water intake (last 7 days)',
            style: AppTextStylesPremium.h3(color: AppColorsPremium.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Daily total · litres (L) · bar chart',
            style: AppTextStylesPremium.caption(color: AppColorsPremium.textSecondary),
          ),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final idx = group.x.toInt();
                      final day = idx >= 0 && idx < data.days.length
                          ? DateFormat('dd MMM').format(data.days[idx])
                          : '';
                      return BarTooltipItem(
                        '$day\n${rod.toY.toStringAsFixed(2)} L',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.days.length) return const SizedBox.shrink();
                        final label = TrackerMath.chartDayLabel(DateTime.now(), data.days[idx]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: AppTextStylesPremium.caption(color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: AppTextStylesPremium.caption(color: Colors.grey.shade600),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(seriesL.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: seriesL[i],
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF3D7AB0),
                            Color(0xFF5EB3E8),
                            Color(0xFF9AD4F2),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumMentalHealthTrendChart extends StatelessWidget {
  final MentalTrendData data;
  final TrackerStageType stageType;

  const PremiumMentalHealthTrendChart({
    super.key,
    required this.data,
    required this.stageType,
  });

  static Color _barColorForScore(int score) {
    if (score <= 0) return const Color(0xFFE8E4EF);
    if (score >= 8) return const Color(0xFF7E57C2);
    if (score >= 5) return const Color(0xFFB085D6);
    return const Color(0xFFFF8FA8);
  }

  static List<Color> _barGradientForScore(int score) {
    if (score <= 0) {
      return [const Color(0xFFECE8F4), const Color(0xFFE0DAEA)];
    }
    if (score >= 8) {
      return [const Color(0xFF6A4FB8), const Color(0xFF9B7AD4), const Color(0xFFC9A8E8)];
    }
    if (score >= 5) {
      return [const Color(0xFF8E6BB8), const Color(0xFFB895D8), const Color(0xFFE8B4D4)];
    }
    return [const Color(0xFFB07AA8), const Color(0xFFD49AB8), const Color(0xFFFFA8B8)];
  }

  @override
  Widget build(BuildContext context) {
    final scores = data.seriesScore;
    final logged = scores.where((s) => s > 0).toList();
    final hasData = logged.isNotEmpty;
    final avg = hasData
        ? logged.reduce((a, b) => a + b) / logged.length
        : 0.0;
    final maxScore = hasData ? logged.reduce(max) : 0;
    final chartMaxY = (max(maxScore + 1.0, 6.0)).clamp(6.0, 10.0);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadiusPremium.cards),
        border: Border.all(color: const Color(0xFFE8E0F5)),
        boxShadow: [AppShadowPremium.softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood & wellbeing',
                      style: AppTextStylesPremium.h3(
                        color: AppColorsPremium.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last 7 days · daily score out of 10',
                      style: AppTextStylesPremium.caption(
                        color: AppColorsPremium.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8E0F5)),
                  ),
                  child: Text(
                    'Avg ${avg.toStringAsFixed(1)}/10',
                    style: AppTextStylesPremium.caption(
                      color: const Color(0xFF7E57C2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE8F4)),
              ),
              child: Column(
                children: [
                  Text(
                    TrackerMath.moodToEmoji('okay'),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No mood logs yet this week',
                    style: AppTextStylesPremium.body(
                      color: AppColorsPremium.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Log your mood daily to see your trend here',
                    textAlign: TextAlign.center,
                    style: AppTextStylesPremium.caption(
                      color: AppColorsPremium.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 2,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFEDE8F4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF2D2640),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x.toInt();
                        if (idx < 0 || idx >= data.days.length) {
                          return null;
                        }
                        final day = data.days[idx];
                        final score = scores[idx];
                        final dateLabel = DateFormat('EEE, d MMM').format(day);
                        if (score <= 0) {
                          return BarTooltipItem(
                            '$dateLabel\nNo log',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return BarTooltipItem(
                          '$dateLabel\n$score/10 · ${TrackerMath.scoreToMood(score)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= scores.length) {
                            return const SizedBox.shrink();
                          }
                          final score = scores[idx];
                          if (score <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$score',
                              style: AppTextStylesPremium.caption(
                                color: const Color(0xFF7E57C2),
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.days.length) {
                            return const SizedBox.shrink();
                          }
                          final day = data.days[idx];
                          final isToday = TrackerMath.dateOnly(day) ==
                              TrackerMath.dateOnly(today);
                          final rel = TrackerMath.chartDayLabel(today, day);
                          final score = scores[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (score > 0)
                                  Text(
                                    TrackerMath.moodToEmoji(
                                      TrackerMath.scoreToMood(score),
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                Text(
                                  isToday ? 'Today' : rel,
                                  style: AppTextStylesPremium.caption(
                                    color: isToday
                                        ? const Color(0xFF7E57C2)
                                        : Colors.grey.shade600,
                                  ).copyWith(
                                    fontWeight: isToday
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: chartMaxY / 2,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStylesPremium.caption(
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(scores.length, (i) {
                    final score = scores[i];
                    final displayY = score > 0 ? score.toDouble() : 0.35;
                    final isToday = TrackerMath.dateOnly(data.days[i]) ==
                        TrackerMath.dateOnly(today);
                    final colors = _barGradientForScore(score);
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: displayY,
                          width: isToday ? 18 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: colors,
                          ),
                          borderSide: isToday
                              ? const BorderSide(
                                  color: Color(0xFF7E57C2),
                                  width: 1.5,
                                )
                              : BorderSide.none,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          if (hasData) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(color: _barColorForScore(8), label: 'Great'),
                const SizedBox(width: 12),
                _LegendDot(color: _barColorForScore(6), label: 'Okay'),
                const SizedBox(width: 12),
                _LegendDot(color: _barColorForScore(3), label: 'Low'),
                const SizedBox(width: 12),
                _LegendDot(color: _barColorForScore(0), label: 'No log'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStylesPremium.caption(color: AppColorsPremium.textSecondary),
        ),
      ],
    );
  }
}

class _PremiumScaleButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _PremiumScaleButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_PremiumScaleButton> createState() => _PremiumScaleButtonState();
}

class _PremiumScaleButtonState extends State<_PremiumScaleButton> {
  double _pressed = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = 0.97),
      onTapCancel: () => setState(() => _pressed = 1.0),
      child: AnimatedScale(
        scale: _pressed,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: AppTextStylesPremium.body(
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBounceScaleButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _PremiumBounceScaleButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_PremiumBounceScaleButton> createState() =>
      _PremiumBounceScaleButtonState();
}

class _PremiumBounceScaleButtonState extends State<_PremiumBounceScaleButton> {
  bool _anim = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        setState(() => _anim = true);
      },
      onTapCancel: () {
        setState(() => _anim = false);
      },
      child: AnimatedScale(
        scale: _anim ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: AppTextStylesPremium.body(
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

