import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/post_pregnancy/data/postpartum_logs_merge.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';

/// Central postpartum recovery scoring, trends, and insight generation.
class PostpartumRecoveryEngine {
  static const int _hydrationGoalMl = 2000;

  /// Weighted overall recovery (0–100).
  static double computeOverallScore({
    required double physical,
    required double uterine,
    required double energy,
    required double hydrationConsistency,
    required double moodScore,
    required double sleepScore,
    required double symptomWellness,
    required double taskCompletion,
    required double logConsistency,
  }) {
    final clinical = (physical * 0.22) +
        (uterine * 0.12) +
        (energy * 0.18) +
        (hydrationConsistency * 0.12) +
        (moodScore * 0.12) +
        (sleepScore * 0.10) +
        (symptomWellness * 0.08) +
        (logConsistency * 0.06);
    final blended = (clinical * 0.88) + (taskCompletion * 0.12);
    return blended.clamp(0, 100);
  }

  static double scoreFromLog(Data? log) {
    if (log == null) return 0;
    final mood = moodScoreFromLog(log);
    final moodPct = mood > 0 ? (mood / 10.0) * 100.0 : 0.0;
    final sleepQ = (log.sleepQuality ?? 0).clamp(0, 5);
    final sleepPct = sleepQ > 0 ? (sleepQ / 5.0) * 100.0 : 0.0;
    final symptoms = log.symptoms?.length ?? 0;
    final symptomPct = (100 - symptoms * 12).clamp(0, 100).toDouble();
    final hydrationMl = log.hydration?.waterIntake ?? 0;
    final hydrationPct = hydrationMl > 0
        ? ((hydrationMl / _hydrationGoalMl) * 100).clamp(0, 100).toDouble()
        : 0.0;
    if (moodPct == 0 && sleepPct == 0 && hydrationPct == 0) return 0;
    return computeOverallScore(
      physical: moodPct * 0.85,
      uterine: sleepPct * 0.85,
      energy: sleepPct,
      hydrationConsistency: hydrationPct,
      moodScore: moodPct,
      sleepScore: sleepPct,
      symptomWellness: symptomPct,
      taskCompletion: 0,
      logConsistency: 100,
    );
  }

