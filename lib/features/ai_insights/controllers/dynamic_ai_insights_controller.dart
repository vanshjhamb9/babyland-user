import 'dart:async';
import 'dart:convert';

import 'package:babyland/app/controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/subscription_dialog.dart';
import 'package:babyland/core/services/cache_service.dart';
import 'package:flutter/foundation.dart';

/// Tab selection for dynamic AI insights (maps to API `category` query param).
enum DynamicInsightCategory { all, nutrition, exercise, precautions, wellness }

extension DynamicInsightCategoryX on DynamicInsightCategory {
  String get label {
    switch (this) {
      case DynamicInsightCategory.all:
        return 'All';
      case DynamicInsightCategory.nutrition:
        return 'Nutrition';
      case DynamicInsightCategory.exercise:
        return 'Exercise';
      case DynamicInsightCategory.precautions:
        return 'Precautions';
      case DynamicInsightCategory.wellness:
        return 'Wellness';
    }
  }

  /// API value; `null` means aggregate all categories.
  String? get apiCategory {
    switch (this) {
      case DynamicInsightCategory.all:
        return null;
      case DynamicInsightCategory.nutrition:
        return 'nutrition';
      case DynamicInsightCategory.exercise:
        return 'exercise';
      case DynamicInsightCategory.precautions:
        return 'precautions';
      case DynamicInsightCategory.wellness:
        return 'wellness';
    }
  }
}

/// One row for UI: insight + source category (for styling in "All").
class DynamicInsightEntry {
  const DynamicInsightEntry({required this.item, required this.categoryKey});

  final InsightItem item;
  final String categoryKey;
}

/// Loads `/api/v1/ai/insights` per category with 6h cache and optional "All" merge.
class DynamicAiInsightsController extends ChangeNotifier {
  DynamicAiInsightsController({
    required Repository repository,
    required CacheService cacheService,
  }) : _repository = repository,
       _cache = cacheService;

  final Repository _repository;
  final CacheService _cache;

  static const _cachePrefix = 'dynamic_ai_insights_v2_';
  static const _ttl = Duration(hours: 6);

  static const _apiCategories = [
    'nutrition',
    'exercise',
    'precautions',
    'wellness',
  ];

  DynamicInsightCategory _selected = DynamicInsightCategory.all;
  DynamicInsightCategory get selectedCategory => _selected;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  List<DynamicInsightEntry> _entries = [];
  List<DynamicInsightEntry> get entries => _entries;

  QuickTip? _quickTip;
  QuickTip? get quickTip => _quickTip;

  Timer? _refreshTimer;

  DateTime? _lastGlobalRefresh;

  /// Optional `week` query (1–42) for `GET /api/v1/ai/insights`; JWT is the only user id.
  int? Function()? _pregnancyWeekResolver;

  /// Bind from UI (e.g. pregnancy week from profile). Omit resolver to let the server use [User.pregnancyWeek].
  void setPregnancyWeekResolver(int? Function()? resolver) {
    _pregnancyWeekResolver = resolver;
  }

  /// Call when the insights screen is opened (respects 6h cache unless stale).
  Future<void> onScreenOpened() async {
    await loadSelectedCategory(forceRefresh: _shouldRefreshFromAge());
  }

  void selectCategory(DynamicInsightCategory category) {
    if (_selected == category) return;
    _selected = category;
    _entries = [];
    _quickTip = null;
    notifyListeners();
    unawaited(loadSelectedCategory());
  }

  bool _shouldRefreshFromAge() {
    if (_lastGlobalRefresh == null) return true;
    return DateTime.now().difference(_lastGlobalRefresh!) >= _ttl;
  }

