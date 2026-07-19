import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../models/symptom_check_model.dart';
import '../repositories/symptom_checker_repository.dart';

/// Controller for AI Symptom Checker feature.
class SymptomCheckerController extends ChangeNotifier {
  final SymptomCheckerRepository _repository;
  final AnalyticsService _analytics;

  final TextEditingController symptomInput = TextEditingController();
  final List<String> _symptoms = [];
  List<String> get symptoms => List.unmodifiable(_symptoms);

  SymptomCheckResult? _result;
  SymptomCheckResult? get result => _result;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  static const List<String> commonSymptoms = [
    'Headache',
    'Nausea',
    'Fatigue',
    'Back pain',
    'Swollen feet',
    'Dizziness',
    'Cramping',
    'Heartburn',
    'Insomnia',
    'Mood swings',
  ];

  SymptomCheckerController({
    required SymptomCheckerRepository repository,
    required AnalyticsService analytics,
  })  : _repository = repository,
        _analytics = analytics;

  void addSymptom(String symptom) {
    final trimmed = symptom.trim();
    if (trimmed.isEmpty || _symptoms.contains(trimmed)) return;
    _symptoms.add(trimmed);
    symptomInput.clear();
    notifyListeners();
  }

  void removeSymptom(String symptom) {
    _symptoms.remove(symptom);
    notifyListeners();
  }

  void clearAll() {
    _symptoms.clear();
    _result = null;
    _error = null;
    notifyListeners();
  }

  Future<void> checkSymptoms() async {
    if (_symptoms.isEmpty) {
      _error = 'Please add at least one symptom';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      _result = await _repository.checkSymptoms(_symptoms);
      _analytics.logFeatureUsed('symptom_checker', params: {
        'symptom_count': _symptoms.length.toString(),
        'risk_level': _result?.riskLevel ?? 'unknown',
      });
    } catch (e) {
      log('Symptom check error: $e', name: 'SymptomCheckerCtrl');
      _error = 'Failed to analyze symptoms. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    symptomInput.dispose();
    super.dispose();
  }
}