  static PostpartumRecoverySnapshot buildSnapshot({
    PostpartumRecoverySummary? serverRecovery,
    required List<Data> logs,
    required double taskCompletionPercent,
    required List<int> hydrationSeriesMl,
    required List<DateTime> trendDays,
    List<AIInsight> aiInsights = const [],
  }) {
    final now = DateTime.now();
    final byDay = <String, Data>{};
    for (final log in logs) {
      final parsed = TrackerMath.parseDateAny(log.date);
      if (parsed == null) continue;
      byDay[TrackerMath.dayKey(parsed)] = log;
    }

    double physical = serverRecovery?.physicalHealingScore ?? 0;
    double uterine = serverRecovery?.uterineRecoveryScore ?? 0;
    double energy = serverRecovery?.energyStrengthScore ?? 0;
    double overall = serverRecovery?.overallScore ?? 0;

    final todayKey = TrackerMath.dayKey(now);
    final todayLog = byDay[todayKey];
    final todayIdxEarly = trendDays.isNotEmpty ? trendDays.length - 1 : -1;
    final todayHydrationEarly = todayIdxEarly >= 0 && todayIdxEarly < hydrationSeriesMl.length
        ? hydrationSeriesMl[todayIdxEarly]
        : 0;
    var todayProxy = scoreFromLog(todayLog);
    if (todayProxy <= 0 && todayHydrationEarly > 0) {
      todayProxy = ((todayHydrationEarly / _hydrationGoalMl) * 55).clamp(8, 55).toDouble();
    }

    if (overall <= 0 && physical <= 0 && uterine <= 0 && energy <= 0) {
      if (todayProxy > 0) {
        physical = todayProxy * 0.9;
        uterine = todayProxy * 0.85;
        energy = todayProxy * 0.88;
        overall = todayProxy;
      }
    } else if (overall <= 0) {
      overall = (physical + uterine + energy) / 3.0;
    }

    final weeklyPoints = <DailyRecoveryPoint>[];
    for (var i = 0; i < trendDays.length; i++) {
      final d = trendDays[i];
      final log = byDay[TrackerMath.dayKey(d)];
      var dayScore = scoreFromLog(log);
      if (dayScore <= 0 && i < hydrationSeriesMl.length) {
        final h = hydrationSeriesMl[i];
        if (h > 0) dayScore = ((h / _hydrationGoalMl) * 40).clamp(5, 40).toDouble();
      }
      weeklyPoints.add(
        DailyRecoveryPoint(
          date: d,
          score: dayScore,
          moodScore: moodScoreFromLog(log),
          hydrationMl: log?.hydration?.waterIntake ?? hydrationSeriesMl[i],
        ),
      );
    }

    final loggedScores = weeklyPoints.where((p) => p.score > 0).map((p) => p.score).toList();
    final logsThisWeek = weeklyPoints
        .where((p) => p.score > 0 || p.hydrationMl > 0 || p.moodScore > 0)
        .length;
    final hasAnyLogs = logsThisWeek > 0 || todayLog != null || todayHydrationEarly > 0;

    double weeklyDelta = 0;
    if (loggedScores.length >= 2) {
      final mid = loggedScores.length ~/ 2;
      final firstHalf = loggedScores.sublist(0, mid);
      final secondHalf = loggedScores.sublist(mid);
      final avg1 = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final avg2 = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      weeklyDelta = avg2 - avg1;
    }

    final streak = _computeStreak(byDay, trendDays, hydrationSeriesMl, now);
    final todayIdx = trendDays.isNotEmpty ? trendDays.length - 1 : -1;
    final todayHydration = todayIdx >= 0 && todayIdx < hydrationSeriesMl.length
        ? hydrationSeriesMl[todayIdx]
        : 0;
    final moodToday = moodScoreFromLog(todayLog);
    final sleepToday = (todayLog?.sleepQuality ?? 0).clamp(0, 5);

    final hydrationConsistency = todayHydration > 0
        ? ((todayHydration / _hydrationGoalMl) * 100).clamp(0, 100).toDouble()
        : 0.0;
    final moodPct = moodToday > 0 ? (moodToday / 10.0) * 100.0 : 0.0;
    final sleepPct = sleepToday > 0 ? (sleepToday / 5.0) * 100.0 : 0.0;
    final symptomCount = todayLog?.symptoms?.length ?? 0;
    final symptomWellness = (100 - symptomCount * 15).clamp(0, 100).toDouble();
    final logConsistency = (logsThisWeek / 7.0 * 100).clamp(0, 100).toDouble();

    if (overall <= 0 && hasAnyLogs) {
      overall = computeOverallScore(
        physical: physical > 0 ? physical : todayProxy,
        uterine: uterine > 0 ? uterine : todayProxy * 0.9,
        energy: energy > 0 ? energy : todayProxy * 0.88,
        hydrationConsistency: hydrationConsistency,
        moodScore: moodPct,
        sleepScore: sleepPct,
        symptomWellness: symptomWellness,
        taskCompletion: taskCompletionPercent,
        logConsistency: logConsistency,
      );
    } else if (overall > 0) {
      overall = computeOverallScore(
        physical: physical,
        uterine: uterine,
        energy: energy,
        hydrationConsistency: hydrationConsistency > 0 ? hydrationConsistency : overall * 0.5,
        moodScore: moodPct > 0 ? moodPct : overall * 0.5,
        sleepScore: sleepPct > 0 ? sleepPct : overall * 0.5,
        symptomWellness: symptomWellness,
        taskCompletion: taskCompletionPercent,
        logConsistency: logConsistency,
      );
    }

    final breakdown = <RecoveryBreakdownMetric>[
      RecoveryBreakdownMetric(
        label: 'Physical',
        value: physical > 0 ? physical : todayProxy,
        unit: '%',
        iconKey: 'pain',
      ),
      RecoveryBreakdownMetric(
        label: 'Energy',
        value: energy > 0 ? energy : todayProxy * 0.9,
        unit: '%',
        iconKey: 'activity',
      ),
      RecoveryBreakdownMetric(
        label: 'Mood',
        value: moodToday > 0 ? moodToday.toDouble() : moodPct,
        unit: moodToday > 0 ? '/10' : '%',
        iconKey: 'mood',
      ),
      RecoveryBreakdownMetric(
        label: 'Hydration',
        value: hydrationConsistency,
        unit: '%',
        iconKey: 'hydration',
      ),
      RecoveryBreakdownMetric(
        label: 'Sleep',
        value: sleepPct,
        unit: '%',
        iconKey: 'sleep',
      ),
      RecoveryBreakdownMetric(
        label: 'Streak',
        value: streak.toDouble(),
        unit: 'days',
        iconKey: 'streak',
      ),
    ];

    final insights = _generateInsights(
      overall: overall,
      weeklyDelta: weeklyDelta,
      streak: streak,
      hydrationMl: todayHydration,
      moodToday: moodToday,
      logsThisWeek: logsThisWeek,
      aiInsights: aiInsights,
    );

    return PostpartumRecoverySnapshot(
      overallScore: overall,
      physicalScore: physical,
      uterineScore: uterine,
      energyScore: energy,
      taskCompletionPercent: taskCompletionPercent,
      weeklyDeltaPercent: weeklyDelta,
      recoveryStreakDays: streak,
      logsThisWeek: logsThisWeek,
      weeklyTrend: weeklyPoints,
      breakdown: breakdown,
      insights: insights,
      hasClinicalData: (serverRecovery != null &&
          (serverRecovery.physicalHealingScore > 0 ||
              serverRecovery.overallScore > 0)),
      hasAnyLogs: hasAnyLogs,
      computedAt: now,
    );
  }

