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

    await repository.getUser().then((value) {
      pt("getUser() response: success=${value.success}");
      if (value.success == true) {
        setUserData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
        
        final user = value.user?.user;
        if (user != null) {
           String? cType = user.cycleType;
           pt("Syncing data. Backend cycleType: $cType");
           
           // Minimal sync for Splash screen routing
           if (cType == "pregnancy") {
              UserLocalData.saveStep("1");
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

    String? profilePicUrl;

    try {
      // 1. Upload image if present
      if (profileImage != null) {
        // AppPopUp.showToast(message: "Uploading image...");
        final uploadResponseMap = await repository.uploadFile(profileImage);
        pt("Raw Upload Response: $uploadResponseMap");

        bool success = uploadResponseMap['success'] == true;
        dynamic responseData = uploadResponseMap['data'];
        String? message = uploadResponseMap['message']?.toString();

        if (success) {
             // Try to find the URL in various places
             if (responseData is String) {
               profilePicUrl = responseData;
             } else if (responseData is Map) {
               profilePicUrl = responseData['url'] ?? responseData['secure_url'] ?? responseData['path'] ?? responseData['fileUrl'];
             } else {
               // checking root
               profilePicUrl = uploadResponseMap['url'] ?? uploadResponseMap['fileUrl'] ?? uploadResponseMap['path']; 
             }

             // Fix relative path if needed
             if (profilePicUrl != null && !profilePicUrl!.startsWith('http')) {
                // If it's a relative path like 'public\uploads\file.jpg' or 'public/uploads/file.jpg'
                // We need to ensure it uses forward slashes and starts with / if needed (or not, depending on backend)
                // Backend serves /public -> public folder.
                // If path is 'public/uploads/file.jpg', URL should be 'baseUrl/public/uploads/file.jpg'? 
                // Wait, app.js says: app.use('/public', express.static(... 'public'))
                // So http://host/public/file.jpg maps to public/file.jpg?
                // Or http://host/public/uploads/file.jpg maps to public/uploads/file.jpg?
                // Let's assume we just need to join baseUrl and the clean path.
                
                String cleanPath = profilePicUrl!.replaceAll('\\', '/');
                if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
                
                // If the path starts with 'public/', and the static route is also '/public', it fits.
                // EndPoints.baseUrl usually ends with /api. We need the root host.
                // EndPoints.baseUrl is https://api-babyland.duckdns.org/api
                // We need https://api-babyland.duckdns.org/
                
                final uri = Uri.parse(EndPoints.baseUrl);
                final rootUrl = "${uri.scheme}://${uri.host}"; // No port if standard, or include if exists
                
                // Construct full URL
                // If cleanPath indicates 'public/...' then we append it to root?
                // app.use('/public', ...) means /public route serves files.
                profilePicUrl = "$rootUrl/$cleanPath";
             }
             pt("Constructed Profile Pic URL: $profilePicUrl");
        } 
        
        if (success && profilePicUrl != null) {
             // Success!
        } else {
          // If upload fails, just show error and return, or proceed without image?
          // Usually better to fail fast.
          String errorMsg = message ?? "Unknown error (Success=$success)";
          if(success && profilePicUrl == null) errorMsg = "Upload successful but no URL found in response.";
          
          updateProfile(ApiResponse.error("Image upload failed: $errorMsg"));
          AppPopUp.showToast(message: "Image upload failed: $errorMsg");
          return; 
        }
      }

    // 2. Prepare data for Profile Update
    // Send conditions as-is: selected = true, unselected = false
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
      "email": email, // Keeping email, though API might ignore/get from token
      "phone": phone,
      "weight": weight,
      "medicalHistory": medicalHistory,
      "conditions": conditionsMap, // Send as Map (JSON)
    };

    if (profilePicUrl != null) {
      data['profilePic'] = profilePicUrl; // Key from GET response is 'profilePic'
    }

      final value = await repository.updateUserProfile(data);
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