import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';

/// Fills gaps when `/healthInsights` returns zeros by reading Phase 3 trackers
/// and today's pregnancy daily log (symptoms), or pre-pregnancy mood log symptoms.
Future<DashboardData> enrichDashboardData(
  Future<DashboardData> baseFuture, {
  PregnancyController? pregnancyController,
  /// When non-null and API symptom count is zero, use this (e.g. today's menstrual log).
  int? preMenstrualSymptomsToday,
  /// When non-null and sleep minutes are zero, derive sleep from today's menstrual log.
  int? preMenstrualSleepQualityToday,
}) async {
  final base = await baseFuture;
  final h = base.healthSummary;

  int waterMl = h.hydration.today;
  int sleepMin = h.sleep.lastNight;
  int symptomCount = h.symptoms.activeCount;

  int minutesFromSleepQuality(int q) {
    final clamped = q.clamp(1, 5);
    switch (clamped) {
      case 1:
        return 300; // 5h
      case 2:
        return 360; // 6h
      case 3:
        return 420; // 7h
      case 4:
        return 480; // 8h
      case 5:
        return 540; // 9h
      default:
        return 0;
    }
  }

  if (waterMl <= 0) {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final logs = await sl.healthTrackerService.getHydrationLogs(
        from: from,
        to: to,
        page: 1,
        limit: 200,
      );
      waterMl = logs.data.fold<int>(0, (sum, log) => sum + log.amountMl);
    } catch (_) {}
  }

  if (sleepMin <= 0) {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 40));
      final logs = await sl.healthTrackerService.getSleepLogs(
        from: from,
        to: now,
        page: 1,
        limit: 40,
      );
      if (logs.data.isNotEmpty) {
        final sorted = [...logs.data]
          ..sort((a, b) => b.sleepEndTime.compareTo(a.sleepEndTime));
        sleepMin = sorted.first.durationMinutes;
      }
    } catch (_) {}
  }

  if (pregnancyController != null && sleepMin <= 0) {
    final dailyLogs =
        pregnancyController.pregnancyApiData?.data?.data?.data?.tracker?.dailyLogs ??
            [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    for (final log in dailyLogs) {
      final parsed = TrackerMath.parseDateAny(log.date ?? '');
      if (parsed == null) continue;
      final d = DateTime(parsed.year, parsed.month, parsed.day);
      if (d == todayDate) {
        final q = int.tryParse((log.sleepQuality ?? '').trim());
        if (q != null && q > 0) {
          sleepMin = minutesFromSleepQuality(q);
        }
        break;
      }
    }
  } else if (pregnancyController == null &&
      sleepMin <= 0 &&
      preMenstrualSleepQualityToday != null &&
      preMenstrualSleepQualityToday > 0) {
    sleepMin = minutesFromSleepQuality(preMenstrualSleepQualityToday);
  }

  if (pregnancyController != null && symptomCount <= 0) {
    final dailyLogs =
        pregnancyController.pregnancyApiData?.data?.data?.data?.tracker?.dailyLogs ??
            [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    for (final log in dailyLogs) {
      final parsed = TrackerMath.parseDateAny(log.date ?? '');
      if (parsed == null) continue;
      final d = DateTime(parsed.year, parsed.month, parsed.day);
      if (d == todayDate) {
        symptomCount = log.symptoms?.length ?? 0;
        break;
      }
    }
  } else if (pregnancyController == null &&
      symptomCount <= 0 &&
      preMenstrualSymptomsToday != null) {
    symptomCount = preMenstrualSymptomsToday;
  }

  if (waterMl == h.hydration.today &&
      sleepMin == h.sleep.lastNight &&
      symptomCount == h.symptoms.activeCount) {
    return base;
  }

  return DashboardData(
    healthSummary: HealthSummary(
      hydration: HydrationSummary(
        today: waterMl,
        weeklyAverage: h.hydration.weeklyAverage,
        goal: h.hydration.goal,
        trend: h.hydration.trend,
      ),
      sleep: SleepSummary(
        lastNight: sleepMin,
        weeklyAverage: h.sleep.weeklyAverage,
        goal: h.sleep.goal,
        quality: h.sleep.quality,
      ),
      symptoms: SymptomSummary(
        activeCount: symptomCount,
        recent: h.symptoms.recent,
      ),
      medications: h.medications,
      supplements: h.supplements,
      babyGrowth: h.babyGrowth,
    ),
    aiInsights: base.aiInsights,
    predictiveAlerts: base.predictiveAlerts,
    recommendations: base.recommendations,
    lastUpdated: base.lastUpdated,
  );
}
