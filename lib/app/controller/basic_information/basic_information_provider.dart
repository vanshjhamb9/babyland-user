import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../main.dart';
import '../../routes/app_routes.dart';
import 'model/onboarding_completed_model.dart';

class BasicInformationProvider extends ChangeNotifier{

  final dateController = TextEditingController();
  final medicalReason = TextEditingController();

  BasicInformationProvider(){
    controllerCycle1 = FixedExtentScrollController(initialItem: selectedCycleDay1 - 1);
    controllerCycle2 = FixedExtentScrollController(initialItem: selectedCycleDay2 - 1);
    controllerPeriodLength1 = FixedExtentScrollController(initialItem: selectedPeriodLengthDay1 - 1);
  }

  bool _isRegular = true;
  bool get isRegular => _isRegular;
  void setIsRegular(bool val) {
    _isRegular = val;
    notifyListeners();
  }
//-----------------------------------------------------

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }


//-----------------------------------------------------
  int selectedCycleDay1 = 15;

  int selectedCycleDay2 = 16;

  late FixedExtentScrollController controllerCycle1;

  late FixedExtentScrollController controllerCycle2;

  int get secondPickerStart => selectedCycleDay1 + 1;

  int get secondPickerLength => 30 - selectedCycleDay1;

  setSelectedDay1(int value){
    selectedCycleDay1 = value;
    notifyListeners();
  }

  setSelectedDay2(int value){
    selectedCycleDay2 = value;
    notifyListeners();
  }
  //-----------------------------------------------------
  late FixedExtentScrollController controllerPeriodLength1;
  int selectedPeriodLengthDay1 = 5;
  setSelectedPeriodDay1(int value){
    selectedPeriodLengthDay1 = value;
    notifyListeners();
  }
//------------------------------------------


//------------------------------------------


  List<String> existingConditions = [
    "PCOS",
    "PMS",
    "Endometriosis",
    "Thyroid Issues",
    "Diabetes",
    "Hypertension",
  ];

  List<bool> existingConditionsSelected = List.generate(6, (index) => false);

  void toggleConditionSelection(int index) {
    if (index < 0 || index >= existingConditionsSelected.length) return;

    existingConditionsSelected[index] = !existingConditionsSelected[index];
    notifyListeners();
  }

  List<String> get selectedConditions => [
    for (int i = 0; i < existingConditions.length; i++)
      if (existingConditionsSelected[i]) existingConditions[i],
  ];

  Map<String, bool> get conditionsForApi {
    final Map<String, bool> map = {};
    for (int i = 0; i < existingConditions.length; i++) {
      map[existingConditions[i]] = existingConditionsSelected[i];
    }
    return map;
  }


  //---- onboarding completed api
  ApiResponse<OnboardingCompletedModel>? _onboardingApiData = ApiResponse.completed(null);
  ApiResponse<OnboardingCompletedModel>? get onboardingApiData => _onboardingApiData;

  void setOnboardingData(ApiResponse<OnboardingCompletedModel> response) {
    _onboardingApiData = response;
    notifyListeners();
  }

  Future<void> onboardingCompleteApi() async {
    setOnboardingData(ApiResponse.loading());
    notifyListeners();

    final data = {
      "lastPeriodStartDate": formatDateForApi(dateController.text),
      "cycleType": isRegular ? "regular" : "irregular",
      "cycleLengthDays": isRegular ? selectedCycleDay1  : selectedCycleDay2,
      "averagePeriodLengthDays": selectedPeriodLengthDay1,
      "conditions": conditionsForApi,
      "medicalHistory": medicalReason.text.isEmpty ? "No major medical history." : medicalReason.text,
    };

    pt("message data $data");

    try {
      final value = await repository.onboardingCompleted(data);
      if (value.success == true) {
        setOnboardingData(ApiResponse.completed(value));
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          AppRoutes.stagesView,
              (Route<dynamic> route) => false,
        );
        AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      } else {
        setOnboardingData(ApiResponse.error(value.message ?? "Something went wrong!"));
        AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      }
      notifyListeners();
    } catch (e, s) {
      pt("Error in setOnboardingData: $e\n$s");
      setOnboardingData(ApiResponse.error(e.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }
  }



  String formatDateForApi(String inputDate) {
    try {
      final inputFormat = DateFormat('dd-MM-yyyy');
      final outputFormat = DateFormat('yyyy-MM-dd');
      final parsedDate = inputFormat.parse(inputDate);
      return outputFormat.format(parsedDate);
    } catch (e) {
      print("Date format error: $e");
      return "";
    }
  }


  ApiResponse<CommonResponseModel>? _checkOnboardData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get checkOnboardData => _checkOnboardData;

  void setCheckOnboardingData(ApiResponse<CommonResponseModel> response) {
    _checkOnboardData = response;
    notifyListeners();
  }

  Future<bool> checkOnboardingApi(String type) async {
    setCheckOnboardingData(ApiResponse.loading());
    notifyListeners();

    try {
      final value = await repository.checkModeOnboard(type);

      if (value.success == true) {
        setCheckOnboardingData(ApiResponse.completed(value));
        notifyListeners();
        return true;
      } else {
        setCheckOnboardingData(
          ApiResponse.error(value.message ?? "Something went wrong!"),
        );
        notifyListeners();
        AppPopUp.showToast(
          message: value.message ?? "Something went wrong!",
        );
        return false;
      }
    } catch (e, s) {
      pt("Error in setOnboardingData: $e\n$s");
      setCheckOnboardingData(ApiResponse.error(e.toString()));
      notifyListeners();
      AppPopUp.showToast(
        message: "Something went wrong. Please try again.",
      );
      return false;
    }
  }



}