  void _schedulePeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_ttl, (_) {
      unawaited(loadSelectedCategory(forceRefresh: true));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Force network refresh (pull-to-refresh).
  Future<void> refresh() => loadSelectedCategory(forceRefresh: true);

  Future<void> loadSelectedCategory({bool forceRefresh = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (_selected == DynamicInsightCategory.all) {
        await _loadAllMerged(forceRefresh: forceRefresh);
      } else {
        await _loadSingle(_selected.apiCategory!, forceRefresh: forceRefresh);
      }
      _lastGlobalRefresh = DateTime.now();
      _schedulePeriodicRefresh();
    } catch (e, st) {
      pt('DynamicAiInsightsController: $e\n$st');
      _error = e.toString();
      _entries = [];
      _quickTip = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSingle(
    String apiCategory, {
    required bool forceRefresh,
  }) async {
    if (!forceRefresh) {
      final cached = _readSingleCache(apiCategory);
      if (cached != null) {
        _applyEntries(
          _entriesFromModel(cached, apiCategory),
          cached.dataexit?.quickTip,
        );
        return;
      }
    }

    final model = await _fetchFromNetwork(apiCategory);
    if (model != null) {
      await _writeSingleCache(apiCategory, model);
      _applyEntries(
        _entriesFromModel(model, apiCategory),
        model.dataexit?.quickTip,
      );
    } else {
      _entries = [];
      _quickTip = null;
    }
  }

  List<DynamicInsightEntry> _entriesFromModel(
    MenturalAiInsightsModel model,
    String apiCategory,
  ) {
    final items = model.dataexit?.items ?? [];
    return items
        .map((e) => DynamicInsightEntry(item: e, categoryKey: apiCategory))
        .toList();
  }

  void _applyEntries(List<DynamicInsightEntry> entries, QuickTip? tip) {
    _entries = entries;
    _quickTip = tip;
  }

  Future<void> _loadAllMerged({required bool forceRefresh}) async {
    if (!forceRefresh) {
      final merged = _readMergedCache();
      if (merged != null) {
        _applyEntries(merged.$1, merged.$2);
        return;
      }
      final fromParts = _tryMergeFromCategoryCaches();
      if (fromParts != null) {
        _applyEntries(fromParts.$1, fromParts.$2);
        await _writeMergedCache(fromParts.$1, fromParts.$2);
        return;
      }
    }

    final results = await Future.wait(
      _apiCategories.map((c) => _fetchFromNetwork(c)),
    );

    final entries = <DynamicInsightEntry>[];
    final seen = <String>{};
    QuickTip? tip;

    for (var i = 0; i < _apiCategories.length; i++) {
      final m = results[i];
      final cat = _apiCategories[i];
      tip ??= m?.dataexit?.quickTip;
      if (m != null) {
        await _writeSingleCache(cat, m);
      }
      for (final it in m?.dataexit?.items ?? []) {
        final key = '${it.title ?? ''}|${it.description ?? ''}|${it.sId ?? ''}';
        if (seen.add(key)) {
          entries.add(DynamicInsightEntry(item: it, categoryKey: cat));
        }
      }
    }

    if (entries.isEmpty) {
      _entries = [];
      _quickTip = null;
      return;
    }

    await _writeMergedCache(entries, tip);
    _applyEntries(entries, tip);
  }

  (List<DynamicInsightEntry>, QuickTip?)? _tryMergeFromCategoryCaches() {
    final list = <MenturalAiInsightsModel>[];
    for (final c in _apiCategories) {
      final m = _readSingleCache(c);
      if (m == null) return null;
      list.add(m);
    }

    final entries = <DynamicInsightEntry>[];
    final seen = <String>{};
    QuickTip? tip;

    for (var i = 0; i < _apiCategories.length; i++) {
      final m = list[i];
      final cat = _apiCategories[i];
      tip ??= m.dataexit?.quickTip;
      for (final it in m.dataexit?.items ?? []) {
        final key = '${it.title ?? ''}|${it.description ?? ''}|${it.sId ?? ''}';
        if (seen.add(key)) {
          entries.add(DynamicInsightEntry(item: it, categoryKey: cat));
        }
      }
    }

    return (entries, tip);
  }

  Future<MenturalAiInsightsModel?> _fetchFromNetwork(String apiCategory) async {
    final data = <String, dynamic>{'category': apiCategory};
    final w = _pregnancyWeekResolver?.call();
    if (w != null && w >= 1 && w <= 42) {
      data['week'] = w;
    }

    try {
      final value = await _repository.menturalAiInsights(data);

      if (value.success == true) {
        return value;
      }

      final msg = value.displayMessage;
      final handled =
          await SubscriptionDialog.showDialogIfSubscriptionRequired(msg);
      if (!handled) AppPopUp.showToast(message: msg);
      return null;
    } catch (error, stackTrace) {
      pt('DynamicAiInsightsController fetch $apiCategory: $error\n$stackTrace');
      AppPopUp.showToast(message: 'Error: $error');
      return null;
    }
  }

  MenturalAiInsightsModel? _readSingleCache(String key) {
    final raw = _cache.get('$_cachePrefix$key');
    if (raw == null) return null;
    try {
      final str = raw is String ? raw : jsonEncode(raw);
      final map = jsonDecode(str) as Map<String, dynamic>;
      return MenturalAiInsightsModel.fromJson(map);
    } catch (e) {
      pt('DynamicAiInsights cache read error: $e');
      return null;
    }
  }

  Future<void> _writeSingleCache(
    String key,
    MenturalAiInsightsModel model,
  ) async {
    try {
      await _cache.put(
        '$_cachePrefix$key',
        jsonEncode(model.toJson()),
        expiry: _ttl,
      );
    } catch (e) {
      pt('DynamicAiInsights cache write error: $e');
    }
  }

  (List<DynamicInsightEntry>, QuickTip?)? _readMergedCache() {
    final raw = _cache.get('${_cachePrefix}all');
    if (raw == null) return null;
    try {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(jsonDecode(raw as String) as Map);
      final list = map['entries'] as List<dynamic>? ?? [];
      final tipJson = map['quickTip'] as Map<String, dynamic>?;
      final entries = <DynamicInsightEntry>[];
      for (final row in list) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final cat = m['c']?.toString() ?? 'nutrition';
        final itemRaw = m['i'];
        final itemMap = itemRaw is Map<String, dynamic>
            ? itemRaw
            : itemRaw is Map
                ? Map<String, dynamic>.from(itemRaw)
                : null;
        if (itemMap == null) continue;
        entries.add(
          DynamicInsightEntry(
            categoryKey: cat,
            item: InsightItem.fromJson(itemMap),
          ),
        );
      }
      final tip = tipJson != null ? QuickTip.fromJson(tipJson) : null;
      return (entries, tip);
    } catch (e) {
      pt('DynamicAiInsights merged cache read: $e');
      return null;
    }
  }

  Future<void> _writeMergedCache(
    List<DynamicInsightEntry> entries,
    QuickTip? tip,
  ) async {
    try {
      final map = {
        'entries': entries
            .map((e) => {'c': e.categoryKey, 'i': e.item.toJson()})
            .toList(),
        'quickTip': tip?.toJson(),
      };
      await _cache.put('${_cachePrefix}all', jsonEncode(map), expiry: _ttl);
    } catch (e) {
      pt('DynamicAiInsights merged cache write: $e');
    }
  }
}
