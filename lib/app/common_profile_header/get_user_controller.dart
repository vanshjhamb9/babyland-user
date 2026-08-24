import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/response/api_response.dart';
import '../data/storage/user_local_data.dart';

class GetUserProvider extends ChangeNotifier {
  ApiResponse<GetUserModel>? _userData = ApiResponse.completed(null);
  ApiResponse<GetUserModel>? get userData => _userData;

  static const Duration _cacheTtl = Duration(seconds: 15);
  DateTime? _lastSuccessAt;
  Future<void>? _inFlight;

  bool get _isCacheFresh =>
      _lastSuccessAt != null &&
      DateTime.now().difference(_lastSuccessAt!) < _cacheTtl;

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

  Future<void> getUser({bool force = false}) {
    if (!force && _isCacheFresh) {
      pt("getUser() skipped - cache fresh (${_lastSuccessAt!.difference(DateTime.now()).inSeconds}s)");
      return Future.value();
    }
    if (_inFlight != null && !force) {
      pt("getUser() coalesced into in-flight request");
      return _inFlight!;
    }
    final future = _fetchUser();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _fetchUser() async {
    pt("getUser() called - Setting loading");
    if (_userData != null && _userData!.data != null) {
      _userData = ApiResponse.loading(data: _userData!.data);
    } else {
      setUserData(ApiResponse.loading());
    }
    notifyListeners();

    await repository.getUser().then((value) async {
      pt("[USER-AUDIT] getUser() response: success=${value.success}");
      pt("[USER-AUDIT] message: ${value.message}");
      pt("[USER-AUDIT] user: ${value.user}");
      if (value.user?.user != null) {
        final u = value.user!.user!;
        pt("[USER-AUDIT] user.sId: ${u.sId}");
        pt("[USER-AUDIT] user.phone: ${u.phone}");
        pt("[USER-AUDIT] user.lastPeriodStartDate: ${u.lastPeriodStartDate}");
        pt("[USER-AUDIT] user.cycleType: ${u.cycleType}");
        pt("[USER-AUDIT] user.email: ${u.email}");
      }
      if (value.success == true) {
        _lastSuccessAt = DateTime.now();
        setUserData(ApiResponse.completed(value));

        final userObj = value.user;
        final user = userObj?.user;
        if (user != null) {
          if (user.sId != null && user.sId!.isNotEmpty) {
            await SecureStorage.saveUserId(user.sId!);
          }

          final phone = user.phone?.trim();
          if (phone != null && phone.isNotEmpty) {
            await UserLocalData.clearNeedsPhoneProfile();
          }

          final lpd = user.lastPeriodStartDate?.trim();
          final returning = ExistingAccount.isReturning(
            user,
            profileCompletion: userObj?.profileCompletion,
          );
          if (returning ||
              (lpd != null && lpd.isNotEmpty && lpd != 'null')) {
            pt(
              "[USER-AUDIT] existing account (stage=${user.stage} "
              "completion=${userObj?.profileCompletion} lpd='$lpd') — "
              "clearing needsBasicProfile",
            );
            await UserLocalData.clearNeedsBasicProfile();
          } else {
            pt("[USER-AUDIT] no stage/profile data — keeping needsBasicProfile");
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
           String? stage = user.stage;
           pt("Syncing data. Backend cycleType: $cType, stage: $stage");

           // Minimal sync for Splash screen routing.
           // `stage` is the source of truth when set; fall back to cycleType.
           final isPost = stage == "postpregnancy" || cType == "post_pregnancy";
           final isPreg = stage == "pregnancy" || cType == "pregnancy";

           if (isPost) {
              UserLocalData.saveStep("2");
           } else if (isPreg) {
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
      pt("[USER-AUDIT] ❌ Error in getUser: $error");
      pt("[USER-AUDIT] Stack trace: $stackTrace");
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

      await getUser(force: true);
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

  Future<void>? _profilePhotoUploadInFlight;

  void updateProfile(ApiResponse<CommonResponseModel> response) {
    _updateProfileData = response;
    notifyListeners();
  }

  /// Minimal multipart payload for profile photo uploads.
  /// Matches the working shape from test_profile_update.dart: name + phone + photo.
  Map<String, dynamic> buildProfilePhotoMultipartPayload({String? nameOverride}) {
    final user = userData?.data?.user?.user;
    final payload = <String, dynamic>{};

    final name = (nameOverride ?? user?.name)?.trim();
    payload['name'] = (name != null && name.isNotEmpty) ? name : 'User';

    final phone = user?.phone?.trim();
    if (phone != null && phone.isNotEmpty && phone != 'null') {
      payload['phone'] = phone;
    }

    return payload;
  }

  /// Seeds JSON profile-update requests from cached user data.
  Map<String, dynamic> buildProfileUpdatePayload({String? nameOverride}) {
    final user = userData?.data?.user?.user;
    final payload = <String, dynamic>{};

    final name = (nameOverride ?? user?.name)?.trim();
    payload['name'] = (name != null && name.isNotEmpty) ? name : 'User';

    void putIfPresent(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty && v != 'null') {
        payload[key] = v;
      }
    }

    if (user != null) {
      putIfPresent('email', user.email);
      putIfPresent('phone', user.phone);
      putIfPresent('stage', user.stage);
      putIfPresent('weight', user.weight);
      putIfPresent('age', user.age);
      putIfPresent('height', user.height);
      putIfPresent('medicalHistory', user.medicalHistory);
      putIfPresent('lastPeriodStartDate', user.lastPeriodStartDate);
      putIfPresent('averagePeriodLengthDays', user.averagePeriodLengthDays);
      putIfPresent('cycleLengthDays', user.cycleLengthDays);
      putIfPresent('pregnancyStartDate', user.pregnancyStartDate);

      final cycleType = user.cycleType?.trim();
      if (cycleType != null && cycleType.isNotEmpty) {
        payload['cycleType'] = cycleType;
      }
      if (user.conditions != null) {
        payload['conditions'] = user.conditions!.toJson();
      }
    }

    return payload;
  }

  String _profileUpdateErrorMessage(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
      switch (error.response?.statusCode) {
        case 413:
          return 'Image is too large. Try a smaller photo.';
        case 500:
        case 502:
          return 'Photo upload failed. Stay on this screen and try again.';
        default:
          break;
      }
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Could not update profile. Please try again.';
  }

  Future<void> _runWithUploadLoader(Future<void> Function() action) async {
    final nav = navigatorKey.currentContext;
    var dialogOpen = false;
    if (nav != null && nav.mounted) {
      dialogOpen = true;
      showDialog<void>(
        context: nav,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Uploading photo…',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    try {
      await action();
    } finally {
      if (dialogOpen && nav != null && nav.mounted) {
        Navigator.of(nav, rootNavigator: true).pop();
      }
    }
  }

  Future<void> uploadProfilePicture(
    File profileImage, {
    bool popOnSuccess = false,
  }) async {
    if (_profilePhotoUploadInFlight != null) {
      pt('uploadProfilePicture skipped — upload already in progress');
      return _profilePhotoUploadInFlight!;
    }

    final future = _uploadProfilePictureImpl(
      profileImage,
      popOnSuccess: popOnSuccess,
    );
    _profilePhotoUploadInFlight = future;
    try {
      await future;
    } finally {
      _profilePhotoUploadInFlight = null;
    }
  }

  Future<void> _uploadProfilePictureImpl(
    File profileImage, {
    bool popOnSuccess = false,
  }) async {
    updateProfile(ApiResponse.loading());
    notifyListeners();

    await _runWithUploadLoader(() async {
      try {
        final data = buildProfilePhotoMultipartPayload();
        if (data['phone'] == null) {
          throw StateError(
            'Phone number is required before uploading a profile photo.',
          );
        }
        if (kDebugMode) {
          pt('uploadProfilePicture payload keys: ${data.keys.toList()}');
        }
        final value =
            await repository.updateUserProfile(data, profileImage: profileImage);
        if (value.success == true) {
          updateProfile(ApiResponse.completed(value));
          AppPopUp.showToast(
            message: value.message ?? 'Profile photo updated successfully!',
          );
          await getUser(force: true);
          if (popOnSuccess) {
            final nav = navigatorKey.currentContext;
            if (nav != null && nav.mounted) {
              if (Navigator.canPop(nav)) {
                Navigator.pop(nav);
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  nav,
                  AppRoutes.splashView,
                  (route) => false,
                );
              }
            }
          }
        } else {
          updateProfile(
            ApiResponse.error(value.message ?? 'Something went wrong!'),
          );
          if (value.message != null && value.message!.isNotEmpty) {
            AppPopUp.showToast(message: value.message!);
          } else {
            AppPopUp.showToast(
              message: 'Photo upload failed. Stay on this screen and try again.',
            );
          }
        }
      } on StateError catch (e) {
        updateProfile(ApiResponse.error(e.message));
        AppPopUp.showToast(message: e.message);
      } catch (e, st) {
        pt('Upload Profile Picture Error: $e $st');
        final message = _profileUpdateErrorMessage(e);
        updateProfile(ApiResponse.error(message));
        AppPopUp.showToast(message: message);
      }
      notifyListeners();
    });
  }

  Future<void> updateUserProfile({
    required String name,
    String? email,
    Map<String, bool>? conditions,
    File? profileImage,
    String? phone,
    String? weight,
    String? medicalHistory,
    String? age,
    String? height,
    bool popOnSuccess = true,
  }) async {
    if (profileImage != null && _profilePhotoUploadInFlight != null) {
      pt('updateUserProfile skipped — photo upload already in progress');
      return;
    }

    updateProfile(ApiResponse.loading());
    notifyListeners();

    try {
      if (profileImage != null) {
        await _updateUserProfileWithPhoto(
          name: name,
          email: email,
          conditions: conditions,
          profileImage: profileImage,
          phone: phone,
          weight: weight,
          medicalHistory: medicalHistory,
          age: age,
          height: height,
          popOnSuccess: popOnSuccess,
        );
        return;
      }

      final data = buildJsonProfilePayload(
        name: name,
        email: email,
        conditions: conditions,
        phone: phone,
        weight: weight,
        medicalHistory: medicalHistory,
        age: age,
        height: height,
      );

      final value = await repository.updateUserProfile(data);
      await _handleProfileUpdateResult(
        value,
        popOnSuccess: popOnSuccess,
        phone: phone,
      );
    } catch (e, st) {
      pt("Update Profile Error: $e $st");
      final message = _profileUpdateErrorMessage(e);
      updateProfile(ApiResponse.error(message));
      AppPopUp.showToast(message: message);
    }
    notifyListeners();
  }

  /// Whether a photo upload should be followed by a JSON profile update
  /// (email, conditions, weight, etc.) without re-uploading the image.
  static bool needsAdditionalJsonUpdateAfterPhoto({
    required Map<String, dynamic> jsonPayload,
    Map<String, bool>? conditions,
    String? email,
  }) {
    return jsonPayload.length > 1 ||
        conditions != null ||
        (email != null && email.trim().isNotEmpty);
  }

  Map<String, dynamic> buildJsonProfilePayload({
    required String name,
    String? email,
    Map<String, bool>? conditions,
    String? phone,
    String? weight,
    String? medicalHistory,
    String? age,
    String? height,
  }) {
    final data = <String, dynamic>{'name': name};

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (conditions != null) {
      data['conditions'] = {
        'PCOS': conditions['PCOS'] ?? false,
        'PMS': conditions['PMS'] ?? false,
        'Endometriosis': conditions['Endometriosis'] ?? false,
        'ThyroidIssues': conditions['Thyroid Issues'] ?? false,
        'Diabetes': conditions['Diabetes'] ?? false,
        'Hypertension': conditions['Hypertension'] ?? false,
      };
    }

    if (phone != null && phone.trim().isNotEmpty) {
      data['phone'] = phone.trim();
    }
    if (weight != null && weight.trim().isNotEmpty) {
      data['weight'] = weight.trim();
    }
    if (medicalHistory != null && medicalHistory.trim().isNotEmpty) {
      data['medicalHistory'] = medicalHistory.trim();
    }
    if (age != null && age.trim().isNotEmpty) {
      data['age'] = age.trim();
    }
    if (height != null && height.trim().isNotEmpty) {
      data['height'] = height.trim();
    }

    return data;
  }

  Future<void> _updateUserProfileWithPhoto({
    required String name,
    String? email,
    Map<String, bool>? conditions,
    required File profileImage,
    String? phone,
    String? weight,
    String? medicalHistory,
    String? age,
    String? height,
    bool popOnSuccess = true,
  }) async {
    final photoPayload = buildProfilePhotoMultipartPayload(nameOverride: name);
    final phoneVal = phone?.trim();
    if (phoneVal != null && phoneVal.isNotEmpty) {
      photoPayload['phone'] = phoneVal;
    }
    if (photoPayload['phone'] == null) {
      throw StateError(
        'Phone number is required before uploading a profile photo.',
      );
    }

    final uploadFuture = repository.updateUserProfile(
      photoPayload,
      profileImage: profileImage,
    );
    _profilePhotoUploadInFlight = uploadFuture.then((_) {});
    final photoResult = await uploadFuture;
    _profilePhotoUploadInFlight = null;

    if (photoResult.success != true) {
      updateProfile(
        ApiResponse.error(photoResult.message ?? 'Profile photo update failed!'),
      );
      AppPopUp.showToast(
        message: photoResult.message ?? 'Profile photo update failed!',
      );
      return;
    }

    final jsonPayload = buildJsonProfilePayload(
      name: name,
      email: email,
      conditions: conditions,
      phone: phone,
      weight: weight,
      medicalHistory: medicalHistory,
      age: age,
      height: height,
    );

    // Photo already saved — update remaining text fields without re-uploading.
    jsonPayload.remove('photo');
    final hasExtraFields = needsAdditionalJsonUpdateAfterPhoto(
      jsonPayload: jsonPayload,
      conditions: conditions,
      email: email,
    );

    CommonResponseModel value = photoResult;
    if (hasExtraFields) {
      value = await repository.updateUserProfile(jsonPayload);
    }

    await _handleProfileUpdateResult(
      value,
      popOnSuccess: popOnSuccess,
      phone: phone,
      successMessage: photoResult.message ?? 'Profile updated successfully!',
    );
  }

  Future<void> _handleProfileUpdateResult(
    CommonResponseModel value, {
    required bool popOnSuccess,
    String? phone,
    String? successMessage,
  }) async {
    if (value.success == true) {
      updateProfile(ApiResponse.completed(value));
      AppPopUp.showToast(
        message: successMessage ?? value.message ?? 'Profile updated successfully!',
      );
      if (phone != null && phone.trim().isNotEmpty) {
        await UserLocalData.clearNeedsPhoneProfile();
      }
      await getUser(force: true);
      if (popOnSuccess) {
        final nav = navigatorKey.currentContext;
        if (nav != null && nav.mounted) {
          if (Navigator.canPop(nav)) {
            Navigator.pop(nav);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              nav,
              AppRoutes.splashView,
              (route) => false,
            );
          }
        }
      }
    } else {
      updateProfile(
        ApiResponse.error(value.message ?? 'Something went wrong!'),
      );
      AppPopUp.showToast(
        message: value.message ?? 'Profile update failed!',
      );
    }
  }
}