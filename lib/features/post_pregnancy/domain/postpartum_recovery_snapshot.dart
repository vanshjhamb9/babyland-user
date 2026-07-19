/// Immutable read model for the post-pregnancy dashboard.
class PostpartumRecoverySnapshot {
  final double overallScore;
  final double physicalScore;
  final double uterineScore;
  final double energyScore;
  final double taskCompletionPercent;
  final double weeklyDeltaPercent;
  final int recoveryStreakDays;
  final int logsThisWeek;
  final List<DailyRecoveryPoint> weeklyTrend;
  final List<RecoveryBreakdownMetric> breakdown;
  final List<RecoveryInsight> insights;
  final bool hasClinicalData;
  final bool hasAnyLogs;
  final DateTime computedAt;

  const PostpartumRecoverySnapshot({
    required this.overallScore,
    required this.physicalScore,
    required this.uterineScore,
    required this.energyScore,
    required this.taskCompletionPercent,
    required this.weeklyDeltaPercent,
    required this.recoveryStreakDays,
    required this.logsThisWeek,
    required this.weeklyTrend,
    required this.breakdown,
    required this.insights,
    required this.hasClinicalData,
    required this.hasAnyLogs,
    required this.computedAt,
  });

  static PostpartumRecoverySnapshot empty() {
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DailyRecoveryPoint(
        date: DateTime(d.year, d.month, d.day),
        score: 0,
        moodScore: 0,
        hydrationMl: 0,
      );
    });
    return PostpartumRecoverySnapshot(
      overallScore: 0,
      physicalScore: 0,
      uterineScore: 0,
      energyScore: 0,
      taskCompletionPercent: 0,
      weeklyDeltaPercent: 0,
      recoveryStreakDays: 0,
      logsThisWeek: 0,
      weeklyTrend: days,
      breakdown: const [],
      insights: const [],
      hasClinicalData: false,
      hasAnyLogs: false,
      computedAt: DateTime.now(),
    );
  }
}

class DailyRecoveryPoint {
  final DateTime date;
  final double score;
  final int moodScore;
  final int hydrationMl;

  const DailyRecoveryPoint({
    required this.date,
    required this.score,
    required this.moodScore,
    required this.hydrationMl,
  });
}

class RecoveryBreakdownMetric {
  final String label;
  final double value;
  final String unit;
  /// Semantic key for UI icons: hydration, mood, sleep, pain, feeding, activity, streak.
  final String iconKey;

  const RecoveryBreakdownMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.iconKey,
  });
}

class RecoveryInsight {
  final String title;
  final String body;
  final InsightTone tone;

  const RecoveryInsight({
    required this.title,
    required this.body,
    required this.tone,
  });
}

enum InsightTone { positive, neutral, attention }