  static int _computeStreak(
    Map<String, Data> byDay,
    List<DateTime> trendDays,
    List<int> hydrationSeriesMl,
    DateTime now,
  ) {
    var streak = 0;
    var cursor = TrackerMath.dateOnly(now);
    while (true) {
      final key = TrackerMath.dayKey(cursor);
      final hasLog = byDay.containsKey(key);
      final dayIdx = trendDays.indexWhere((d) => TrackerMath.dayKey(d) == key);
      final hasHydration = dayIdx >= 0 &&
          dayIdx < hydrationSeriesMl.length &&
          hydrationSeriesMl[dayIdx] > 0;
      if (hasLog || hasHydration) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static List<RecoveryInsight> _generateInsights({
    required double overall,
    required double weeklyDelta,
    required int streak,
    required int hydrationMl,
    required int moodToday,
    required int logsThisWeek,
    required List<AIInsight> aiInsights,
  }) {
    final out = <RecoveryInsight>[];

    for (final ai in aiInsights.where((i) => i.category == 'recovery').take(2)) {
      out.add(
        RecoveryInsight(
          title: ai.title,
          body: ai.description,
          tone: InsightTone.neutral,
        ),
      );
    }

    if (overall <= 0 && logsThisWeek == 0) {
      out.add(
        const RecoveryInsight(
          title: 'Start your recovery journey',
          body:
              'Track hydration, mood, sleep and symptoms daily to unlock personalized recovery analytics.',
          tone: InsightTone.neutral,
        ),
      );
      return out;
    }

    if (weeklyDelta >= 5) {
      out.add(
        RecoveryInsight(
          title: 'Strong weekly momentum',
          body:
              'You are recovering faster this week (+${weeklyDelta.round()}% trend). Keep up your daily logs.',
          tone: InsightTone.positive,
        ),
      );
    } else if (weeklyDelta <= -5) {
      out.add(
        RecoveryInsight(
          title: 'Recovery needs attention',
          body:
              'Your trend dipped ${weeklyDelta.abs().round()}% this week. Consider resting more and logging symptoms.',
          tone: InsightTone.attention,
        ),
      );
    }

    if (streak >= 3) {
      out.add(
        RecoveryInsight(
          title: '$streak-day recovery streak',
          body: 'Consistent logging helps your care team and IRA give better guidance.',
          tone: InsightTone.positive,
        ),
      );
    }

    if (hydrationMl >= _hydrationGoalMl) {
      out.add(
        const RecoveryInsight(
          title: 'Hydration on track',
          body: 'Great water intake today — hydration supports healing and energy.',
          tone: InsightTone.positive,
        ),
      );
    } else if (hydrationMl > 0 && hydrationMl < _hydrationGoalMl ~/ 2) {
      out.add(
        const RecoveryInsight(
          title: 'Hydration opportunity',
          body: 'Increasing water intake may support your physical recovery this week.',
          tone: InsightTone.attention,
        ),
      );
    }

    if (moodToday > 0 && moodToday <= 4) {
      out.add(
        const RecoveryInsight(
          title: 'Emotional wellness check-in',
          body: 'Your mood trend suggests extra rest or support may help — you are not alone.',
          tone: InsightTone.attention,
        ),
      );
    } else if (moodToday >= 8) {
      out.add(
        const RecoveryInsight(
          title: 'Mood stable',
          body: 'Your emotional wellness looks steady today. Keep nurturing yourself.',
          tone: InsightTone.positive,
        ),
      );
    }

    if (out.isEmpty && overall > 0) {
      out.add(
        RecoveryInsight(
          title: 'Recovery score ${overall.round()}%',
          body: 'Continue daily logs to refine your personalized recovery insights.',
          tone: InsightTone.neutral,
        ),
      );
    }

    return out.take(4).toList();
  }
}
