import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/constants/flow.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/appoinment_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/communities_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/pregnancy_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_info_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/navbar/pregnancy/navbar.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/addAppointment_data_model.dart';
import 'model/postsenddatamodel.dart';

class PregnancyController extends ChangeNotifier{

  bool isReminderEnabled = false;

  final dateController = TextEditingController();
  final titleController = TextEditingController();
  final timerController = TextEditingController();

//--------------------------
  ApiResponse<PregnancyInfoModel>? _pregnancyInfoApiData = ApiResponse.completed(null);
  ApiResponse<PregnancyInfoModel>? get pregnancyInfoApiData => _pregnancyInfoApiData;

  void setPregnancyData(ApiResponse<PregnancyInfoModel> response) {
    _pregnancyInfoApiData = response;
    notifyListeners();
  }

  Future<void> pregnancyInfo() async {
    setPregnancyData(ApiResponse.loading());
    notifyListeners();
    final userId = await SecureStorage.getUserId();
    final data = {
      "userId": userId,
      if(dateController.text.isNotEmpty) "pregnancyStartDate": formatDateForApi(dateController.text),
    };

    try {
      await repository.pregnancyInfo(data).then((value) {
        if (value.success == true) {
          setPregnancyData(ApiResponse.completed(value));
          Navigator.pushAndRemoveUntil(navigatorKey.currentContext!, MaterialPageRoute(builder: (context) => NavbarView(flow: FlowType.pregnancy),), (route) => false);
          // Navigator.pushNamedAndRemoveUntil(navigatorKey.currentContext!, AppRoutes.navbarView,(route) => false,);
          pt(name: "response", "${value.message}");
        }
        if(value.success == false) {
          setPregnancyData(ApiResponse.error(value.message ?? "Something went wrong!"));
          AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        }
      },);
      notifyListeners();
    } catch (e, s) {
      pt("Error in pregnancyInfo: $e\n$s");
      setPregnancyData(ApiResponse.error(e.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }
  }


  ////////////////// add daily logs api//////////////

  ApiResponse<CommonResponseModel>? _addDailyLogsApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addDailyLogsApiData => _addDailyLogsApiData;

  void setAddDailyLogsApiApiData(ApiResponse<CommonResponseModel> response) {
    _addDailyLogsApiData = response;
    notifyListeners();
  }
  Future<void> addDailyLogsApiPregnancy({required String mood,
    required String date, required List<String> symptoms,
    required var stressLevel,required var anxietyLevel,required String notes,}) async {
    setAddDailyLogsApiApiData(ApiResponse.loading());

    Map<String, dynamic>  data = {
      "date": formatDateForApi(date),
      "mood": mood,
      "symptoms": symptoms,
      "stressLevel": stressLevel,
      "anxietyLevel": anxietyLevel,
      "notes": notes,
      // "sleepQuality": 4
    };
    repository.postPregnancyDataApi(data: data).then((value) {
      if(value.success == true){
        setAddDailyLogsApiApiData(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "");
        Navigator.pop(navigatorKey.currentContext!);
        date = "";
        mood = "";
        symptoms.clear();
        notes = "";
      }else if(value.message == "You can only add a new daily log after 24 hours. Please wait 24 hour(s)."){
        setAddDailyLogsApiApiData(ApiResponse.completed(value));
        date = "";
        mood = "";
        symptoms.clear();
        notes = "";
        AppPopUp.showToast(message: value.message ?? "");
        Navigator.pop(navigatorKey.currentContext!);
      }else{
        setAddDailyLogsApiApiData(ApiResponse.error(value.message));
      }
    },).onError((error, stackTrace) {
      setAddDailyLogsApiApiData(ApiResponse.error(error.toString()));
      pt("err $error");
    },);

  }


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
      // Format as "Tuesday, October 15" or any desired format
      return DateFormat('EEEE, MMMM d').format(dateTime);
    } catch (e) {
      // If parsing fails, return original string or empty
      return isoDate;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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
      final value = await repository.addAppointmentApi(data);

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
      final value = await repository.getAppointmentDataApi();

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

  Future<void> getCommunitiesData({bool load = true}) async {
    if(load == true){
      setLoadingComm(true);
      setCommunitiesApiData(ApiResponse.loading());
    }

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


  ///////// like api //////////////

  ApiResponse<CommonResponseModel>? _likeApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get likeApiData => _likeApiData;


  void setLikeApiData(ApiResponse<CommonResponseModel> response) {
    _likeApiData = response;
    notifyListeners();
  }


  Future<void> lieApi({required String likeId}) async {

    setLikeApiData(ApiResponse.loading());

    try {
      final value = await repository.likeApiPost(likeId);

      if (value.success == true) {
        setLikeApiData(ApiResponse.completed(value));
        AppPopUp.showToast(message: "Appointment Booked! You will get notified.");
        getCommunitiesData(load: false);
      } else {
        setLikeApiData(ApiResponse.error(value.message ?? "like failed"));
        AppPopUp.showToast(message: value.message ?? "like failed");
      }
    } catch (e, s) {
      pt("Error in like api: $e\n$s");
      setLikeApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }
  }



  ///////// post api //////////////

  ApiResponse<PostSendDataModel>? _postData = ApiResponse.completed(null);
  ApiResponse<PostSendDataModel>? get postData => _postData;

  TextEditingController msgController = TextEditingController();


  void setPostApiData(ApiResponse<PostSendDataModel> response) {
    _postData = response;
    notifyListeners();
  }


  Future<void> postCreateApi({required String msg}) async {

    setPostApiData(ApiResponse.loading());

    try {

      var data ={
        "message":msg.toString()
      };

      final value = await repository.postSendApi(data);

      if (value.success == true) {
        setPostApiData(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message.toString());
        getCommunitiesData(load: false);
      } else {
        setPostApiData(ApiResponse.error(value.message ?? "post failed"));
        AppPopUp.showToast(message: value.message ?? "post failed");
      }
    } catch (e, s) {
      pt("Error in like api: $e\n$s");
      setPostApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }
  }

}
