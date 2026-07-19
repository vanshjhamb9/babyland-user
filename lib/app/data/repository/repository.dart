import 'dart:io';
import 'dart:convert';
import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/controller/ai_assistant/model/ai_chat_model.dart';
import 'package:babyland/app/controller/basic_information/model/onboarding_completed_model.dart';
import 'package:babyland/app/controller/create_account/model/set_password_model.dart';
import 'package:babyland/app/controller/experts_consultation/model/booking_data_model.dart';
import 'package:babyland/app/controller/experts_consultation/model/doctor_data_model.dart';
import 'package:babyland/app/controller/post_pregenancy/model/postpartums_add_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/appoinment_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/model/communities_data_model.dart';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_info_model.dart';
import 'package:babyland/app/controller/sign_in/model/login_model.dart';
import 'package:babyland/app/view/baby_growth/model/baby_growth_add_data_model.dart';
import 'package:babyland/app/view/baby_growth/model/baby_growth_details_model.dart';
import 'package:babyland/app/view/baby_growth/model/get_mildstone_model.dart';
import 'package:babyland/app/view/baby_growth/photo/photo_model/get_baby_photos_model.dart';
import 'package:babyland/app/view/baby_growth/vaccianations/model/vaccination_model.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/model/subscription_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import 'package:babyland/core/di/service_locator.dart';
import '../../agora/agora.dart';
import '../../controller/ai_assistant/model/chat_room_create_model.dart';
import '../../controller/ai_assistant/model/create_ai_chat_model.dart';
import '../../controller/baby_growth/model/add_baby_growth_data_model.dart';
import '../../controller/experts_consultation/model/ConsultationDataModel.dart';
import '../../controller/experts_consultation/model/availableslotdatamodel.dart';
import '../../controller/experts_consultation/model/live_slots_model.dart';
import '../../controller/experts_consultation/model/booking_add_model.dart';
import '../../controller/forgot_password/model/forgot_password_model.dart';
import '../../controller/policies/model/policy_model.dart';
import '../../controller/post_pregenancy/model/recovery_progress_model.dart';
import '../../controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import '../../controller/pre_pregenancy_flow/model/dashboard_current_mood_model.dart';
import '../../controller/pre_pregenancy_flow/model/menstrual_dashboard_Predict_model.dart';
import '../../controller/pre_pregenancy_flow/model/menstrual_predict_model.dart';
import '../../controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import '../../controller/pre_pregenancy_flow/model/mentural_cycle_calender_model.dart';
import '../../controller/pre_pregenancy_flow/model/menstruals_cycle_model.dart';
import '../../controller/pregnancy_flow/model/addAppointment_data_model.dart';
import '../../controller/pregnancy_flow/model/postsenddatamodel.dart';
import '../../controller/pregnancy_flow/model/pregnancy_data_model.dart';
import '../../controller/group_controller/model/group_model.dart';
import '../network/end_points.dart';
import '../network/network_api_services.dart';
import '../../controller/create_account/model/request_verification_model.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:intl/intl.dart';

class Repository extends ChangeNotifier {
  final NetworkApiServices apiService;

  Repository._internal(this.apiService);

  static final Repository _instance = Repository._internal(
    NetworkApiServices(),
  );

  factory Repository({NetworkApiServices? apiService}) {
    return _instance;
  }

  /* ------------------------------------------------ Authentication ---------------------------------------------------- */
  
