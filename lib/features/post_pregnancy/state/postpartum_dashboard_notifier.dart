import 'package:babyland/app/controller/post_pregenancy/model/recovery_progress_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/features/post_pregnancy/data/postpartum_analytics_repository.dart';
import 'package:babyland/features/post_pregnancy/domain/postpartum_recovery_snapshot.dart';
import 'package:flutter/foundation.dart';

/// Cached postpartum dashboard analytics; refresh after any log save.
class PostpartumDashboardNotifier extends ChangeNotifier {
  PostpartumDashboardNotifier({PostpartumAnalyticsRepository? repository})
      : _repository = repository ?? PostpartumAnalyticsRepository();

  final PostpartumAnalyticsRepository _repository;

  PostpartumRecoverySnapshot? _snapshot;
  bool _loading = false;
  Object? _error;
  int _dataGeneration = 0;

  PostpartumRecoverySnapshot? get snapshot => _snapshot;
  bool get isLoading => _loading;
  Object? get error => _error;
  int get dataGeneration => _dataGeneration;

  Future<void> refresh({
    RecoveryProgressModel? recoveryTask,
    MenstrualLogsListModel? dashboardLogs,
    bool force = false,
  }) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _snapshot = await _repository.loadRecoverySnapshot(
        recoveryTask: recoveryTask,
        dashboardLogs: dashboardLogs,
      );
    } catch (e, st) {
      _error = e;
      debugPrint('[PostpartumDashboard] refresh failed: $e\n$st');
      _snapshot ??= PostpartumRecoverySnapshot.empty();
    } finally {
      _loading = false;
      _dataGeneration++;
      notifyListeners();
    }
  }

  void clear() {
    _snapshot = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
