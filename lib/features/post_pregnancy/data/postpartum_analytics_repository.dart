import 'package:babyland/app/controller/post_pregenancy/model/recovery_progress_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:babyland/features/post_pregnancy/postpartum_dashboard_enrichment.dart';
import 'package:babyland/features/post_pregnancy/data/postpartum_logs_merge.dart';
import 'package:babyland/features/post_pregnancy/recovery_engine/postpartum_recovery_engine.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:intl/intl.dart';
/// Loads and aggregates postpartum dashboard analytics from live APIs.
class PostpartumAnalyticsRepository {
  final Repository _repository;
  final DashboardService _dashboardService;

  PostpartumAnalyticsRepository({
    Repository? repository,
    DashboardService? dashboardService,
  })  : _repository = repository ?? Repository(),
        _dashboardService = dashboardService ?? sl.dashboardService;

  Future<PostpartumRecoverySnapshot> loadRecoverySnapshot({
    RecoveryProgressModel? recoveryTask,
    MenstrualLogsListModel? dashboardLogs,
  }) async {
    final days = TrackerMath.lastNDays(DateTime.now(), count: 7);
    List<Data> logs = dashboardLogs?.data ?? [];

    try {
      final bulk = await _repository.getPostpartumLogs();
      if (bulk.data != null && bulk.data!.isNotEmpty) {
        logs = bulk.data!;
      }
    } catch (_) {}

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayRes = await _repository.getPostpartumLogs(params: {'date': today});
      if (todayRes.data != null && todayRes.data!.isNotEmpty) {
        final merged = <Data>[...logs];
        for (final row in todayRes.data!) {
          final p = TrackerMath.parseDateAny(row.date);
          if (p == null) continue;
          final key = TrackerMath.dayKey(p);
          final idx = merged.indexWhere(
            (l) => TrackerMath.dayKey(TrackerMath.parseDateAny(l.date) ?? DateTime(0)) == key,
          );
          if (idx >= 0) {
            merged[idx] = row;
          } else {
            merged.add(row);
          }
        }
        logs = merged;
      }
    } catch (_) {}

    logs = mergePostpartumLogsWithLocalMood(logs);

    List<int> hydrationSeries = List.filled(7, 0);
    try {
      final from = days.first;
      final to = days.last.add(const Duration(hours: 23, minutes: 59));
      final resp = await sl.healthTrackerService.getHydrationLogs(
        from: from,
        to: to,
        page: 1,
        limit: 200,
      );
      final map = <String, int>{};
      for (final log in resp.data) {
        final d = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final key = TrackerMath.dayKey(d);
        map[key] = (map[key] ?? 0) + log.amountMl;
      }
      hydrationSeries = days.map((d) => map[TrackerMath.dayKey(d)] ?? 0).toList();
    } catch (_) {}

    DashboardData? dashboard;
    try {
      dashboard = await enrichPostpartumDashboard(
        _dashboardService.refresh(),
        logs: logs,
        hydrationTodayMl: hydrationSeries.isNotEmpty ? hydrationSeries.last : 0,
      );
    } catch (_) {
      try {
        dashboard = await _dashboardService.refresh();
      } catch (_) {}
    }

    final taskPct = double.tryParse(
          recoveryTask?.tasks?.completionPercentage ?? '0',
        ) ??
        0.0;

    return PostpartumRecoveryEngine.buildSnapshot(
      serverRecovery: dashboard?.healthSummary.postpartumRecovery,
      logs: logs,
      taskCompletionPercent: taskPct,
      hydrationSeriesMl: hydrationSeries,
      trendDays: days,
      aiInsights: dashboard?.aiInsights ?? const [],
    );
  }
}