  // NEW AUTH FLOW 
  Future<CommonResponseModel> signup(Map<String, String> data) async {
    final response = await apiService.post(EndPoints.signup, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> sendOtp(Map<String, String> data) async {
    final response = await apiService.post(EndPoints.sendOtp, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> verifyOtpSignup(Map<String, String> data) async {
    // Backend now expects { idToken, phone }
    final response = await apiService.post(EndPoints.verifyOtp, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> googleLogin(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.googleLogin, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> appleLogin(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.appleLogin, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> updatePhone(Map<String, dynamic> data) async {
    // Modify based on the exact endpoint if update phone is required.
    // Assuming EndPoints.updatePhone for now
    final response = await apiService.post(EndPoints.updatePhone, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<RequestVerificationModel> requestVerification(
    Map<String, String> data,
  ) async {
    final response = await apiService.post(
      EndPoints.requestVerification,
      data: data,
    );
    return RequestVerificationModel.fromJson(response);
  }

  Future<CommonResponseModel> otpVerification(Map<String, String> data) async {
    final response = await apiService.post(
      EndPoints.otpVerification,
      data: data,
    );
    return CommonResponseModel.fromJson(response);
  }

  Future<SetPasswordModel> setPassword(Map<String, String> data) async {
    final response = await apiService.post(EndPoints.setPassword, data: data);
    return SetPasswordModel.fromJson(response);
  }

  Future<LoginModel> login(Map<String, String> data) async {
    final response = await apiService.post(EndPoints.login, data: data);
    return LoginModel.fromJson(response);
  }

  Future<OnboardingCompletedModel> onboardingCompleted(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.put(
      EndPoints.onboardingCompleted,
      data: data,
    );
    return OnboardingCompletedModel.fromJson(response);
  }

  Future<forgot_password_model> forgot(Map<String, String> data) async {
    final response = await apiService.post(EndPoints.forgot, data: data);
    return forgot_password_model.fromJson(response);
  }

  Future<PregnancyInfoModel> pregnancyInfo(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.pregnancyInfo, data: data);
    return PregnancyInfoModel.fromJson(response);
  }

  Future<MenstrualDashboardPredictModel> menstrualDashboardPredict(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.get(
      EndPoints.menstrualsDashboardPredict,
      params: data,
    );
    return MenstrualDashboardPredictModel.fromJson(response);
  }

  Future<CommonResponseModel> addMenstrual(Map<String, dynamic> data) async {
    final response = await apiService.post(
      EndPoints.addMenstrual,
      data: data,
    );
    return CommonResponseModel.fromJson(response);
  }

  ///--------------Postpartums --------
  Future<PostpartumsAddModel> postpartumsAdd(Map<String, dynamic> data) async {
    final response = await apiService.post(
      EndPoints.postpartumsAdd,
      data: data,
    );
    return PostpartumsAddModel.fromJson(response);
  }

  Future<AddAppointment_Data_Model> addAppointmentApi(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post(
      EndPoints.addAppointment,
      data: data,
    );
    return AddAppointment_Data_Model.fromJson(response);
  }

  Future<AddAppointment_Data_Model> addAppointmentApiPost(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post(
      EndPoints.postpartumsDoctorAppointments,
      data: data,
    );
    return AddAppointment_Data_Model.fromJson(response);
  }


  Future<CommonResponseModel> likeApiPost(String likeId) async {
    final response = await apiService.post(
      EndPoints.likeApi+likeId,
    );
    return CommonResponseModel.fromJson(
      response is Map<String, dynamic> ? response : <String, dynamic>{},
    );
  }

  Future<CommonResponseModel> addCommunityComment(
    String postId,
    String comment,
  ) async {
    final response = await apiService.post(
      EndPoints.communityComment(postId),
      data: {'comment': comment},
    );
    return CommonResponseModel.fromJson(
      response is Map<String, dynamic> ? response : <String, dynamic>{},
    );
  }


  Future<PostSendDataModel> postSendApi(Map<String, dynamic> data,
      ) async {
    final response = await apiService.post(
      EndPoints.postApi,
      data: data,
    );
    return PostSendDataModel.fromJson(response);
  }

  // --- Groups and Group Posts Methods ---
  
  Future<GroupDataModel> getMyGroups() async {
    final response = await apiService.get(EndPoints.getMyGroups);
    return GroupDataModel.fromJson(response);
  }

  Future<CommonResponseModel> addGroupMember(String groupId, Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.addGroupMember(groupId), data: data);
    return CommonResponseModel.fromJson(response);
  }


  Future<Communities_Data_Model> getGroupPosts(String groupId) async {
    final response = await apiService.get(EndPoints.getGroupPosts(groupId));
    return Communities_Data_Model.fromJson(response);
  }

  Future<CommonResponseModel> createGroupPost(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.createGroupPost, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> likeGroupPost(String postId) async {
    final response = await apiService.post(EndPoints.likeGroupPost(postId));
    return CommonResponseModel.fromJson(
      response is Map<String, dynamic> ? response : <String, dynamic>{},
    );
  }

  Future<CommonResponseModel> commentGroupPost(String postId, String comment) async {
    final response = await apiService.post(
      EndPoints.commentGroupPost(postId),
      data: {'comment': comment},
    );
    return CommonResponseModel.fromJson(
      response is Map<String, dynamic> ? response : <String, dynamic>{},
    );
  }

  Future<CommonResponseModel> saveGroupPost(String postId) async {
    final response = await apiService.post(EndPoints.saveGroupPost(postId));
    return CommonResponseModel.fromJson(
      response is Map<String, dynamic> ? response : <String, dynamic>{},
    );
  }

  Future<Communities_Data_Model> getSavedPosts() async {
    final response = await apiService.get(EndPoints.getSavedPosts);
    return Communities_Data_Model.fromJson(response);
  }

  Future<Menstruals_Cycle_model> getMenstrualCycleById(String cycleId) async {
    final response = await apiService.get(EndPoints.getMenstrualCycleById(cycleId));
    return Menstruals_Cycle_model.fromJson(response);
  }

  
  // --- End Groups Methods ---

  Future<Appointment_Data_Model> getAppointmentDataApi() async {
    final response = await apiService.get(EndPoints.getAppointment);
    return Appointment_Data_Model.fromJson(response);
  }

  Future<Appointment_Data_Model> getAppointmentDataApiPost() async {
    final response = await apiService.get(EndPoints.getPostpartumsDoctorAppointments);
    return Appointment_Data_Model.fromJson(response);
  }
  Future<CommonResponseModel> checkModeOnboard(String type) async {
    final response = await apiService.get(EndPoints.checkModeOnboard+type);
    return CommonResponseModel.fromJson(response);
  }

  Future<PregnancyDashboardModel> getPregnancyDataApi() async {
    final response = await apiService.get(EndPoints.getPregnancyDashBoard);
    return PregnancyDashboardModel.fromJson(response);
  }

  /// Formats `date` input into `YYYY-MM-DD` (no time).
  /// Accepts `yyyy-MM-dd`, `dd-MM-yyyy`, or ISO strings containing `T`.
  String _formatDateYmd(String input) {
    final todayYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final trimmed = input.trim();
    if (trimmed.isEmpty) return todayYmd;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      return trimmed;
    }
    try {
      // Handle ISO-8601 timestamps: "2025-10-09T10:15:30Z"
      if (trimmed.contains('T')) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(trimmed));
      }
    } catch (_) {}

    try {
      // Handle existing menstrual/mental endpoints input: "dd-MM-yyyy"
      final parsed = DateFormat('dd-MM-yyyy').parse(trimmed);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {}

    try {
      // Final attempt: let DateTime parse handle it
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(trimmed));
    } catch (_) {}

    return todayYmd;
  }

  Future<Map<String, int>> _getHydrationTotalsForToday() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final hydrationLogsToday = await sl.healthTrackerService.getHydrationLogs(
      from: from,
      to: to,
      page: 1,
      limit: 200,
    );

    final waterIntake =
        hydrationLogsToday.data.fold<int>(0, (sum, log) => sum + log.amountMl);

    final summary = await sl.dashboardService.refresh();
    final target = summary.healthSummary.hydration.goal;

    return {
      'waterIntake': waterIntake,
      'target': target,
    };
  }

  Future<int?> _getSleepQualityForToday() async {
    final now = DateTime.now();
    // "Last night" sleep often starts before midnight, so fetch a broader window.
    final from = now.subtract(const Duration(hours: 40));
    final to = now;

    final sleepResp = await sl.healthTrackerService.getSleepLogs(
      from: from,
      to: to,
      page: 1,
      limit: 200,
    );

    if (sleepResp.data.isEmpty) return null;

    final latest = sleepResp.data.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
    return latest.qualityScore;
  }

  Future<Map<String, dynamic>> _buildDailyLogContractPayload({
    required Map<String, dynamic> input,
    required bool includeSleepQuality,
  }) async {
    final rawDate = input['date']?.toString() ?? '';
    final formattedDate = _formatDateYmd(rawDate);

    final rawMood = input['mood']?.toString() ?? '';
    final score = TrackerMath.moodToScore(rawMood).clamp(1, 10);
    final mood = TrackerMath.scoreToMood(score);

    final notes = input['notes']?.toString() ?? '';

    final hydrationTotals = await _getHydrationTotalsForToday();

    final payload = <String, dynamic>{
      'date': formattedDate,
      'mentalHealth': <String, dynamic>{
        'mood': mood,
        'notes': notes,
        'score': score,
      },
      'hydration': <String, dynamic>{
        'waterIntake': hydrationTotals['waterIntake'],
        'target': hydrationTotals['target'],
      },
    };

    final explicitSleepQuality = () {
      final raw = input['sleepQuality'];
      if (raw is num) return raw.toInt();
      final parsed = int.tryParse(raw?.toString().trim() ?? '');
      return parsed;
    }();
    if (explicitSleepQuality != null) {
      payload['sleepQuality'] = explicitSleepQuality;
    } else if (includeSleepQuality) {
      final sleepQuality = await _getSleepQualityForToday();
      if (sleepQuality != null) payload['sleepQuality'] = sleepQuality;
    }

    // Include Postpartum Recovery scores if present
    if (input.containsKey('physical')) {
      payload['physical'] = input['physical'];
    } else if (input.containsKey('physicalHealing')) {
      // Backward compatibility for old key
      payload['physical'] = input['physicalHealing'];
    }

    if (input.containsKey('uterine')) {
      payload['uterine'] = input['uterine'];
    } else if (input.containsKey('uterineRecovery')) {
      payload['uterine'] = input['uterineRecovery'];
    }

    if (input.containsKey('energy')) {
      payload['energy'] = input['energy'];
    } else if (input.containsKey('energyStrength')) {
      payload['energy'] = input['energyStrength'];
    }

    if (kDebugMode) {
      print("POST PAYLOAD: $payload");
    }
    return payload;
  }

  Future<CommonResponseModel> postPregnancyDataApi({Object? data}) async {
    final input = data is Map
        ? data.cast<String, dynamic>()
        : <String, dynamic>{};

    final payload = await _buildDailyLogContractPayload(
      input: input,
      includeSleepQuality: true,
    );

    final response = await apiService.post(
      EndPoints.pregnancysLogs,
      data: payload,
    );
    return CommonResponseModel.fromJson(response);
  }

  Future<Communities_Data_Model> getCommunitiesDataApi() async {
    final response = await apiService.get(EndPoints.getCommunities);
    return Communities_Data_Model.fromJson(response);
  }

  Future<CommonResponseModel> recoveryProgressAdd(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post(
      EndPoints.postpartumsAppappointment,
      data: data,
    );
    return CommonResponseModel.fromJson(response);
  }

  Future<MentauralCalenderModel> menturalCycleCalender(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post(
      EndPoints.predictCalenderMentrual,
      data: data,
    );
    return MentauralCalenderModel.fromJson(response);
  }

  Future<MenstrualPredictModel> predictMenstrual(
    Map<String, dynamic> data,
  ) async {
    final response = await apiService.post(
      EndPoints.predictMenstrual,
      data: data,
    );
    return MenstrualPredictModel.fromJson(response);
  }

  Future<DashboardCurrentMood> menstrualDashboardMood() async {
    final response = await apiService.get(EndPoints.dashboardCurrentMood);
    return DashboardCurrentMood.fromJson(response);
  }


  Future<MenturalAiInsightsModel> menstrualDashboardAiInsights(Map<String, dynamic>  data) async {
    final response = await apiService.get(EndPoints.menstrualsDashboardInsight,params: data);
    return MenturalAiInsightsModel.fromJson(response);
  }


  Future<CommonResponseModel> postpartumsDoctorAppointmentAdd(Map<String, dynamic>  data ) async {
    final response = await apiService.get(EndPoints.postpartumsDoctorAppointmentAdd,);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> postpartumsLogsAdd(Map<String, dynamic> data) async {
    final payload = await _buildDailyLogContractPayload(
      input: data,
      includeSleepQuality: true,
    );

    final response =
        await apiService.post(EndPoints.postpartumsLogs, data: payload);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> postpartumsJournalAdd(Map<String, dynamic> data) async {
    final payload = await _buildDailyLogContractPayload(
      input: data,
      includeSleepQuality: true,
    );

    final response =
        await apiService.post(EndPoints.postpartumsJournal, data: payload);
    return CommonResponseModel.fromJson(response);
  }

  /// GET postpartum mental logs (used for AI context; Hive only as fallback).
  ///
  /// Backend is expected to return a standard `{ success, message, data }` payload,
  /// where `data` may be a list, a single object, or include a nested `data`.
  Future<CommonResponseModel> getPostpartumsLogs(
      {Map<String, dynamic>? params}) async {
    final response = await apiService.get(
      EndPoints.postpartumsLogs,
      params: params ?? {},
    );

    if (response is Map<String, dynamic>) {
      return CommonResponseModel.fromJson(response);
    }

    return CommonResponseModel(
      success: false,
      message: 'Invalid server response',
      data: response,
    );
  }

  /// Contract-aligned typed model for `GET /api/v1/postpartums/logs`.
  ///
  /// Response is expected to be: `{ success, message, data: [] }`
  Future<MenstrualLogsListModel> getPostpartumLogs({
    Map<String, dynamic>? params,
  }) async {
    final response = await apiService.get(
      EndPoints.postpartumsLogs,
      params: params ?? {},
    );
    return MenstrualLogsListModel.fromJson(response);
  }

  /// Contract-aligned typed model for `GET /api/v1/pregnancys/logs`.
  Future<MenstrualLogsListModel> getPregnancyLogs({
    Map<String, dynamic>? params,
  }) async {
    final response = await apiService.get(
      EndPoints.pregnancysLogs,
      params: params ?? {},
    );
    return MenstrualLogsListModel.fromJson(response);
  }

  Future<DailyLogsMenturalModel> addDailyLogsMentural(Map<String, dynamic> data) async {
    final payload = await _buildDailyLogContractPayload(
      input: data,
      includeSleepQuality: false,
    );

    final response =
        await apiService.post(EndPoints.addDailyLogMentrual, data: payload);
    return DailyLogsMenturalModel.fromJson(response);
  }

  /// GET menstrual logs (optional date filter: dd-MM-yyyy)
  Future<MenstrualLogsListModel> getMenstrualLogs({Map<String, dynamic>? params}) async {
    final response = await apiService.get(EndPoints.addDailyLogMentrual, params: params ?? {});
    return MenstrualLogsListModel.fromJson(response);
  }

  /// Category AI insights — `GET /api/ai/insights?category=&week=` (user id from JWT only).
  Future<MenturalAiInsightsModel> menturalAiInsights(Map<String, dynamic> data) async {
    final response = await apiService.get(EndPoints.insights, params: data);
    if (response is! Map<String, dynamic>) {
      return MenturalAiInsightsModel(
        success: false,
        message: 'Could not reach the server. Check your connection and API URL.',
      );
    }
    return MenturalAiInsightsModel.fromJson(response);
  }

  @Deprecated('Legacy path; use menturalAiInsights / GET /api/v1/ai/insights')
  Future<MenturalAiInsightsModel> getAisInsights(Map<String, dynamic> data) async {
    final response = await apiService.get(EndPoints.getAisInsights, params: data);
    return MenturalAiInsightsModel.fromJson(response);
  }


 Future<GetUserModel> getUser() async {
    final response = await apiService.get(EndPoints.getUser);
    if (response is! Map<String, dynamic>) {
      return GetUserModel(
        success: false,
        message: 'Invalid server response',
      );
    }
    return GetUserModel.fromJson(response);
  }

  Future<PolicyModel> privacyPolicy(String policy) async {
    final response = await apiService.get(EndPoints.privacyPolicy+policy);
    return PolicyModel.fromJson(response);
  }

  Future<CommonResponseModel> updateUserProfile(Map<String,dynamic> data, {File? profileImage}) async {
    if (kDebugMode) {
      print("----- REPOSITORY updateUserProfile CALLED -----");
      print("Has Image: ${profileImage != null}");
    }
    if (profileImage != null) {
      if (kDebugMode) {
        print("Image path: ${profileImage.path}");
      }
      // Send as multipart with file under field name 'photo' (backend expects upload.single("photo"))
      final fields = <String, dynamic>{};
      data.forEach((key, value) {
        if (value is Map) {
          fields[key] = jsonEncode(value);
        } else if (value != null) {
          fields[key] = value;
        }
      });
      if (kDebugMode) {
        print("Sending fields: $fields");
      }
      final files = <String, File>{'photo': profileImage};
      final response = await apiService.putApiMultiPart(
        EndPoints.updateUserProfile,
        fields,
        files,
      );
      if (kDebugMode) {
        print("Multipart response: $response");
      }
      return CommonResponseModel.fromJson(response);
    } else {
      if (kDebugMode) {
        print("No image, sending fallback JSON PUT");
      }
      final response = await apiService.put(EndPoints.updateUserProfile, data: data);
      return CommonResponseModel.fromJson(response);
    }
  }

  Future<Map<String, dynamic>> uploadFile(File file) async {
    final response = await apiService.postApiMultiPart(
      EndPoints.uploadSingleFile,
      {},
      {'file': file},
    );
    return response is Map<String, dynamic> ? response : {};
  }

 Future<CommonResponseModel> addBabygrowths(Map<String, dynamic> data) async {
    final response = await apiService.get(EndPoints.addBabygrowths,params: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<BabyGrowthApiData> babygrowthsDetails() async {
    final response = await apiService.get(EndPoints.babygrowthsDetails,);
    // Support both { success, tracker } and { data: { success, tracker } }
    final Map<String, dynamic> payload = response is Map && response['data'] != null
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return BabyGrowthApiData.fromJson(payload);
  }

  Future<BabyGrowthAddData> babygrowthsAdd(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.babygrowthsAdd,data: data);
    return BabyGrowthAddData.fromJson(response);
  }

  Future<CommonResponseModel> babygrowthsAddPage(Map<String, dynamic> data) async {
    final response = await apiService.put(EndPoints.babygrowthsAddData,data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> babygrowthsUpdate(Map<String, dynamic> data) async {
    final response = await apiService.put(EndPoints.babygrowthsUpdate,data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<Add_Baby_Growth_Data_Model> addBabyGrowthRepo(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.addBabyGrowthApi,data: data);
    return Add_Baby_Growth_Data_Model.fromJson(response);
  }


  Future<BookingDataModel> getBookingApi({required bool isPast}) async {
    final response = await apiService.get(isPast ? EndPoints.getBookingPast  : EndPoints.getBookingUpcoming);
    return BookingDataModel.fromJson(response);
  }

  Future<CommonResponseModel> addMildStone(Map<String,dynamic> fields,Map<String, File>files) async {
    final response = await apiService.postApiMultiPart(EndPoints.addMildStones, fields, files);
    return CommonResponseModel.fromJson(response);
  }

  Future<MilestonesModel> getMildStone() async {
    final response = await apiService.get(EndPoints.getMildStone);
    return MilestonesModel.fromJson(response);
  }

  Future<CommonResponseModel> babygrowthsLogs(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.babygrowthsLogs, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<dynamic> getBabygrowthsDailyLogs() async {
    final response = await apiService.get(EndPoints.getBabygrowthsDailyLogs);
    return response; 
  }

  Future<CommonResponseModel> addBabygrowthsVaccination(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.addBabygrowthsVaccination, data: data);
    return CommonResponseModel.fromJson(response);
  }


  Future<CommonResponseModel> addBabyGrowthPhotos(Map<String,dynamic> fields,Map<String, File>files) async {
    final response = await apiService.postApiMultiPart(EndPoints.addBabyPhotos,fields,files);
    return CommonResponseModel.fromJson(response);
  }

  Future<GetBabyPhotosModel> getBabyGrowthPhotos() async {
    final response = await apiService.get(EndPoints.getBabyPhotos);
    return GetBabyPhotosModel.fromJson(response);
  }

  Future<VaccinationModel> getAllVaccinations() async {
    final response = await apiService.get(EndPoints.getVaccinations);
    return VaccinationModel.fromJson(response);
  }

  Future<CommonResponseModel> getFeeding() async {
    final response = await apiService.get(EndPoints.feedingGet);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> addFeeding(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.feedingAdd, data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<CommonResponseModel> updateVaccinations(Map<String,dynamic> data,String vacId) async {
    final response = await apiService.put(EndPoints.updateVaccinations+vacId,data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<BookingAddModel> bookingAdd(Map<String,dynamic> data) async {
    final response = await apiService.post(EndPoints.bookingAdd,data: data);
    return BookingAddModel.fromJson(response);
  }

  Future<CommonResponseModel> cancelBooking(String id) async {
    final response = await apiService.delete(EndPoints.cancelBooking + id);
    return CommonResponseModel.fromJson(response);
  }

  Future<DoctorDataModel> getDoctorApi(
      Map<String, dynamic> data,
      ) async {
    final response = await apiService.get(
      EndPoints.getDoctorApi,
      params: data,
    );
    return DoctorDataModel.fromJson(response);
  }

  Future<AvailableSlotDataModel> getSlotApi(
      String doctorId,
      Map<String, dynamic> data,
      ) async {
    final response = await apiService.get(
      EndPoints.getAvailableSlotApi(doctorId),
      params: data,
    );
    return AvailableSlotDataModel.fromJson(response);
  }

  /// Live-slots grid (Section B §8). Same caller contract as [getSlotApi] but
  /// hits the richer `/doctors/:id/live-slots` endpoint and returns the typed
  /// `LiveSlotsResponse` (per-slot AVAILABLE/HELD/BOOKED/PAST + `until` chip).
  Future<LiveSlotsResponse> getDoctorLiveSlots(
    String doctorId,
    Map<String, dynamic> params,
  ) async {
    final response = await apiService.get(
      EndPoints.getDoctorLiveSlotsApi(doctorId),
      params: params,
    );
    return LiveSlotsResponse.fromJson(
      response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map),
    );
  }


  ///---------------------------AI CHAT


  Future<CreateAiChatRoomModel> createChatRoom() async {
    final response = await apiService.post(EndPoints.aiChatCreateRoom);
    return CreateAiChatRoomModel.fromJson(response);
  }

  Future<GetAiChatModel> getAllAiChat() async {
    final response = await apiService.get(EndPoints.aiChatAllMessages);
    return GetAiChatModel.fromJson(response);
  }

  Future<CreateAiChatModel> createAiChat(Map<String,dynamic> data) async {
    final response = await apiService.post(EndPoints.aiChatSendMessage,data: data);
    return CreateAiChatModel.fromJson(response);
  }
  ///---------------------------Subscription

  Future<GetAllPlansModel> getSubscriptionPlan() async {
    final response = await apiService.get(EndPoints.getAllSubscriptionPlan);
    return GetAllPlansModel.fromJson(response);
  }

  Future<CommonResponseModel> addSubscriptionPlan(Map<String,dynamic> data) async {
    final response = await apiService.post(EndPoints.subscriptionsAdd,data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<dynamic> directChat(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.directChat, data: data);
    return response;
  }

  Future<dynamic> streamChat(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.streamChat, data: data);
    return response;
  }


  Future<Subscription_Data_Model> getMySubscription() async {
    final response = await apiService.get(EndPoints.getMySubscription);
    return Subscription_Data_Model.fromJson(response);
  }

  Future<GetAllPlansModel> getPublicPlans() async {
    final response = await apiService.get(EndPoints.getPublicPlans);
    return GetAllPlansModel.fromJson(response);
  }

  Future<dynamic> getNotifications(String userId) async {
    final response = await apiService.get(EndPoints.getNotifications(userId));
    return response;
  }




  Future<PostpartumsAddModel> recoveryTask(Map<String, dynamic> data,String? id) async {
    final response = await apiService.post(EndPoints.recoveryTask+(id ?? ""), data: data);
    return PostpartumsAddModel.fromJson(response);
  }

  Future<RecoveryProgressModel> getRecoveryTask(Map<String, dynamic> data) async {
    final response = await apiService.get(EndPoints.getRecoveryTask, params: data);
    return RecoveryProgressModel.fromJson(response);
  }


  Future<ConsultationDataModel> consultationRepo(Map<String, String> data, Map<String, File> filesData) async {
    final response = await apiService.postApiMultiPart(
      EndPoints.medicalRecordUpload, data, filesData
    );
    return ConsultationDataModel.fromJson(response);
  }



  Future<TokenGeneratorModel> getCallTokenGeneratorApi(Map data) async {
    dynamic response = await apiService.post(EndPoints.agoraRtcTokenApi, data: data);
    return TokenGeneratorModel.fromJson(response);
  }


}
