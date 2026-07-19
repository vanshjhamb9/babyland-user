import 'dart:io';

import '../constants/api_endpoints.dart';
import '../error/app_exceptions.dart';
import '../error/error_handler.dart';
import '../network/api_client.dart';

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final String stage; // "prepregnancy", "pregnancy", "postpregnancy"
  final int? pregnancyWeek; // 1-40, required if stage is "pregnancy"
  final int? babyAge; // in months, required if stage is "postpregnancy"
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhoto,
    required this.stage,
    this.pregnancyWeek,
    this.babyAge,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
      stage: json['stage']?.toString() ?? 'prepregnancy',
      pregnancyWeek: (json['pregnancyWeek'] as num?)?.toInt(),
      babyAge: (json['babyAge'] as num?)?.toInt(),
      onboardingCompleted: json['onboardingCompleted'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'stage': stage,
      if (pregnancyWeek != null) 'pregnancyWeek': pregnancyWeek,
      if (babyAge != null) 'babyAge': babyAge,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? stage,
    int? pregnancyWeek,
    int? babyAge,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      stage: stage ?? this.stage,
      pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
      babyAge: babyAge ?? this.babyAge,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Onboarding status model
class OnboardingStatus {
  final bool onboarded;
  final List<String> completedSteps;
  final List<String> pendingSteps;

  OnboardingStatus({
    required this.onboarded,
    this.completedSteps = const [],
    this.pendingSteps = const [],
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return OnboardingStatus(
      onboarded: data['onboarded'] == true,
      completedSteps: (data['completedSteps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pendingSteps: (data['pendingSteps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// Service for user profile management and stage shifting
class UserService {
  final ApiClient _apiClient;

  UserService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get current user profile
  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getUser);

      if (response is Map<String, dynamic> && response['success'] == true) {
        return UserProfile.fromJson(response['data'] ?? response);
      }
      throw AppException('Failed to fetch user profile');
    } catch (e) {
      ErrorHandler.logError(e);
      throw AppException('Error fetching user profile: $e');
    }
  }

  /// Update user profile
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? phone,
    File? photo,
    String? stage,
    int? pregnancyWeek,
    int? babyAge,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (name != null) fields['name'] = name;
      if (email != null) fields['email'] = email;
      if (phone != null) fields['phone'] = phone;
      if (stage != null) {
        fields['stage'] = stage;
        if (stage == 'pregnancy' && pregnancyWeek != null) {
          fields['pregnancyWeek'] = pregnancyWeek;
        }
        if (stage == 'postpregnancy' && babyAge != null) {
          fields['babyAge'] = babyAge;
        }
      }

      Map<String, dynamic> response;
      if (photo != null) {
        // Multipart request with photo
        final files = <String, File>{'photo': photo};
        response = await _apiClient.putMultipart(
          ApiEndpoints.profileUpdate,
          fields: fields,
          files: files,
        ) as Map<String, dynamic>;
      } else {
        // Regular JSON request
        response = await _apiClient.put(
          ApiEndpoints.profileUpdate,
          data: fields,
        ) as Map<String, dynamic>;
      }

      if (response['success'] == true) {
        return UserProfile.fromJson(response['data'] ?? response);
      }
      throw AppException('Failed to update profile');
    } catch (e) {
      ErrorHandler.logError(e);
      throw AppException('Error updating profile: $e');
    }
  }

  /// Shift user stage
  /// 
  /// Valid stages: "prepregnancy", "pregnancy", "postpregnancy"
  /// For "pregnancy": requires pregnancyWeek (1-40)
  /// For "postpregnancy": requires babyAge (in months)
  Future<UserProfile> shiftStage({
    required String stage,
    int? pregnancyWeek,
    int? babyAge,
  }) async {
    if (stage != 'prepregnancy' &&
        stage != 'pregnancy' &&
        stage != 'postpregnancy') {
      throw ValidationException('Invalid stage: $stage');
    }

    if (stage == 'pregnancy' && (pregnancyWeek == null || pregnancyWeek < 1 || pregnancyWeek > 40)) {
      throw ValidationException('pregnancyWeek must be between 1 and 40 for pregnancy stage');
    }

    if (stage == 'postpregnancy' && (babyAge == null || babyAge < 0)) {
      throw ValidationException('babyAge must be provided for postpregnancy stage');
    }

    return updateProfile(
      stage: stage,
      pregnancyWeek: pregnancyWeek,
      babyAge: babyAge,
    );
  }

  /// Complete onboarding
  Future<bool> completeOnboarding() async {
    try {
      final response = await _apiClient.put(ApiEndpoints.onboardingComplete);

      if (response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return false;
    } catch (e) {
      ErrorHandler.logError(e);
      throw AppException('Error completing onboarding: $e');
    }
  }

  /// Check onboarding status for a specific tracker type
  Future<OnboardingStatus> checkOnboardingStatus(String type) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.checkModeOnboard(type),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return OnboardingStatus.fromJson(response);
      }
      return OnboardingStatus(onboarded: false);
    } catch (e) {
      ErrorHandler.logError(e);
      return OnboardingStatus(onboarded: false);
    }
  }

  /// Get user by ID (for admin or profile viewing)
  Future<UserProfile> getUserById(String userId) async {
    try {
      final response = await _apiClient.get(
        '/users/getuser-by-id/$userId',
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        return UserProfile.fromJson(response['data'] ?? response);
      }
      throw AppException('Failed to fetch user');
    } catch (e) {
      ErrorHandler.logError(e);
      throw AppException('Error fetching user: $e');
    }
  }
}
