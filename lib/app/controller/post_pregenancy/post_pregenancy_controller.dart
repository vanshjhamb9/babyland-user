import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/subscription_dialog.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:babyland/features/post_pregnancy/state/postpartum_dashboard_notifier.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/storage/user_local_data.dart';
import '../../routes/app_routes.dart';
import 'model/postpartums_add_model.dart';
import 'model/recovery_progress_model.dart';

class PostpregnancyProvider extends ChangeNotifier {
  // --- EXISTING STATE ---
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeIndex(int newIndex) {
    if (newIndex == 1 && dateController.text.isNotEmpty && dobController.text.isEmpty) {
      dobController.text = dateController.text;
    }
    _currentIndex = newIndex;
    notifyListeners();
  }

  final Set<int> _selectedIndexes = {};
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
    notifyListeners();
  }
  String? selectedGender;

  final dateController = TextEditingController();
  final dobController = TextEditingController();
  final babyNameController = TextEditingController();

  // --- RECOVERY SCALE STATE ---
  
  // Postpartum Journal (1-5 scale)
  double journalPain = 1.0;
  double journalWound = 5.0;
  double journalSwelling = 5.0;
  double journalMobility = 5.0;
  double journalEnergy = 5.0;
  double journalStrength = 5.0;

  void updateJournal({
    double? pain,
    double? wound,
    double? swelling,
    double? mobility,
    double? energy,
    double? strength,
  }) {
    if (pain != null) journalPain = pain;
    if (wound != null) journalWound = wound;
    if (swelling != null) journalSwelling = swelling;
    if (mobility != null) journalMobility = mobility;
    if (energy != null) journalEnergy = energy;
    if (strength != null) journalStrength = strength;
    notifyListeners();
  }

  // Physical Healing
  int painLevel = 0; // 0-10
  String woundHealing = "Good"; // Poor, Okay, Good
  String swelling = "None"; // High, Mild, None
  String mobility = "Normal"; // Limited, Moderate, Normal

  // Uterine Recovery
  String cramps = "None"; // Severe, Mild, None
  String bellyReduction = "Good progress"; // No change, Slow, Good progress

  // Energy & Strength
  String energyLevel = "High"; // Low, Moderate, High
  String fatigue = "Low"; // High, Medium, Low
  String dailyActivity = "Normal"; // Limited, Moderate, Normal
  int sleepQuality = 3; // 1-5

  void updatePhysical({int? pain, String? wound, String? swell, String? mob}) {
    if (pain != null) painLevel = pain;
    if (wound != null) woundHealing = wound;
    if (swell != null) swelling = swell;
    if (mob != null) mobility = mob;
    notifyListeners();
  }

  void updateUterine({String? cramp, String? belly}) {
    if (cramp != null) cramps = cramp;
    if (belly != null) bellyReduction = belly;
    notifyListeners();
  }

  void updateEnergy({String? energy, String? fat, String? activity, int? sleep}) {
    if (energy != null) energyLevel = energy;
    if (fat != null) fatigue = fat;
    if (activity != null) dailyActivity = activity;
    if (sleep != null) sleepQuality = sleep;
    notifyListeners();
  }

  ApiResponse<CommonResponseModel>? _recoveryLogStatus = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get recoveryLogStatus => _recoveryLogStatus;

  ApiResponse<CommonResponseModel>? _journalLogStatus = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get journalLogStatus => _journalLogStatus;

  Future<void> submitJournalLog({required String date}) async {
    final formattedDate = formatDateForApi(date);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (formattedDate != today) {
      AppPopUp.showToast(message: "Logs can only be edited on the same day.");
      return;
    }

    _journalLogStatus = ApiResponse.loading();
    notifyListeners();

    // Mapping 1-5 scale to 0-100 scores
    // pain: 1 is best, 5 is worst
    double physicalScore = ((6 - journalPain) + journalWound + journalSwelling + journalMobility) / 20.0 * 100.0;
    double energyScore = (journalEnergy + journalStrength) / 10.0 * 100.0;

    final payload = {
      "date": formattedDate,
      "painScore": journalPain.toInt(),
      "woundHealingScore": journalWound.toInt(),
      "swellingScore": journalSwelling.toInt(),
      "mobilityScore": journalMobility.toInt(),
      "energyScore": journalEnergy.toInt(),
      "strengthScore": journalStrength.toInt(),
      "physicalHealing": {
        "score": physicalScore,
      },
      "energyStrength": {
        "score": energyScore,
      },
      "mood": TrackerMath.scoreToMood((physicalScore + energyScore) ~/ 20 + 1),
    };

    try {
      final value = await repository.postpartumsJournalAdd(payload);
      if (value.success == true) {
        _journalLogStatus = ApiResponse.completed(value);
        AppPopUp.showToast(message: "Journal log saved!");
        getRecoveryTaskApi(isRefresh: false);
        getDashboardLogsApi();
        _refreshPostpartumDashboard();
        Navigator.pop(navigatorKey.currentContext!);
      } else {
        _journalLogStatus = ApiResponse.error(value.message);
        AppPopUp.showToast(message: value.message ?? "Failed to save journal");
      }
    } catch (e) {
      _journalLogStatus = ApiResponse.error(e.toString());
      AppPopUp.showToast(message: "Error: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> submitRecoveryLog({required String date}) async {
    _recoveryLogStatus = ApiResponse.loading();
    notifyListeners();

    final physicalScore = TrackerMath.calculatePhysicalHealingScore(
      pain: painLevel,
      wound: woundHealing,
      swelling: swelling,
      mobility: mobility,
    );

    final uterineScore = TrackerMath.calculateUterineRecoveryScore(
      cramps: cramps,
      bellyReduction: bellyReduction,
    );

    final energyScore = TrackerMath.calculateEnergyScore(
      energy: energyLevel,
      fatigue: fatigue,
      activity: dailyActivity,
    );

    // Map wound healing string to 1-5 score for backend
    int woundScore = 3;
    switch (woundHealing.toLowerCase()) {
      case 'good': woundScore = 5; break;
      case 'okay': woundScore = 3; break;
      case 'poor': woundScore = 1; break;
    }

    final payload = {
      "date": formatDateForApi(date),
      "physical": {
        "pain": painLevel,
        "woundHealing": woundScore,
        "swelling": swelling.toLowerCase(),
      },
      "uterine": {
        "bleedingLevel": 3, // Default value if not collected in UI
        "cramps": cramps.toLowerCase(),
      },
      "energy": {
        "energyLevel": energyLevel.toLowerCase(),
        "fatigue": fatigue.toLowerCase(),
        "sleepQuality": sleepQuality,
      },
      "notes": "Postpartum recovery log",
      "mood": TrackerMath.scoreToMood((physicalScore + uterineScore + energyScore) ~/ 30 + 1),
    };

    try {
      final value = await repository.postpartumsLogsAdd(payload);
      if (value.success == true) {
        _recoveryLogStatus = ApiResponse.completed(value);
        
        // Handle Alerts
        final dataMap = value.data is Map ? value.data as Map<String, dynamic> : null;
        if (dataMap?['alertsTriggered'] == true) {
          AppPopUp.showToast(message: "Log saved. Clinical alert triggered!");
        } else {
          AppPopUp.showToast(message: "Recovery log saved!");
        }
        
        getRecoveryTaskApi(isRefresh: false);
        getDashboardLogsApi();
        _refreshPostpartumDashboard();
        Navigator.pop(navigatorKey.currentContext!);
      } else {
        _recoveryLogStatus = ApiResponse.error(value.message);
        AppPopUp.showToast(message: value.message ?? "Failed to save log");
      }
    } catch (e) {
      _recoveryLogStatus = ApiResponse.error(e.toString());
      AppPopUp.showToast(message: "Error: $e");
    } finally {
      notifyListeners();
    }
  }

  void _refreshPostpartumDashboard() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    try {
      ctx.read<PostpartumDashboardNotifier>().refresh(
        recoveryTask: getRecoveryApiData?.data,
        dashboardLogs: dashboardLogsApiData?.data,
        force: true,
      );
    } catch (_) {}
  }

  // --- API DATA & METHODS ---

  ApiResponse<PostpartumsAddModel>? _postPregnancyInfoApiData = ApiResponse.completed(null);
  ApiResponse<PostpartumsAddModel>? get postPregnancyInfoApiData => _postPregnancyInfoApiData;

  void setPregnancyData(ApiResponse<PostpartumsAddModel> response) {
    _postPregnancyInfoApiData = response;
    notifyListeners();
  }

  Future<void> pregnancyInfo() async {
    final deliveryDate = formatDateForApiYMD(dateController.text);
    final babyDate = formatDateForApiYMD(dobController.text);
    if (deliveryDate.isEmpty || babyDate.isEmpty) {
      const msg =
          'Please enter a valid delivery date and baby date of birth.';
      setPregnancyData(ApiResponse.error(msg));
      AppPopUp.showToast(message: msg);
      notifyListeners();
      return;
    }

    setPregnancyData(ApiResponse.loading());
    notifyListeners();

    final data = {
      "deliveryDate": deliveryDate,
      "deliveryType": _normalizeDeliveryType(selectedDeliveryType),
      "babyDetails": {
        "name": babyNameController.text.trim(),
        "date": babyDate,
        "gender": selectedGender?.toLowerCase() == "boy"
            ? "Male"
            : selectedGender?.toLowerCase() == "girl"
            ? "Female"
            : "Prefer not to say",
      }
    };

    pt('[POSTPARTUM-AUDIT] pregnancyInfo payload=$data');

    try {
      final value = await repository.postpartumsAdd(data);
      pt(
        '[POSTPARTUM-AUDIT] pregnancyInfo result success=${value.success} message=${value.message}',
      );
      if (value.success == true ||
          PostpartumsAddModel.isAlreadyExists(value.message)) {
        setPregnancyData(ApiResponse.completed(value));
        await _completePostpartumSetupAndGoToDashboard();
      } else {
        final msg = value.message?.trim();
        setPregnancyData(
          ApiResponse.error(
            (msg != null && msg.isNotEmpty) ? msg : 'Something went wrong!',
          ),
        );
        AppPopUp.showToast(
          message: (msg != null && msg.isNotEmpty)
              ? msg
              : 'Something went wrong!',
        );
      }
    } catch (error, stackTrace) {
      pt('[POSTPARTUM-AUDIT] pregnancyInfo error: $error');
      pt('Stack trace: $stackTrace');
      if (PostpartumsAddModel.isAlreadyExists(error.toString())) {
        setPregnancyData(ApiResponse.completed(null));
        await _completePostpartumSetupAndGoToDashboard();
      } else {
        setPregnancyData(ApiResponse.error(error.toString()));
        final apiMessage = _userFacingPostpartumError(error);
        AppPopUp.showToast(message: apiMessage);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _completePostpartumSetupAndGoToDashboard() async {
    await UserLocalData.saveBabyDetails(
      name: babyNameController.text,
      dob: dobController.text,
      gender: selectedGender,
    );
    await UserLocalData.savePostPregnancySetupComplete();
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.pushNamedAndRemoveUntil(
      ctx,
      AppRoutes.postPregnancyNavbarView,
      (route) => false,
    );
  }

  String _userFacingPostpartumError(Object error) {
    final raw = error.toString();
    const prefix = 'AppException(UNKNOWN): ';
    if (raw.startsWith(prefix)) {
      final inner = raw.substring(prefix.length).trim();
      if (inner.isNotEmpty) return inner;
    }
    if (raw.contains('Exception:')) {
      final inner = raw.split('Exception:').last.trim();
      if (inner.isNotEmpty && inner.length < 180) return inner;
    }
    return 'Something went wrong. Please try again.';
  }

  String _normalizeDeliveryType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'c-section':
      case 'csection':
      case 'c section':
      case 'c_section':
        return 'c_section';
      default:
        return 'Normal';
    }
  }

  ApiResponse<MenstrualLogsListModel>? _dashboardLogsApiData = ApiResponse.completed(null);
  ApiResponse<MenstrualLogsListModel>? get dashboardLogsApiData => _dashboardLogsApiData;

  Future<void> getDashboardLogsApi() async {
    _dashboardLogsApiData = ApiResponse.loading();
    notifyListeners();
    try {
      final value = await repository.getPostpartumLogs();
      _dashboardLogsApiData = ApiResponse.completed(value);
    } catch (e) {
      _dashboardLogsApiData = ApiResponse.error(e.toString());
    } finally {
      notifyListeners();
    }
  }

  ApiResponse<CommonResponseModel>? _postpartumsLogsAdd = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get postpartumsLogsAdd => _postpartumsLogsAdd;

  void postpartumsLogsAddData(ApiResponse<CommonResponseModel> response) {
    _postpartumsLogsAdd = response;
    notifyListeners();
  }

  Future<void> postpartumsLogsAddApi({
    required String mood,
    required String date,
    required List<String> symptoms,
    required var stressLevel,
    required var anxietyLevel,
    required int sleepQuality,
    required String notes,
  }) async {
    postpartumsLogsAddData(ApiResponse.loading());
    notifyListeners();

    Map<String, dynamic> data = {
      "date": formatDateForApi(date),
      "mood": mood,
      "symptoms": symptoms,
      "stressLevel": stressLevel,
      "anxietyLevel": anxietyLevel,
      "sleepQuality": sleepQuality,
      "notes": notes,
    };

    try {
      final value = await repository.postpartumsLogsAdd(data);
      if (value.success == true) {
        postpartumsLogsAddData(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "Log saved!");
        await getDashboardLogsApi();
        _refreshPostpartumDashboard();
        final nav = navigatorKey.currentContext;
        if (nav != null && Navigator.canPop(nav)) {
          Navigator.pop(nav);
        } else if (nav != null) {
          Navigator.pushNamed(nav, AppRoutes.postPregnancyNavbarView);
        }
      } else {
        postpartumsLogsAddData(ApiResponse.error(value.message ?? "Something went wrong!"));
        final handled = await SubscriptionDialog.showDialogIfSubscriptionRequired(value.message);
        if (!handled) AppPopUp.showToast(message: value.message ?? "Something went wrong!");
      }
    } catch (error) {
      postpartumsLogsAddData(ApiResponse.error(error.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    } finally {
      notifyListeners();
    }
  }

  // --- FEEDING ---
  ApiResponse<CommonResponseModel>? _feedingData = ApiResponse<CommonResponseModel>.completed(null);
  ApiResponse<CommonResponseModel>? get feedingData => _feedingData;

  void setFeedingApi(ApiResponse<CommonResponseModel> response) {
    _feedingData = response;
    notifyListeners();
  }

  Future<void> getFeedingApi() async {
    setFeedingApi(ApiResponse.loading());
    try {
      final value = await repository.getFeeding();
      if (value.success == true) {
        setFeedingApi(ApiResponse.completed(value));
      } else {
        setFeedingApi(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
    } catch (error) {
      setFeedingApi(ApiResponse.error(error.toString()));
    } finally {
      notifyListeners();
    }
  }

  // --- RECOVERY TASKS ---
  ApiResponse<PostpartumsAddModel>? _recoveryTaskApiData = ApiResponse.completed(null);
  ApiResponse<PostpartumsAddModel>? get recoveryTaskApiData => _recoveryTaskApiData;

  void setRecoveryTaskApiData(ApiResponse<PostpartumsAddModel> response) {
    _recoveryTaskApiData = response;
    notifyListeners();
  }

  Future<bool> recoveryTaskApi({
    required bool? completed,
    required String? id,
    required String? task,
    required String dateAssigned,
    required String dueDate,
    required String dateCompleted,
  }) async {
    setRecoveryTaskApiData(ApiResponse.loading());
    final data = {
      "task": task,
      "dateAssigned": dateAssigned,
      "dueDate": dueDate,
      "completed": completed,
      "dateCompleted": dateCompleted
    };

    try {
      final value = await repository.recoveryTask(data, id);
      if (value.success == true) {
        setRecoveryTaskApiData(ApiResponse.completed(value));
        getRecoveryTaskApi(isRefresh: false);
        AppPopUp.showToast(message: value.message ?? "");
        return true;
      } else {
        setRecoveryTaskApiData(ApiResponse.error(value.message));
        AppPopUp.showToast(message: value.message ?? "Please try again.");
        return false;
      }
    } catch (e) {
      setRecoveryTaskApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      return false;
    } finally {
      notifyListeners();
    }
  }

  ApiResponse<RecoveryProgressModel>? _getRecoveryApiData = ApiResponse.completed(null);
  ApiResponse<RecoveryProgressModel>? get getRecoveryApiData => _getRecoveryApiData;

  void setGetRecoveryTaskApiData(ApiResponse<RecoveryProgressModel> response) {
    _getRecoveryApiData = response;
    notifyListeners();
  }

  Future<bool> getRecoveryTaskApi({bool? isRefresh = true}) async {
    if (isRefresh == true) setGetRecoveryTaskApiData(ApiResponse.loading());
    final data = {"date": DateFormat('yyyy-MM-dd').format(DateTime.now())};
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
      pt("getRecoveryTaskApi error: $e\n$s");
      setGetRecoveryTaskApiData(ApiResponse.error(e.toString()));
      return false;
    } finally {
      notifyListeners();
    }
  }
}
