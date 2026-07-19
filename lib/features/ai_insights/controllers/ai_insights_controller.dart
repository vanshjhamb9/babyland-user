import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../models/ai_insight_model.dart';
import '../repositories/ai_insights_repository.dart';

/// Controller for AI Pregnancy Insights Dashboard.
class AiInsightsController extends ChangeNotifier {
  final AiInsightsRepository _repository;
  final AnalyticsService _analytics;

  // ─── State ────────────────────────────────────────────────
  List<AiInsightModel> _insights = [];
  List<AiInsightModel> get insights => _insights;

  AiDailyGuidance? _dailyGuidance;
  AiDailyGuidance? get dailyGuidance => _dailyGuidance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isGuidanceLoading = false;
  bool get isGuidanceLoading => _isGuidanceLoading;

  String? _error;
  String? get error => _error;

  String _selectedFilter = 'all';
  String get selectedFilter => _selectedFilter;

  AiInsightsController({
    required AiInsightsRepository repository,
    required AnalyticsService analytics,
  })  : _repository = repository,
        _analytics = analytics;

  // ─── Filtered insights ──────────────────────────────────
  List<AiInsightModel> get filteredInsights {
    if (_selectedFilter == 'all') return _insights;
    return _insights.where((i) => i.type == _selectedFilter).toList();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // ─── Load Insights ──────────────────────────────────────
  Future<void> loadInsights() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await _repository.getInsights();
      _analytics.logScreenView('ai_insights_dashboard');
      _analytics.logFeatureUsed('ai_insights_viewed');
    } catch (e) {
      log('Error loading insights: $e', name: 'AiInsightsCtrl');
      _error = 'Failed to load insights';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load Daily Guidance ────────────────────────────────
  Future<void> loadDailyGuidance() async {
    _isGuidanceLoading = true;
    notifyListeners();

    try {
      _dailyGuidance = await _repository.getDailyGuidance();
      _analytics.logFeatureUsed('ai_daily_guidance_viewed');
    } catch (e) {
      log('Error loading daily guidance: $e', name: 'AiInsightsCtrl');
    }

    _isGuidanceLoading = false;
    notifyListeners();
  }

  // ─── Refresh All ────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([
      loadInsights(),
      loadDailyGuidance(),
    ]);
  }
}
