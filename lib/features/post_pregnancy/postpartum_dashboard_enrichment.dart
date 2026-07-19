import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';

/// Fills postpartum recovery gaps when `/health-insights` returns empty scores.
Future<DashboardData> enrichPostpartumDashboard(
  Future<DashboardData> baseFuture, {
  List<Data>? logs,
  int hydrationTodayMl = 0,
}) async {
  final base = await baseFuture;
  var recovery = base.healthSummary.postpartumRecovery;
  final hasScores = recovery != null &&
      (recovery.overallScore > 0 ||
          recovery.physicalHealingScore > 0 ||
          recovery.energyStrengthScore > 0);

  if (hasScores) return base;

  final logList = logs ?? [];
  Data? todayLog;
  final now = DateTime.now();
  final todayKey = TrackerMath.dayKey(now);
  for (final log in logList) {
    final parsed = TrackerMath.parseDateAny(log.date);
    if (parsed == null) continue;
    if (TrackerMath.dayKey(parsed) == todayKey) {
      todayLog = log;
      break;
    }
  }

  final mood = TrackerMath.moodToScore(todayLog?.mood);
  final sleepQ = (todayLog?.sleepQuality ?? 0).clamp(0, 5);
  final moodPct = mood > 0 ? (mood / 10.0) * 100.0 : 0.0;
  final sleepPct = sleepQ > 0 ? (sleepQ / 5.0) * 100.0 : 0.0;
  final hydrationPct = hydrationTodayMl > 0
      ? ((hydrationTodayMl / 2000.0) * 100).clamp(0, 100).toDouble()
      : 0.0;

  if (moodPct <= 0 && sleepPct <= 0 && hydrationPct <= 0) return base;

  final proxy = (moodPct * 0.4 + sleepPct * 0.35 + hydrationPct * 0.25);
  recovery = PostpartumRecoverySummary(
    physicalHealingScore: proxy * 0.95,
    uterineRecoveryScore: sleepPct > 0 ? sleepPct * 0.9 : proxy * 0.85,
    energyStrengthScore: sleepPct > 0 ? sleepPct : proxy * 0.88,
    overallScore: proxy,
    physicalStatus: proxy >= 70 ? 'Improving' : 'Monitor',
    uterineStatus: 'Normal',
    energyStatus: sleepPct >= 60 ? 'Strong' : 'Building',
  );

  return DashboardData(
    healthSummary: HealthSummary(
      hydration: base.healthSummary.hydration,
      sleep: base.healthSummary.sleep,
      symptoms: base.healthSummary.symptoms,
      medications: base.healthSummary.medications,
      supplements: base.healthSummary.supplements,
      babyGrowth: base.healthSummary.babyGrowth,
      postpartumRecovery: recovery,
    ),
    aiInsights: base.aiInsights,
    predictiveAlerts: base.predictiveAlerts,
    recommendations: base.recommendations,
    lastUpdated: base.lastUpdated,
  );
}
