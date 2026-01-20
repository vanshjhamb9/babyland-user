import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../routes/app_routes.dart';
import '../../widgets/print.dart';
import 'model/postpartums_add_model.dart';
import 'model/recovery_progress_model.dart';

class PostpregnancyProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners();
  }

  Set<int> _selectedIndexes = {};

  Set<int> get selectedIndexes => _selectedIndexes;

  void toggleRecoveryIndex(int index) {
    if (_selectedIndexes.contains(index)) {
      _selectedIndexes.remove(index);
    } else {
      _selectedIndexes.add(index);
    }
    notifyListeners();
  }

  void clearSelectedIndexes() {
    _selectedIndexes.clear();
    notifyListeners();
  }

  String selectedDeliveryType = "";
  void onDeliveryTypeSelect(String type) {
    selectedDeliveryType = type;
    pt("selectedDeliveryType $selectedDeliveryType");
    notifyListeners();
  }
  String? selectedGender;

  final dateController = TextEditingController();
  final dobController = TextEditingController();
  final babyNameController = TextEditingController();

  ApiResponse<PostpartumsAddModel>? _postPregnancyInfoApiData = ApiResponse.completed(null);
  ApiResponse<PostpartumsAddModel>? get postPregnancyInfoApiData => _postPregnancyInfoApiData;

  void setPregnancyData(ApiResponse<PostpartumsAddModel> response) {
    _postPregnancyInfoApiData = response;
    notifyListeners();
  }

    Future<void> pregnancyInfo() async {
    setPregnancyData(ApiResponse.loading());
    notifyListeners();
    final userId = await SecureStorage.getUserId();

    final data = {
      "userId": userId,
      "deliveryDate": formatDateForApiYMD(dateController.text),
      "deliveryType": selectedDeliveryType,
      "babyDetails": {
        "name": babyNameController.text,
        "date": formatDateForApiYMD(dobController.text),
        "gender": selectedGender?.toLowerCase() == "boy" ? "Male" : selectedGender?.toLowerCase() == "girl" ? "Female": "Prefer not to say",
      }
//   "dailyLogs": [
//     {
//       "date": "2025-10-09",
//       "mood": "Good",
//       "symptoms": [
//         "nausea",
//         "fatigue"
//       ],
//       "stressLevel": 2,
//       "anxietyLevel": 1,
//       "notes": "Felt slightly tired today",
//       "sleepQuality": 4
//     }
//   ],
//   "feedingSchedule": [
//     {
//       "time": "2025-11-13T15:46:37.311Z",
//       "type": "Breastfeeding",
//       "side": "Both",
//       "durationMinutes": 0,
//       "quantity": "100ml",
//       "notes": "string"
//     }
//   ],
//   "recoveryChecklist": [
//     {
//       "task": "string",
//       "dateAssigned": "2025-11-13",
//       "dueDate": "2025-11-13",
//       "completed": false,
//       "dateCompleted": "2025-11-13"
//     }
//   ],
//   "appointments": [
//     {
//       "title": "OB-GYN Checkup",
//       "date": "2025-10-15",
//       "time": "10:30 AM",
//       "reminder": false,
//       "notes": "Bring previous test reports"
//     }
//   ],
//   "aiPredictions": [
//     {
//       "date": "2025-11-13",
//       "modelOutput": {
//         "recoveryScore": 0,
//         "depressionRisk": "Low",
//         "fatigueLevel": "Low",
//         "insights": "string",
//         "recommendations": [
//           "string"
//         ]
//       }
//     }
//   ]
    };

    pt("data body==>> $data");

      await repository.postpartumsAdd(data).then((value) {
        if (value.success == true) {
          setPregnancyData(ApiResponse.completed(value));
          pt(name: "response", "${value.message}");
          Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
        }
        if(value.success == false) {
          setPregnancyData(ApiResponse.error(value.message ?? "Something went wrong!"));
          if(value.message == "Postpartum tracker already exists for this user"){
            Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
          }
          AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        }
        notifyListeners();
      },).onError((error, stackTrace) {
        pt("Error in pregnancyInfo: $error\n$stackTrace");
        setPregnancyData(ApiResponse.error(error.toString()));
        notifyListeners();
        AppPopUp.showToast(message: "Something went wrong. Please try again.");
        notifyListeners();
      },);
    }

  //--------------------------------------------------------------------------------------------
  ApiResponse<CommonResponseModel>? _postpartumsLogsAdd = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get postpartumsLogsAdd => _postpartumsLogsAdd;

  void postpartumsLogsAddData(ApiResponse<CommonResponseModel> response) {
    _postpartumsLogsAdd = response;
    notifyListeners();
  }

    Future<void> postpartumsLogsAddApi({required String mood,
      required String date, required List<String> symptoms,
      required var stressLevel, required var anxietyLevel,required String notes,}) async {
      postpartumsLogsAddData(ApiResponse.loading());
    notifyListeners();
    // final userId = await SecureStorage.getUserId();

      Map<String, dynamic>  data = {
        "date": formatDateForApi(date),
        "mood": mood,
        "symptoms": symptoms,
        "stressLevel": stressLevel,
        "anxietyLevel": anxietyLevel,
        "notes": notes,
        // "sleepQuality": 4
      };

    pt("data body==>> $data");
      await repository.postpartumsLogsAdd(data).then((value) {
        if (value.success == true) {
          postpartumsLogsAddData(ApiResponse.completed(value));
          pt(name: "response", "${value.message}");
          AppPopUp.showToast(message: value.message ?? "Something went wrong!");
          Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
        }
        if(value.success == false) {
          postpartumsLogsAddData(ApiResponse.error(value.message ?? "Something went wrong!"));
          // if(value.message == "Postpartum tracker already exists for this user"){
          //   Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
          // }
          // AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        }
        notifyListeners();
      },).onError((error, stackTrace) {
        pt("Error in pregnancyInfo: $error\n$stackTrace");
        postpartumsLogsAddData(ApiResponse.error(error.toString()));
        notifyListeners();
        AppPopUp.showToast(message: "Something went wrong. Please try again.");
        notifyListeners();
      },);
    }
  //--------------------------------------------------------------------------------------------
  // ApiResponse<CommonResponseModel>? _appAppointmentData = ApiResponse.completed(null);
  // ApiResponse<CommonResponseModel>? get appAppointmentData => _appAppointmentData;
  //
  // void appointmentData(ApiResponse<CommonResponseModel> response) {
  //   _appAppointmentData = response;
  //   notifyListeners();
  // }
  //
  //   Future<void> appointmentAddApi() async {
  //     appointmentData(ApiResponse.loading());
  //   notifyListeners();
  //   final userId = await SecureStorage.getUserId();
  //
  //     Map<String, dynamic>  data = {
  //     "title": "OB-GYN Checkup",
  //     "date": "2025-10-15",
  //     "time": "10:30 AM",
  //     "reminder": false,
  //     "notes": "Bring previous test reports"
  //   };
  //
  //   pt("data body==>> $data");
  //
  //     await repository.postpartumsDoctorAppointmentAdd(data).then((value) {
  //       if (value.success == true) {
  //         appointmentData(ApiResponse.completed(value));
  //         pt(name: "response", "${value.message}");
  //         Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
  //       }
  //       if(value.success == false) {
  //         appointmentData(ApiResponse.error(value.message ?? "Something went wrong!"));
  //         if(value.message == "Postpartum tracker already exists for this user"){
  //           Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
  //         }
  //         AppPopUp.showToast(message: value.message ?? "Something went wrong!");
  //       }
  //       notifyListeners();
  //     },).onError((error, stackTrace) {
  //       pt("Error in pregnancyInfo: $error\n$stackTrace");
  //       appointmentData(ApiResponse.error(error.toString()));
  //       notifyListeners();
  //       AppPopUp.showToast(message: "Something went wrong. Please try again.");
  //       notifyListeners();
  //     },);
  //   }


  //--------------------------get feeding

  ApiResponse<CommonResponseModel>? _feedingData = ApiResponse<CommonResponseModel>.completed(null);
  ApiResponse<CommonResponseModel>? get feedingData => _feedingData;

  void setFeedingApi(ApiResponse<CommonResponseModel> response) {
    _feedingData = response;
    notifyListeners();
  }

  Future<void> getFeedingApi() async {
    setFeedingApi(ApiResponse.loading());

    await repository.getFeeding().then((value) {
      if (value.success == true) {
        setFeedingApi(ApiResponse.completed(value));
      } else {
        setFeedingApi(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
    }).onError((error, stackTrace) {
      setFeedingApi(ApiResponse.error(error.toString()));
    });
  }



 /// --------------------------set password
  ApiResponse<PostpartumsAddModel>? _recoveryTaskApiData = ApiResponse.completed(null);
  ApiResponse<PostpartumsAddModel>? get recoveryTaskApiData => _recoveryTaskApiData;

  void setRecoveryTaskApiData(ApiResponse<PostpartumsAddModel> response) {
    _recoveryTaskApiData = response;
    notifyListeners();
  }

  Future<bool> recoveryTaskApi({
    required bool? completed,
    required  String? id,
    required String? task,
    required String dateAssigned,
    required String dueDate,
    required String dateCompleted,
  }) async {
    setRecoveryTaskApiData(ApiResponse.loading());

    final data = {
      "task": task,
      "dateAssigned":dateAssigned,
      "dueDate": dueDate,
      "completed": completed,
      "dateCompleted": dateCompleted
    };

    pt(("this is the api post data $data"));

    try {
      final value = await repository.recoveryTask(data, id);

      if (value.success == true) {
        setRecoveryTaskApiData(ApiResponse.completed(value));
        getRecoveryTaskApi(isRefresh: false);
        pt(name: "response", "${value.message}");

        AppPopUp.showToast(message: value.message ?? "");

        return true;
      } else {
        setRecoveryTaskApiData(ApiResponse.error(value.message));
        AppPopUp.showToast(message: value.message ?? "Please try again.");

        return false;
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setRecoveryTaskApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");

      return false;
    }
  }



 /// --------------------------get recovery
  ApiResponse<RecoveryProgressModel>? _getRecoveryApiData = ApiResponse.completed(null);
  ApiResponse<RecoveryProgressModel>? get getRecoveryApiData => _getRecoveryApiData;

  void setGetRecoveryTaskApiData(ApiResponse<RecoveryProgressModel> response) {
    _getRecoveryApiData = response;
    notifyListeners();
  }

  Future<bool> getRecoveryTaskApi({bool? isRefresh = true}) async {
    if(isRefresh == true) {
      setGetRecoveryTaskApiData(ApiResponse.loading());
    }
    final data = {
      "date":DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc()),
    };

    pt(("this is the api post data $data"));

    try {
      final value = await repository.getRecoveryTask(data);

      if (value.success == true) {
        setGetRecoveryTaskApiData(ApiResponse.completed(value));

        return true;
      } else {
        setGetRecoveryTaskApiData(ApiResponse.error(value.message));
        AppPopUp.showToast(message: value.message ?? "Please try again.");
        return false;
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setGetRecoveryTaskApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");

      return false;
    }
  }



}
