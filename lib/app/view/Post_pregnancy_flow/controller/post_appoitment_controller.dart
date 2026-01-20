import 'package:babyland/app/controller/pregnancy_flow/model/appoinment_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/communities_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/pregnancy_data_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controller/pregnancy_flow/model/addAppointment_data_model.dart';

class PostAppointmentController extends ChangeNotifier{

  bool isReminderEnabled = false;

  final dateController = TextEditingController();
  final titleController = TextEditingController();
  final timerController = TextEditingController();


  ////////////////// addAppointment api//////////////

  ApiResponse<AddAppointment_Data_Model>? _addAppointmentApiData = ApiResponse.completed(null);
  ApiResponse<AddAppointment_Data_Model>? get addAppointmentApiData => _addAppointmentApiData;

  void setReminderEnabled(bool value) {
    isReminderEnabled = value;
    notifyListeners();
  }

  void setAddAppointmentApiData(ApiResponse<AddAppointment_Data_Model> response) {
    _addAppointmentApiData = response;
    notifyListeners();
  }


  String formatApiDate(String isoDate) {
    try {
      DateTime dateTime = DateTime.parse(isoDate);
      return DateFormat('EEEE, MMMM d').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> addAppointmentApi() async {
    setLoading(true);

    setAddAppointmentApiData(ApiResponse.loading());

    final data = {
      "title": titleController.text.trim().toString(),
      "date": formatDateForApi(dateController.text.trim().toString()),
      "time": timerController.text.trim().toString(),
      "reminder": isReminderEnabled,
      "notes": "",
    };

    pt("this is a data for api  $data");

    try {
      final value = await repository.addAppointmentApiPost(data);

      if (value.success == true) {
        setAddAppointmentApiData(ApiResponse.completed(value));

        pt(name: "response", "${value.message}");

        AppPopUp.showToast(message: "Appointment Booked! You will get notified.");
        if (navigatorKey.currentContext != null) {

          Navigator.pop(navigatorKey.currentContext!,true);
        }

        titleController.clear();
        dateController.clear();
        timerController.clear();

      } else {
        setAddAppointmentApiData(ApiResponse.error(value.message ?? "Login failed"));
        AppPopUp.showToast(message: value.message ?? "Login failed");
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setAddAppointmentApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoading(false);
    }
  }



////////////// get Appointment data here////////////////
  ApiResponse<Appointment_Data_Model>? _appointmentApiData = ApiResponse.completed(null);
  ApiResponse<Appointment_Data_Model>? get appointmentApiData => _appointmentApiData;

  bool _isLoadingData = false;
  bool get isLoadingData => _isLoadingData;

  void setLoadingData(bool loading) {
    _isLoadingData = loading;
    notifyListeners();
  }

  void setAppointmentApiData(ApiResponse<Appointment_Data_Model> response) {
    _appointmentApiData = response;
    notifyListeners();
  }

  Future<void> getAppointmentApi() async {
    setLoadingData(true);

    setAddAppointmentApiData(ApiResponse.loading());

    try {
      final value = await repository.getAppointmentDataApiPost();

      if (value.success == true) {
        setAppointmentApiData(ApiResponse.completed(value));

        pt(name: "response", "${value.data}");

      } else {
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setAppointmentApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoadingData(false);
    }
  }


  /////////////// get pregnancy data here /////////////

  ApiResponse<PregnancyDashboardModel>? _pregnancyApiData = ApiResponse.completed(null);
  ApiResponse<PregnancyDashboardModel>? get pregnancyApiData => _pregnancyApiData;

  bool _isLoadingPreg = false;
  bool get isLoadingPreg => _isLoadingPreg;

  void setLoadingPreg(bool loading) {
    _isLoadingPreg = loading;
    notifyListeners();
  }

  void setPregnancyApiData(ApiResponse<PregnancyDashboardModel> response) {
    _pregnancyApiData = response;
    notifyListeners();
  }

  Future<void> getPregnancyApiData() async {
    setLoadingPreg(true);

    setPregnancyApiData(ApiResponse.loading());

    try {
      final value = await repository.getPregnancyDataApi();

      if (value.success == true) {
        setPregnancyApiData(ApiResponse.completed(value));

        pt(name: "response", "${value.data}");

      } else {
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setPregnancyApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoadingPreg(false);
    }
  }



  /////////////// get communities data here /////////////

  ApiResponse<Communities_Data_Model>? _communitiesApiData = ApiResponse.completed(null);
  ApiResponse<Communities_Data_Model>? get communitiesApiData => _communitiesApiData;

  bool _isLoadingComm = false;
  bool get isLoadingComm => _isLoadingComm;

  void setLoadingComm(bool loading) {
    _isLoadingComm = loading;
    notifyListeners();
  }

  void setCommunitiesApiData(ApiResponse<Communities_Data_Model> response) {
    _communitiesApiData = response;
    notifyListeners();
  }

  Future<void> getCommunitiesData() async {
    setLoadingComm(true);

    setCommunitiesApiData(ApiResponse.loading());

    try {
      final value = await repository.getCommunitiesDataApi();

      if (value.success == true) {
        setCommunitiesApiData(ApiResponse.completed(value));

        pt(name: "response", "${value.data?.posts?[0].comments}");

      } else {
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setCommunitiesApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoadingComm(false);
    }
  }


}
// import 'package:babyland/app/controller/pregnancy_flow/pregnancy_info_model.dart';
// import 'package:babyland/app/data/response/api_response.dart';
// import 'package:babyland/app/data/storage/secure_storage.dart';
// import 'package:babyland/app/routes/app_routes.dart';
// import 'package:babyland/app/widgets/app_popup.dart';
// import 'package:babyland/app/widgets/print.dart';
// import 'package:babyland/app/widgets/validation.dart';
// import 'package:babyland/main.dart';
// import 'package:flutter/cupertino.dart';
// import 'model/addAppointment_data_model.dart';
//
// class PregnancyController extends ChangeNotifier{
//
//   bool isReminderEnabled = false;
//
//   final dateController = TextEditingController();
//   final titleController = TextEditingController();
//   final timerController = TextEditingController();
//
// //--------------------------
//   ApiResponse<PregnancyInfoModel>? _pregnancyInfoApiData = ApiResponse.completed(null);
//   ApiResponse<PregnancyInfoModel>? get pregnancyInfoApiData => _pregnancyInfoApiData;
//
//   void setPregnancyData(ApiResponse<PregnancyInfoModel> response) {
//     _pregnancyInfoApiData = response;
//     notifyListeners();
//   }
//
//   Future<void> pregnancyInfo() async {
//     setPregnancyData(ApiResponse.loading());
//     notifyListeners();
//     final userId = await SecureStorage.getUserId();
//     final data = {
//       "userId": userId,
//       if(dateController.text.isNotEmpty) "pregnancyStartDate": formatDateForApi(dateController.text),
//       // "currentWeek": 5,
//       // "trimester": 1,
//       // "expectedDueDate": "2025-11-12",
//       // "fetalGrowthStage": "string",
//       // "dailyLogs": [
//       //   {
//       //     "date": "2025-10-09",
//       //     "mood": "Good",
//       //     "symptoms": [
//       //       "nausea",
//       //       "fatigue"
//       //     ],
//       //     "stressLevel": 2,
//       //     "anxietyLevel": 1,
//       //     "notes": "Felt slightly tired today",
//       //     "sleepQuality": 4
//       //   }
//       // ],
//       // "appointments": [
//       //   {
//       //     "title": "OB-GYN Checkup",
//       //     "date": "2025-10-15",
//       //     "time": "10:30 AM",
//       //     "reminder": false,
//       //     "notes": "Bring previous test reports"
//       //   }
//       // ],
//       // "aiInsights": [
//       //   {
//       //     "date": "2025-11-12T18:28:46.974Z",
//       //     "nutritionTips": [
//       //       "string"
//       //     ],
//       //     "mentalHealthTips": [
//       //       "string"
//       //     ],
//       //     "physicalActivityTips": [
//       //       "string"
//       //     ],
//       //     "fetalGrowthUpdate": "string",
//       //     "riskAssessment": {
//       //       "riskLevel": "Low",
//       //       "notes": "string"
//       //     },
//       //     "aiSummary": "string"
//       //   }
//       // ],
//       // "predictions": {
//       //   "dueDate": "2025-11-12",
//       //   "trimesterProgress": 0,
//       //   "fetalSize": "string",
//       //   "nextMilestone": "string"
//       // },
//       // "notes": "string"
//     };
//
//     try {
//       await repository.pregnancyInfo(data).then((value) {
//         if (value.success == true) {
//           setPregnancyData(ApiResponse.completed(value));
//           Navigator.pushNamedAndRemoveUntil(navigatorKey.currentContext!, AppRoutes.navbarView,(route) => false,);
//           pt(name: "response", "${value.message}");
//         }
//         if(value.success == false) {
//           setPregnancyData(ApiResponse.error(value.message ?? "Something went wrong!"));
//           AppPopUp.showToast(message: value.message ?? "Something went wrong!");
//         }
//       },);
//       notifyListeners();
//     } catch (e, s) {
//       pt("Error in pregnancyInfo: $e\n$s");
//       setPregnancyData(ApiResponse.error(e.toString()));
//       notifyListeners();
//       AppPopUp.showToast(message: "Something went wrong. Please try again.");
//     }
//   }
//
//
//   ////////////////// addAppointment api//////////////
//
//   ApiResponse<AddAppointment_Data_Model>? _addAppointmentApiData = ApiResponse.completed(null);
//   ApiResponse<AddAppointment_Data_Model>? get addAppointmentApiData => _addAppointmentApiData;
//
//   void setReminderEnabled(bool value) {
//     isReminderEnabled = value;
//     notifyListeners();
//   }
//
//   void setAddAppointmentApiData(ApiResponse<AddAppointment_Data_Model> response) {
//     _addAppointmentApiData = response;
//     notifyListeners();
//   }
//
//   Future<void> addAppointmentApi() async {
//     setAddAppointmentApiData(ApiResponse.loading());
//
//     final data = {
//       "title": titleController.text.trim(),
//       "date": dateController.text.trim(),
//       "time": timerController.text.trim(),
//       "reminder": isReminderEnabled,
//       "notes": "passwordController.text.trim()",
//     };
//
//     pt("this is a data for api  $data");
//
//     try {
//       final value = await repository.addAppointmentApi(data);
//
//       if (value.success == true) {
//         setAddAppointmentApiData(ApiResponse.completed(value));
//
//         pt(name: "response", "${value.message}");
//
//         AppPopUp.showToast(message: "Appointment Booked! You will get notified.");
//
//
//       } else {
//         setAddAppointmentApiData(ApiResponse.error(value.message ?? "Login failed"));
//         AppPopUp.showToast(message: value.message ?? "Login failed");
//       }
//     } catch (e, s) {
//       pt("Error in login: $e\n$s");
//       setAddAppointmentApiData(ApiResponse.error(e.toString()));
//       AppPopUp.showToast(message: "Something went wrong. Please try again.");
//     }
//   }
//
//
//
// }