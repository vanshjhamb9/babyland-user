import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/dashboard_current_mood_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/menstrual_dashboard_Predict_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/subscription_dialog.dart';
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

  Future<void> dashboardData({bool allowRetry = true}) async {
    setDashboardApiData(ApiResponse.loading());
    notifyListeners();
    final userId = await SecureStorage.getUserId();

    Map<String,dynamic> data = {
      "userId" : userId,
    };
    // pt("data body==>> $data");

    await repository.menstrualDashboardPredict(data).then((value) async {
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
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      }
      notifyListeners();
    },).onError((error, stackTrace) async {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      final msg = error.toString().toLowerCase();
      final isTransient = msg.contains('timeout') ||
          msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('network') ||
          msg.contains('401') ||
          msg.contains('503') ||
          msg.contains('502');
      if (allowRetry && isTransient) {
        pt('dashboardData: transient failure — auto-retry once');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await dashboardData(allowRetry: false);
        return;
      }
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
    await repository.menstrualDashboardMood().then((value) async {
      if (value.success == true) {
        setMoodApiData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
      }
      if(value.success == false) {
        setMoodApiData(ApiResponse.error(value.message ?? "Something went wrong!"));
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "Something went wrong!");
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

    // GET /api/v1/ai/insights: category required; user id from JWT only (do not send userId).
    final data = <String, dynamic>{
      "category": category,
    };

    try {
      final value = await repository.menturalAiInsights(data);

      final message = ""; // value.message ?? "";  Model no longer has message
      final isPlanError = false; // message.contains("Your plan does not include");
      final isTrackerNotFound = false; // message == "Tracker not found";

      if (value.success == true) {
        setAiInsightsApiData(ApiResponse.completed(value));
      } else {
        final msg = value.displayMessage;
        setAiInsightsApiData(ApiResponse.error(msg));
        final handled =
            await SubscriptionDialog.showDialogIfSubscriptionRequired(msg);
        if (!handled) AppPopUp.showToast(message: msg);
      }

    } catch (error, stackTrace) {
      pt("Error in aiInsightsApi: $error\n$stackTrace");

      setAiInsightsApiData(
          ApiResponse.error("Error: $error"));
      AppPopUp.showToast(
          message: "Error: $error");
    }

    notifyListeners();
  }

  //--------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------
  double stressLevel = 3;
  double anxietyLevel = 2;
  double sleepQualityLevel = 3;

  ApiResponse<DailyLogsMenturalModel>? _menturalAddDailyLogs = ApiResponse.completed(null);
  ApiResponse<DailyLogsMenturalModel>? get menturalAddDailyLogs => _menturalAddDailyLogs;

  void setDailyLogs(ApiResponse<DailyLogsMenturalModel> response) {
    _menturalAddDailyLogs = response;
    notifyListeners();

  }

  /// Load existing log for a given date into the form (mood, symptoms, stress, anxiety, notes)
  Future<void> loadLogForDate(DateTime date) async {
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    final apiDate = formatDateForApi(dateStr);
    try {
      final value = await repository.getMenstrualLogs(params: {'date': apiDate});
      if (value.success != true || value.data == null || value.data!.isEmpty) {
        clearDailyLogForm();
        return;
      }
      final log = value.data!.first;
      _selectedMood = log.mood;
      _selectedSymptoms.clear();
      if (log.symptoms != null && log.symptoms!.isNotEmpty) {
        for (final s in log.symptoms!) {
          final cap = s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;
          _selectedSymptoms.add(cap);
        }
      }
      stressLevel = double.tryParse(log.stressLevel ?? '3') ?? 3;
      anxietyLevel = double.tryParse(log.anxietyLevel ?? '2') ?? 2;
      sleepQualityLevel = (log.sleepQuality ?? 3).toDouble();
      otherController.text = log.notes ?? '';
      notifyListeners();
    } catch (e, st) {
      pt("loadLogForDate error: $e $st");
      clearDailyLogForm();
      notifyListeners();
    }
  }

  void clearDailyLogForm() {
    _selectedMood = null;
    _selectedSymptoms.clear();
    stressLevel = 3;
    anxietyLevel = 2;
    sleepQualityLevel = 3;
    otherController.clear();
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
      "sleepQuality": sleepQualityLevel.toInt(),
      "notes": otherController.text,
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
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "Something went wrong!", duration: Duration(seconds: 10));
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
        if (value.success == true) {
          pt(name: "response", "${value.message}");
          AppPopUp.showToast(message: value.message ?? "Successfully updated!");
          
          // Refresh all relevant data
          await dashboardData();
          await getDashBoardAiInsights();
          await dashboardMoodData();
          await cycleCalender(year: focusedDay.year, month: focusedDay.month);
        } else {
          final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
          if (!handled) AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        }
      });
    } catch (e, s) {
      pt("Error in addMenstrualCycle: $e\n$s");
      AppPopUp.showToast(message: "Error: $e");
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
            value.data!.filteredCalendar!.ovulationDays ?? []);
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
        final msg = value.message ?? "Something went wrong!";
        _setCalendarApi(ApiResponse.error(msg));
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(msg);
        if (!handled) AppPopUp.showToast(message: msg);
      }
      notifyListeners();
    } catch (e, stackTrace) {
      pt("🔥 CRASH in cycleCalender: $e\n$stackTrace");
      _setCalendarApi(ApiResponse.error(e.toString()));
      notifyListeners();
    }
  }

  /// Prunes invalid dates and optionally limits consecutive ranges to prevent
  /// "all-red-month" bugs. Ovulation must not be truncated.
  List<String> _sanitizeDates(List<String> dates, {int? limit}) {
    if (dates.isEmpty) return [];

    final normalized = <String>[];
    for (final raw in dates) {
      final ymd = _toYmd(raw);
      if (ymd == null) continue;
      if (!normalized.contains(ymd)) normalized.add(ymd);
    }

    if (limit != null && normalized.length > limit) {
      return normalized.take(limit).toList();
    }

    return normalized;
  }

  String? _toYmd(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      if (parsed.year <= 2000 || parsed.year >= 2100) return null;
      return _format(parsed);
    } catch (_) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
        return raw.substring(0, 10);
      }
      return null;
    }
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
  /// Ovulation is painted first so it is never hidden under predicted/fertile days.
  Color? getDotColor(DateTime date) {
    String f = _format(date);

    if (ovulationDays.contains(f)) {
      return Colors.yellow; // Ovulation
    }
    if (predictedPeriod.contains(f)) {
      return Colors.red; // Period
    }
    if (fertileWindow.contains(f)) {
      return Colors.green; // Fertile
    }
    return null;
  }

  /// Summary strings for the **currently loaded calendar month** (same data as grid).
  String? get monthSummaryPredictedPeriodRange {
    final range = _dateRangeLabel(predictedPeriod);
    return range;
  }

  String? get monthSummaryFertileWindowRange {
    return _dateRangeLabel(fertileWindow);
  }

  String? get monthSummaryOvulationDay {
    if (ovulationDays.isEmpty) return null;
    final sorted = _parseSortIsoDates(ovulationDays);
    if (sorted.isEmpty) return null;
    return formatDateToDayMonth(_format(sorted.first));
  }

  List<DateTime> _parseSortIsoDates(List<String> dates) {
    final out = <DateTime>[];
    for (final s in dates) {
      try {
        out.add(DateTime.parse(s));
      } catch (_) {}
    }
    out.sort();
    return out;
  }

  String? _dateRangeLabel(List<String> isoDates) {
    final sorted = _parseSortIsoDates(isoDates);
    if (sorted.isEmpty) return null;
    final a = sorted.first;
    final b = sorted.last;
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay) {
      return formatDateToDayMonth(_format(a));
    }
    return '${formatDateToDayMonth(_format(a))} - ${formatDateToDayMonth(_format(b))}';
  }

  // YYYY-MM-DD format for matching API result
  String _format(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.day.toString().padLeft(2, '0')}";


}
