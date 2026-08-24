import '../constants/api_endpoints.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../models/health_tracker_models.dart';
import '../network/api_client.dart';

/// Comprehensive service for all Phase 3 Health Trackers.
/// Provides CRUD operations for: Hydration, Sleep, Symptoms, Medications, Supplements, Baby Growth
class HealthTrackerService {
  final ApiClient _apiClient;

  HealthTrackerService({required ApiClient apiClient}) : _apiClient = apiClient;

  static const Duration _hydCacheTtl = Duration(seconds: 10);
  final Map<String, _CachedHydration> _hydCache = {};
  final Map<String, Future<PaginatedResponse<HydrationLog>>> _hydInFlight = {};

  // ─── Hydration Tracker ────────────────────────────────────

  /// Create a hydration log
  Future<HydrationLog> createHydrationLog(HydrationLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.hydration,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        _hydCache.clear();
        return HydrationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create hydration log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating hydration log: $e');
    }
  }

  /// Get hydration logs with pagination
  Future<PaginatedResponse<HydrationLog>> getHydrationLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey =
        '${from?.toIso8601String() ?? ""}|${to?.toIso8601String() ?? ""}|$page|$limit';

    final cached = _hydCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _hydCacheTtl) {
      return cached.response;
    }

    final inFlight = _hydInFlight[cacheKey];
    if (inFlight != null) return inFlight;

    final future = _fetchHydrationLogs(cacheKey, from: from, to: to, page: page, limit: limit);
    _hydInFlight[cacheKey] = future;
    try {
      return await future;
    } finally {
      _hydInFlight.remove(cacheKey);
    }
  }

  Future<PaginatedResponse<HydrationLog>> _fetchHydrationLogs(
    String cacheKey, {
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      // Contract: use startDate/endDate for date-time filtering.
      if (from != null) params['startDate'] = from.toIso8601String();
      if (to != null) params['endDate'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.hydration,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        final result = PaginatedResponse.fromJson(
          response,
          (json) => HydrationLog.fromJson(json),
        );
        _hydCache[cacheKey] = _CachedHydration(result, DateTime.now());
        if (_hydCache.length > 12) {
          _hydCache.remove(_hydCache.keys.first);
        }
        return result;
      }
      throw HealthTrackerException('Failed to fetch hydration logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching hydration logs: $e');
    }
  }

  /// Get a specific hydration log by ID
  Future<HydrationLog> getHydrationLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.hydrationById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return HydrationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch hydration log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching hydration log: $e');
    }
  }

  /// Update a hydration log
  Future<HydrationLog> updateHydrationLog(String id, HydrationLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.hydrationById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return HydrationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update hydration log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating hydration log: $e');
    }
  }

  /// Delete a hydration log
  Future<bool> deleteHydrationLog(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.hydrationById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting hydration log: $e');
    }
  }

  // ─── Sleep Tracker ────────────────────────────────────────

  /// Create a sleep log
  Future<SleepLog> createSleepLog(SleepLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sleep,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SleepLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create sleep log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating sleep log: $e');
    }
  }

  /// Get sleep logs with pagination
  Future<PaginatedResponse<SleepLog>> getSleepLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      // Keep both key styles for backend compatibility.
      // Some endpoints use startDate/endDate while older ones read from/to.
      if (from != null) {
        final iso = from.toIso8601String();
        params['startDate'] = iso;
        params['from'] = iso;
      }
      if (to != null) {
        final iso = to.toIso8601String();
        params['endDate'] = iso;
        params['to'] = iso;
      }

      final response = await _apiClient.get(
        ApiEndpoints.sleep,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => SleepLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch sleep logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching sleep logs: $e');
    }
  }

  /// Get a specific sleep log by ID
  Future<SleepLog> getSleepLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.sleepById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SleepLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch sleep log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching sleep log: $e');
    }
  }

  /// Update a sleep log
  Future<SleepLog> updateSleepLog(String id, SleepLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.sleepById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SleepLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update sleep log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating sleep log: $e');
    }
  }

  /// Delete a sleep log
  Future<bool> deleteSleepLog(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.sleepById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting sleep log: $e');
    }
  }

  // ─── Symptom Tracker ──────────────────────────────────────

  /// Create a symptom log
  Future<SymptomLog> createSymptomLog(SymptomLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.symptoms,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SymptomLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create symptom log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating symptom log: $e');
    }
  }

  /// Get symptom logs with pagination
  Future<PaginatedResponse<SymptomLog>> getSymptomLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.symptoms,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => SymptomLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch symptom logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching symptom logs: $e');
    }
  }

  /// Get a specific symptom log by ID
  Future<SymptomLog> getSymptomLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.symptomById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SymptomLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch symptom log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching symptom log: $e');
    }
  }

  /// Update a symptom log
  Future<SymptomLog> updateSymptomLog(String id, SymptomLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.symptomById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SymptomLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update symptom log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating symptom log: $e');
    }
  }

  /// Delete a symptom log
  Future<bool> deleteSymptomLog(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.symptomById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting symptom log: $e');
    }
  }

  // ─── Medication Tracker ────────────────────────────────────

  /// Create a medication log
  Future<MedicationLog> createMedicationLog(MedicationLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.medication,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return MedicationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create medication log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating medication log: $e');
    }
  }

  /// Get medication logs with pagination
  Future<PaginatedResponse<MedicationLog>> getMedicationLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.medication,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => MedicationLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch medication logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching medication logs: $e');
    }
  }

  /// Get a specific medication log by ID
  Future<MedicationLog> getMedicationLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.medicationById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return MedicationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch medication log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching medication log: $e');
    }
  }

  /// Update a medication log
  Future<MedicationLog> updateMedicationLog(
      String id, MedicationLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.medicationById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return MedicationLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update medication log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating medication log: $e');
    }
  }

  /// Delete a medication log
  Future<bool> deleteMedicationLog(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.medicationById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting medication log: $e');
    }
  }

  // ─── Supplement Tracker ────────────────────────────────────

  /// Create a supplement log
  Future<SupplementLog> createSupplementLog(SupplementLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.supplements,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SupplementLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create supplement log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating supplement log: $e');
    }
  }

  /// Get supplement logs with pagination
  Future<PaginatedResponse<SupplementLog>> getSupplementLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.supplements,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => SupplementLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch supplement logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching supplement logs: $e');
    }
  }

  /// Get a specific supplement log by ID
  Future<SupplementLog> getSupplementLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.supplementById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SupplementLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch supplement log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching supplement log: $e');
    }
  }

  /// Update a supplement log
  Future<SupplementLog> updateSupplementLog(
      String id, SupplementLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.supplementById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return SupplementLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update supplement log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating supplement log: $e');
    }
  }

  /// Delete a supplement log
  Future<bool> deleteSupplementLog(String id) async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.supplementById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting supplement log: $e');
    }
  }

  // ─── Baby Growth Tracker (Phase 3) ─────────────────────────

  /// Create a baby growth log
  Future<BabyGrowthLog> createBabyGrowthLog(BabyGrowthLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.babyGrowthV1,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return BabyGrowthLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create baby growth log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating baby growth log: $e');
    }
  }

  /// Get baby growth logs with pagination
  Future<PaginatedResponse<BabyGrowthLog>> getBabyGrowthLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.babyGrowthV1,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => BabyGrowthLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch baby growth logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching baby growth logs: $e');
    }
  }

  /// Get a specific baby growth log by ID
  Future<BabyGrowthLog> getBabyGrowthLog(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.babyGrowthV1ById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return BabyGrowthLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch baby growth log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching baby growth log: $e');
    }
  }

  /// Update a baby growth log
  Future<BabyGrowthLog> updateBabyGrowthLog(
      String id, BabyGrowthLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.babyGrowthV1ById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return BabyGrowthLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update baby growth log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating baby growth log: $e');
    }
  }

  /// Delete a baby growth log
  Future<bool> deleteBabyGrowthLog(String id) async {
    try {
      final response =
          await _apiClient.delete(ApiEndpoints.babyGrowthV1ById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting baby growth log: $e');
    }
  }

  // ─── Postpartum Recovery Tracker ─────────────────────────

  /// Create a postpartum recovery log
  Future<PostpartumLog> createPostpartumLog(PostpartumLog log) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.postpartumRecovery,
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PostpartumLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to create postpartum log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error creating postpartum log: $e');
    }
  }

  /// Get postpartum recovery logs with pagination
  Future<PaginatedResponse<PostpartumLog>> getPostpartumLogs({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final response = await _apiClient.get(
        ApiEndpoints.postpartumRecovery,
        params: params,
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => PostpartumLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch postpartum logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching postpartum logs: $e');
    }
  }

  /// Get a specific postpartum recovery log by ID
  Future<PostpartumLog> getPostpartumLog(String id) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.postpartumRecoveryById(id));

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PostpartumLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to fetch postpartum log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching postpartum log: $e');
    }
  }

  /// Update a postpartum recovery log
  Future<PostpartumLog> updatePostpartumLog(
      String id, PostpartumLog log) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.postpartumRecoveryById(id),
        data: log.toJson(),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PostpartumLog.fromJson(response['data'] ?? response);
      }
      throw HealthTrackerException('Failed to update postpartum log');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error updating postpartum log: $e');
    }
  }

  /// Delete a postpartum recovery log
  Future<bool> deletePostpartumLog(String id) async {
    try {
      final response =
          await _apiClient.delete(ApiEndpoints.postpartumRecoveryById(id));

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error deleting postpartum log: $e');
    }
  }

  /// Get patient postpartum recovery logs (for Doctor Panel)
  Future<PaginatedResponse<PostpartumLog>> getPatientPostpartumLogs(
      String userId,
      {int page = 1,
      int limit = 50}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.patientPostpartumLogs(userId),
        params: {'page': page, 'limit': limit},
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return PaginatedResponse.fromJson(
          response,
          (json) => PostpartumLog.fromJson(json),
        );
      }
      throw HealthTrackerException('Failed to fetch patient postpartum logs');
    } catch (e) {
      ErrorHandler.logError(e);
      throw HealthTrackerException('Error fetching patient logs: $e');
    }
  }
}

class _CachedHydration {
  final PaginatedResponse<HydrationLog> response;
  final DateTime fetchedAt;

  _CachedHydration(this.response, this.fetchedAt);
}

