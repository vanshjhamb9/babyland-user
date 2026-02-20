import 'dart:convert';
import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/network/end_points.dart';
import '../data/response/api_response.dart';
import '../data/storage/user_local_data.dart';

class GetUserProvider extends ChangeNotifier{
  ApiResponse<GetUserModel>? _userData = ApiResponse.completed(null);
  ApiResponse<GetUserModel>? get userData => _userData;

  void setUserData(ApiResponse<GetUserModel> response) {
    _userData = response;
    notifyListeners();
  }

  String get currentStageLabel {
    final user = _userData?.data?.user?.user;
    if (user == null) return "Unknown";
    
    // Check cycleType (used for logic mapping in this app)
    final cType = user.cycleType;
    if (cType == "pregnancy") return "Pregnancy";
    if (cType == "post_pregnancy") return "Post-pregnancy";
    if (cType == "regular" || cType == "irregular" || cType == "prepregnancy") return "Pre-pregnancy";
    
    return "Onboarding";
  }

  Future<void> getUser() async {
    pt("getUser() called - Setting loading");
    // Preserve existing data while loading
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
        pt(name: "response", "${value.message}");
        
        final userObj = value.user;
        final user = userObj?.user;
        if (user != null) {
           // Self-healing patch for backend mathematical bug caused by Strings
           if (user.hasCorruptedTypes) {
             pt("Found corrupted backend data types. Sending self-healing patch...");
             try {
                final Map<String, dynamic> cleanupData = {};
                if (user.averagePeriodLengthDays != null) {
                  final parsed = int.tryParse(user.averagePeriodLengthDays!);
                  if (parsed != null) cleanupData['averagePeriodLengthDays'] = parsed;
                }
                if (user.cycleLengthDays != null && user.cycleLengthDays != 'null') {
                  final parsed = int.tryParse(user.cycleLengthDays!);
                  if (parsed != null) cleanupData['cycleLengthDays'] = parsed;
                }
                if (cleanupData.isNotEmpty) {
                    await repository.onboardingCompleted(cleanupData);
                    pt("Successfully healed backend data types.");
                }
             } catch(e) {
                pt("Failed to heal data types: $e");
             }
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
           } else if (cType == "regular" || cType == "irregular") {
              // We don't overwrite local step if it's already set to something else,
              // to respect the user's current session until backend catches up.
           }
        }
      }
      if(value.success == false) {
        setUserData(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in getUser: $error\n$stackTrace");
      setUserData(ApiResponse.error(error.toString()));
      notifyListeners();
    },);
  }

  /// Synchronize the user's stage with the backend
  Future<bool> updateUserStage(int index) async {
    String cycleType;
    String step;
    switch (index) {
      case 0:
        cycleType = "regular";
        step = "0";
        break;
      case 1:
        cycleType = "pregnancy";
        step = "1";
        break;
      case 2:
        cycleType = "post_pregnancy";
        step = "2";
        break;
      default:
        return false;
    }

    pt("Syncing stage to backend: index=$index, cycleType=$cycleType");
    
    // 1. Update local step immediately for snappy UI
    await UserLocalData.saveStep(step);
    
    try {
      // 2. Sync with backend
      // We update BOTH cycleType and stage to ensure backend persistence
      await repository.updateUserProfile({
        "cycleType": cycleType,
        "stage": cycleType == "post_pregnancy" ? "postpregnancy" : cycleType
      });
      
      // Also call onboardingCompleted for potential side effects if needed
      await repository.onboardingCompleted({"cycleType": cycleType});
      
      pt("Backend stage sync successful");
      // 3. Refresh profile data
      await getUser();
      return true;
    } catch (e) {
      pt("Error syncing stage: $e");
      return false;
    }
  }

  // update profile

  void updateUserConditions(Conditions conditions) {
    if (userData?.data?.user != null) {
      userData?.data?.user?.user?.conditions = conditions;
      notifyListeners();
    }
  }


  ApiResponse<CommonResponseModel>? _updateProfileData = ApiResponse.completed(null);
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
    // Prepare data for Profile Update
    final conditionsMap = {
      "PCOS": conditions["PCOS"] ?? false,
      "PMS": conditions["PMS"] ?? false,
      "Endometriosis": conditions["Endometriosis"] ?? false,
      "ThyroidIssues": conditions["Thyroid Issues"] ?? false,
      "Diabetes": conditions["Diabetes"] ?? false,
      "Hypertension": conditions["Hypertension"] ?? false,
    };

    Map<String, dynamic> data = {
      "name": name,
      "email": email,
      "phone": phone,
      "weight": weight,
      "medicalHistory": medicalHistory,
      "conditions": conditionsMap,
    };

      // Send profile update — repository handles multipart if image is present
      final value = await repository.updateUserProfile(data, profileImage: profileImage);
      if (value.success == true) {
        updateProfile(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "Profile updated successfully!");
        await getUser();
        Navigator.pop(navigatorKey.currentContext!);
      } else {
        updateProfile(ApiResponse.error(value.message ?? "Something went wrong!"));
        AppPopUp.showToast(message: value.message ?? "Profile updated unsuccessfully!");
      }
    } catch (e,st) {
      pt("Update Profile Error: $e $st");
      updateProfile(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Failed to update profile: $e");
    }
    notifyListeners();
  }


}