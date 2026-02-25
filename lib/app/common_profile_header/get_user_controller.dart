import 'dart:convert';
import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/response/api_response.dart';
import '../data/storage/user_local_data.dart';

class GetUserProvider extends ChangeNotifier {
  ApiResponse<GetUserModel>? _userData = ApiResponse.completed(null);
  ApiResponse<GetUserModel>? get userData => _userData;

  void setUserData(ApiResponse<GetUserModel> response) {
    _userData = response;
    notifyListeners();
  }

  String get currentStageLabel {
    final user = _userData?.data?.user?.user;
    if (user == null) return "Unknown";

    final stage = user.stage;
    if (stage == "pregnancy") return "Pregnancy";
    if (stage == "postpregnancy") return "Post-pregnancy";

    final cType = user.cycleType;
    if (cType == "pregnancy") return "Pregnancy";
    if (cType == "post_pregnancy") return "Post-pregnancy";
    if (cType == "regular" || cType == "irregular" || cType == "prepregnancy") return "Pre-pregnancy";
    return "Onboarding";
  }

  Future<void> getUser() async {
    pt("getUser() called - Setting loading");
    if (_userData != null && _userData!.data != null) {
      _userData = ApiResponse.loading(data: _userData!.data);
    } else {
      setUserData(ApiResponse.loading());
    }
    notifyListeners();

    await repository.getUser().then((value) async {
      pt("getUser() response: success=${value.success}");
      if (value.success == true) {
        setUserData(ApiResponse.completed(value));

        final userObj = value.user;
        final user = userObj?.user;
        if (user != null) {
          if (user.sId != null && user.sId!.isNotEmpty) {
            await SecureStorage.saveUserId(user.sId!);
          }

          // ✅ Self-healing patch for numeric strings
          if (user.hasCorruptedTypes) {
            try {
              final Map<String, dynamic> cleanupData = {};
              if (user.averagePeriodLengthDays != null) {
                final parsed = int.tryParse(user.averagePeriodLengthDays!);
                if (parsed != null) cleanupData['averagePeriodLengthDays'] = parsed;
              }
              if (user.cycleLengthDays != null &&
                  user.cycleLengthDays != 'null') {
                final parsed = int.tryParse(user.cycleLengthDays!);
                if (parsed != null) cleanupData['cycleLengthDays'] = parsed;
              }
              if (cleanupData.isNotEmpty) {
                await repository.onboardingCompleted(cleanupData);
              }
            } catch (_) {}
          }

           String? cType = user.cycleType;
           pt("Syncing data. Backend cycleType: $cType");
           
           // Minimal sync for Splash screen routing
           if (cType == "pregnancy") {
              UserLocalData.saveStep("1");
              String? conceptionDate = user.pregnancyStartDate;
              if (conceptionDate == null && userObj?.pregnancyTracker != null) {
                 conceptionDate = userObj!.pregnancyTracker!['pregnancyStartDate']?.toString() ??
                                  userObj.pregnancyTracker!['conception_date']?.toString();
              }
              if (conceptionDate != null && conceptionDate.isNotEmpty) {
                 UserLocalData.savePregnancySetupComplete();
                 UserLocalData.saveConceptionDate(conceptionDate);
              }
           } else if (cType == "post_pregnancy") {
              UserLocalData.saveStep("2");
           } else if (cType == "regular" || cType == "irregular" || cType == "prepregnancy") {
              // We don't overwrite local step if it's already set to something else,
              // to respect the user's current session until backend catches up.
           }
        }
      }

      if (value.success == false) {
        setUserData(
            ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in getUser: $error");
      setUserData(ApiResponse.error(error.toString()));
      notifyListeners();
    });
  }

  Future<bool> updateUserStage(int index) async {
    String stage;
    String step;
    switch (index) {
      case 0:
        stage = "prepregnancy";
        step = "0";
        break;
      case 1:
        stage = "pregnancy";
        step = "1";
        break;
      case 2:
        stage = "postpregnancy"; // Note: cycleType in backend takes post_pregnancy, stage takes postpregnancy.
        step = "2";
        break;
      default:
        return false;
    }

    pt("Syncing stage to backend: index=$index, stage=$stage");
    await UserLocalData.saveStep(step);

    try {
      // ✅ Only send 'stage'. Never send cycleType here.
      // cycleType enum only accepts [regular, irregular].
      await repository.updateUserProfile({
        "stage": stage,
      });

      await getUser();
      return true;
    } catch (e) {
      pt("Error syncing stage: $e");
      return false;
    }
  }

  void updateUserConditions(Conditions conditions) {
    if (userData?.data?.user != null) {
      userData?.data?.user?.user?.conditions = conditions;
      notifyListeners();
    }
  }

  ApiResponse<CommonResponseModel>? _updateProfileData =
  ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get updateProfileData => _updateProfileData;

  void updateProfile(ApiResponse<CommonResponseModel> response) {
    _updateProfileData = response;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required Map<String, bool> conditions,
    File? profileImage,
    String? phone,
    String? weight,
    String? medicalHistory,
  }) async {
    updateProfile(ApiResponse.loading());
    notifyListeners();

    try {
      final conditionsMap = {
        "PCOS": conditions["PCOS"] ?? false,
        "PMS": conditions["PMS"] ?? false,
        "Endometriosis": conditions["Endometriosis"] ?? false,
        "ThyroidIssues": conditions["Thyroid Issues"] ?? false,
        "Diabetes": conditions["Diabetes"] ?? false,
        "Hypertension": conditions["Hypertension"] ?? false,
      };

      // ✅ Never force cycleType — backend retains existing valid value.
      Map<String, dynamic> data = {
        "name": name,
        "email": email,
        "phone": phone,
        "weight": weight,
        "medicalHistory": medicalHistory,
        "conditions": conditionsMap,
      };

      final value =
      await repository.updateUserProfile(data, profileImage: profileImage);
      if (value.success == true) {
        updateProfile(ApiResponse.completed(value));
        AppPopUp.showToast(
            message: value.message ?? "Profile updated successfully!");
        await getUser();
        Navigator.pop(navigatorKey.currentContext!);
      } else {
        updateProfile(
            ApiResponse.error(value.message ?? "Something went wrong!"));
        AppPopUp.showToast(
            message: value.message ?? "Profile update failed!");
      }
    } catch (e, st) {
      pt("Update Profile Error: $e $st");
      updateProfile(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Failed to update profile: $e");
    }
    notifyListeners();
  }
}