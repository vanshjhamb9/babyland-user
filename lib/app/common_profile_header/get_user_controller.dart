import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/response/api_response.dart';

class GetUserProvider extends ChangeNotifier{
  ApiResponse<GetUserModel>? _userData = ApiResponse.completed(null);
  ApiResponse<GetUserModel>? get userData => _userData;

  void setUserData(ApiResponse<GetUserModel> response) {
    _userData = response;
    notifyListeners();
  }

  Future<void> getUser() async {
    setUserData(ApiResponse.loading());
    notifyListeners();

    await repository.getUser().then((value) {
      if (value.success == true) {
        setUserData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
        // AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        // Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
      }
      if(value.success == false) {
        setUserData(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setUserData(ApiResponse.error(error.toString()));
      notifyListeners();
      // AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
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
    required Map<String, bool> conditions,
    File? profileImage,
  }) async {
    updateProfile(ApiResponse.loading());
    notifyListeners();

    // Send conditions as-is: selected = true, unselected = false
    Map<String, dynamic> data = {
      "name": name,
      "email": userData?.data?.user?.user?.email ?? "",
      "conditions": {
        "PCOS": conditions["PCOS"] ?? false,
        "PMS": conditions["PMS"] ?? false,
        "Endometriosis": conditions["Endometriosis"] ?? false,
        "ThyroidIssues": conditions["Thyroid Issues"] ?? false,
        "Diabetes": conditions["Diabetes"] ?? false,
        "Hypertension": conditions["Hypertension"] ?? false,
      },
    };

    // Optionally include profileImage if API supports it
    // if (profileImage != null) {
    //   data['profileImage'] = profileImage;
    // }

    try {
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
    } catch (e) {
      updateProfile(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Failed to update profile: $e");
    }
    notifyListeners();
  }


}