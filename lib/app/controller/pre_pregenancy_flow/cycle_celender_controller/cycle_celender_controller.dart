import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/dashboard_current_mood_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/menstrual_dashboard_Predict_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../main.dart';
import '../../../constants/images.dart';
import '../../../data/storage/secure_storage.dart';
import '../../../routes/app_routes.dart';
import '../model/mentural_cycle_calender_model.dart';

class CycleCalenderProvider extends ChangeNotifier {
  final otherController = TextEditingController();

  List<String> imagesForMood = [ImageConstants.great,ImageConstants.good,ImageConstants.okay,ImageConstants.low,ImageConstants.sad];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 🔴 Predicted Period Dates
  final List<int> _predictedPeriodDays = [10, 11, 12, 13, 14];

  // 🟢 Fertile Window Dates
  final List<int> _fertileWindowDays = [18, 19, 20, 21, 22, 23];

  // 🟣 Ovulation Day
  final List<int> _ovulationDays = [20];

  String? _selectedMood;
  String? get selectedMood => _selectedMood;

  void selectMood(String mood) {
    _selectedMood = mood;
    pt("mood $mood");
    notifyListeners();
  }


  final Set<String> _selectedSymptoms = {};

  Set<String> get selectedSymptoms => _selectedSymptoms;

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();
  }

  void clearAll() {
    _selectedSymptoms.clear();
    notifyListeners();
  }
 //--------------------------------------------------------------------------------------------

  ApiResponse<MenstrualDashboardPredictModel>? _dashboardApiData = ApiResponse.completed(null);
  ApiResponse<MenstrualDashboardPredictModel>? get dashboardApiData => _dashboardApiData;

  void setDashboardApiData(ApiResponse<MenstrualDashboardPredictModel> response) {
    _dashboardApiData = response;
    notifyListeners();

  }

  Future<void> dashboardData() async {
    setDashboardApiData(ApiResponse.loading());
    notifyListeners();
    final userId = await SecureStorage.getUserId();

    Map<String,dynamic> data = {
      "userId" : userId,
    };
    // pt("data body==>> $data");

    await repository.menstrualDashboardPredict(data).then((value) {
      if (value.success == true) {
        setDashboardApiData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
      }
      if(value.success == false) {
        if(value.message == "Tracker not found"){
          setDashboardApiData(ApiResponse.completed(value));
        }else {
          setDashboardApiData(ApiResponse.error(value.message ?? "Something went wrong!"));
        }
        AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setDashboardApiData(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }

 //--------------------------------------------------------------------------------------------

  ApiResponse<DashboardCurrentMood>? _dashboardMoodApiData = ApiResponse.completed(null);
  ApiResponse<DashboardCurrentMood>? get dashboardMoodApiData => _dashboardMoodApiData;

  void setMoodApiData(ApiResponse<DashboardCurrentMood> response) {
    _dashboardMoodApiData = response;
    notifyListeners();

  }

  Future<void> dashboardMoodData() async {
    setMoodApiData(ApiResponse.loading());
    notifyListeners();
    await repository.menstrualDashboardMood().then((value) {
      if (value.success == true) {
        setMoodApiData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
      }
      if(value.success == false) {
        setMoodApiData(ApiResponse.error(value.message ?? "Something went wrong!"));
        AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setMoodApiData(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }


 //--------------------------------------------------------------------------------------------

  // ApiResponse<MentauralCalenderModel>? _mentauralCalenderData = ApiResponse.completed(null);
  // ApiResponse<MentauralCalenderModel>? get mentauralCalenderData => _mentauralCalenderData;
  //
  // void setCalenderApiData(ApiResponse<MentauralCalenderModel> response) {
  //   _mentauralCalenderData = response;
  //   notifyListeners();
  //
  // }
  //
  // Future<void> cycleCalender({required int year,required int month}) async {
  //   setCalenderApiData(ApiResponse.loading());
  //   notifyListeners();
  //   final userId = await SecureStorage.getUserId();
  //
  //   Map<String,dynamic> data = {
  //     "year" : year.toString(),
  //     "month" : month.toString(),
  //   };
  //
  //   await repository.menturalCycleCalender(data).then((value) {
  //     if (value.success == true) {
  //       setCalenderApiData(ApiResponse.completed(value));
  //       pt(name: "response", "${value.message}");
  //     }
  //     if(value.success == false) {
  //       setCalenderApiData(ApiResponse.error(value.message ?? "Something went wrong!"));
  //       AppPopUp.showToast(message: value.message ?? "Something went wrong!");
  //     }
  //     notifyListeners();
  //   },).onError((error, stackTrace) {
  //     pt("Error in pregnancyInfo: $error\n$stackTrace");
  //     setCalenderApiData(ApiResponse.error(error.toString()));
  //     notifyListeners();
  //     AppPopUp.showToast(message: "Something went wrong. Please try again.");
  //     notifyListeners();
  //   },);
  // }

  //--------------------------------------------------------------------------------------------

  ApiResponse<MenturalAiInsightsModel>? _menstrualAiInsightsDash = ApiResponse.completed(null);
  ApiResponse<MenturalAiInsightsModel>? get menstrualAiInsightsDash => _menstrualAiInsightsDash;

  void setDashboardAiInsightsApiData(ApiResponse<MenturalAiInsightsModel> response) {
    _menstrualAiInsightsDash = response;
    notifyListeners();
  }

  Future<void> getDashBoardAiInsights()async{
    setDashboardAiInsightsApiData(ApiResponse.loading());
    final userId = await SecureStorage.getUserId();
    Map<String, dynamic>  data = {
      "userId": userId,
    };

    repository.menstrualDashboardAiInsights(data).then((value) {
      if(value.success == true){
        setDashboardAiInsightsApiData(ApiResponse.completed(value));
      }else{
        setDashboardAiInsightsApiData(ApiResponse.error(""));
      }
    },).onError((error, stackTrace) {
      pt("Error>>>>>> $error , $stackTrace");
    },);
  }


  //--------------------------------------------------------------------------------------------

  ApiResponse<MenturalAiInsightsModel>? _menturalAiInsights = ApiResponse.completed(null);
  ApiResponse<MenturalAiInsightsModel>? get menturalAiInsights => _menturalAiInsights;

  void setAiInsightsApiData(ApiResponse<MenturalAiInsightsModel> response) {
    _menturalAiInsights = response;
    notifyListeners();
  }

  Future<void> aiInsightsApi(String category) async {
    setAiInsightsApiData(ApiResponse.loading());
    notifyListeners();
    final userId = await SecureStorage.getUserId();

    final data = {
      "category": category,
      "userId": userId,
    };

    try {
      final value = await repository.menturalAiInsights(data);

      final message = ""; // value.message ?? "";  Model no longer has message
      final isPlanError = false; // message.contains("Your plan does not include");
      final isTrackerNotFound = false; // message == "Tracker not found";

      if (value.success == true) {
        setAiInsightsApiData(ApiResponse.completed(value));
      }
      // else if (isPlanError || isTrackerNotFound) {
      //   // ⬅️ Treat these as VALID responses
      //   setAiInsightsApiData(ApiResponse.completed(value));
      // }
      else {
        // ⬅️ Real error
        setAiInsightsApiData(
          ApiResponse.error("Something went wrong!"),
        );
        AppPopUp.showToast(
            message: "Something went wrong!");
      }

    } catch (error, stackTrace) {
      pt("Error in aiInsightsApi: $error\n$stackTrace");

      setAiInsightsApiData(
          ApiResponse.error("Something went wrong. Please try again."));
      AppPopUp.showToast(
          message: "Something went wrong. Please try again.");
    }

    notifyListeners();
  }

  //--------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------
  double stressLevel = 3;
  double anxietyLevel = 2;

  ApiResponse<DailyLogsMenturalModel>? _menturalAddDailyLogs = ApiResponse.completed(null);
  ApiResponse<DailyLogsMenturalModel>? get menturalAddDailyLogs => _menturalAddDailyLogs;

  void setDailyLogs(ApiResponse<DailyLogsMenturalModel> response) {
    _menturalAddDailyLogs = response;
    notifyListeners();

  }

  Future<void> addDailyLogsMentural({DateTime? date}) async {
    setDailyLogs(ApiResponse.loading());
    notifyListeners();
    Map<String, dynamic> data = {
      "date": formatDateForApi(DateFormat('dd-MM-yyyy').format(date ?? DateTime.now())),
      "mood": selectedMood,
      "symptoms": selectedSymptoms.map((e) => e.toLowerCase()).toList(),
      "stressLevel": stressLevel,
      "anxietyLevel": anxietyLevel,
      "notes": otherController.text,
      // "sleepQuality": 4
    };
    await repository.addDailyLogsMentural(data).then((value) async{
      if (value.success == true) {
        setDailyLogs(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");

        Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.cycleCalendarView);
        await dashboardData();
        await getDashBoardAiInsights();
        await dashboardMoodData();
        AppPopUp.showToast(message: value.message ?? "",duration: Duration(seconds: 2),);
      }
      if(value.success == false) {
        setDailyLogs(ApiResponse.error(value.message ?? "Something went wrong!"));
        AppPopUp.showToast(message: value.message ?? "Something went wrong!",duration: Duration(seconds: 10),);
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in setDailyLogs: $error\n$stackTrace");
      setDailyLogs(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }

  //--------------------------------------------------------------------------------------------

  Future<void> addMenstrualCycle({DateTime? startDate, DateTime? endDate}) async {
    setLoading(true);
    notifyListeners();
    try {
      Map<String, dynamic> data = {
        if (startDate != null) "startDate": DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null) "endDate": DateFormat('yyyy-MM-dd').format(endDate),
        "notes": "Added from App"
      };

      await repository.addMenstrual(data).then((value) async {
        if (value['success'] == true) {
          pt(name: "response", "${value['message']}");
          AppPopUp.showToast(message: value['message'] ?? "Successfully updated!");
          
          // Refresh all relevant data
          await dashboardData();
          await getDashBoardAiInsights();
          await dashboardMoodData();
          await cycleCalender(year: focusedDay.year, month: focusedDay.month);
        } else {
          AppPopUp.showToast(message: value['message'] ?? "Something went wrong!");
        }
      });
    } catch (e, s) {
      pt("Error in addMenstrualCycle: $e\n$s");
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  //--------------------------------------------------------------------------------------------

  DateTime _focusedDay = DateTime.now();

  // API से आने वाली 3 लिस्ट
  List<String> predictedPeriod = [];
  List<String> fertileWindow = [];
  List<String> ovulationDays = [];

  DateTime get focusedDay => _focusedDay;
  String get formattedMonthYear =>
      DateFormat('MMMM yyyy').format(_focusedDay);

  ApiResponse<MentauralCalenderModel>? _calendarApi =
  ApiResponse.completed(null);
  ApiResponse<MentauralCalenderModel>? get calendarApi => _calendarApi;

  void _setCalendarApi(ApiResponse<MentauralCalenderModel> res) {
    _calendarApi = res;
    notifyListeners();
  }


  // Provider class mein ye method add karo:
  Color? getDayBackgroundColor(DateTime day) {
    Color? cycleColor = getDotColor(day); // Existing method

    if (cycleColor != null) {
      return cycleColor.withOpacity(0.2); // Light background
    }
    return null;
  }


  // -------------------------------------------------------
  // ⛳ MAIN API CALL
  // -------------------------------------------------------
  Future<void> cycleCalender({required int year, required int month}) async {

    Map<String, dynamic> data = {
      "year": year,
      "month": month,
    };

    try {
      final value = await repository.menturalCycleCalender(data);
      pt("🔥 Calendar API for $year-$month: success=${value.success}");

      if (value.success == true) {
        _setCalendarApi(ApiResponse.completed(value));

        // Use filteredCalendar directly — this endpoint returns pre-computed date lists
        if (value.data?.filteredCalendar != null) {
          predictedPeriod = _sanitizeDates(
            value.data!.filteredCalendar!.predictedPeriod ?? [], limit: 10);
          fertileWindow = _sanitizeDates(
            value.data!.filteredCalendar!.fertileWindow ?? [], limit: 10);
          ovulationDays = _sanitizeDates(
            value.data!.filteredCalendar!.ovulationDays ?? [], limit: 3);
        } else {
          predictedPeriod = [];
          fertileWindow = [];
          ovulationDays = [];
        }

        pt("🔥 Predicted[$month]: $predictedPeriod");
        pt("🔥 Fertile[$month]: $fertileWindow");
        pt("🔥 Ovulation[$month]: $ovulationDays");
      } else {
        pt("🔥 API returned success=false: ${value.message}");
        _setCalendarApi(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    } catch (e, stackTrace) {
      pt("🔥 CRASH in cycleCalender: $e\n$stackTrace");
      _setCalendarApi(ApiResponse.error(e.toString()));
      notifyListeners();
    }
  }

  /// Prunes invalid dates and limits consecutive ranges to prevent "All-Red-Month" bugs
  List<String> _sanitizeDates(List<String> dates, {int limit = 10}) {
    if (dates.isEmpty) return [];
    
    // 1. Remove impossible years (handle backend 1970 bug)
    final validYearDates = dates.where((d) {
      try {
        final year = DateTime.parse(d).year;
        return year > 2000 && year < 2100;
      } catch(_) { return false; }
    }).toList();

    // 2. Limit length if it's unnaturally long for a period/fertile window
    // If more than 'limit' days in a single month are marked, it's likely a calculation error
    if (validYearDates.length > limit) {
       return validYearDates.take(limit).toList();
    }

    return validYearDates;
  }


  // -------------------------------------------------------
  // ⛳ NEXT MONTH
  // -------------------------------------------------------
  void nextMonth() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    cycleCalender(year: _focusedDay.year, month: _focusedDay.month);
    notifyListeners();
  }

  // -------------------------------------------------------
  // ⛳ PREVIOUS MONTH
  // -------------------------------------------------------
  void previousMonth() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    cycleCalender(year: _focusedDay.year, month: _focusedDay.month);
    notifyListeners();
  }

  // -------------------------------------------------------
  // ⛳ UPDATE CALENDAR PAGE CHANGE
  // -------------------------------------------------------
  void updateFocusedDay(DateTime day) {
    // Skip if already on the same month (prevents duplicate API call from onPageChanged)
    if (_focusedDay.year == day.year && _focusedDay.month == day.month) return;
    _focusedDay = day;
    cycleCalender(
      year: _focusedDay.year,
      month: _focusedDay.month,
    );
    notifyListeners();
  }

  // -------------------------------------------------------
  // ⛳ SELECTED DAY
  // -------------------------------------------------------
  DateTime? _selectedDay;
  DateTime? get selectedDay => _selectedDay;

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // -------------------------------------------------------
  // ⛳ DOT COLOR FUNCTION (FINAL)
  // -------------------------------------------------------
  Color? getDotColor(DateTime date) {
    String f = _format(date);

    if (predictedPeriod.contains(f)) {
      return Colors.red; // Period
    }
    if (fertileWindow.contains(f)) {
      return Colors.green; // Fertile
    }
    if (ovulationDays.contains(f)) {
      return Colors.yellow; // Ovulation
    }
    return null;
  }

  // YYYY-MM-DD format for matching API result
  String _format(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.day.toString().padLeft(2, '0')}";


}
