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
import 'package:flutter/foundation.dart';
import '../../agora/agora.dart';
import '../../controller/ai_assistant/model/chat_room_create_model.dart';
import '../../controller/ai_assistant/model/create_ai_chat_model.dart';
import '../../controller/baby_growth/model/add_baby_growth_data_model.dart';
import '../../controller/experts_consultation/model/ConsultationDataModel.dart';
import '../../controller/experts_consultation/model/availableslotdatamodel.dart';
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
import '../../controller/pregnancy_flow/model/addAppointment_data_model.dart';
import '../../controller/pregnancy_flow/model/postsenddatamodel.dart';
import '../../controller/pregnancy_flow/model/pregnancy_data_model.dart';
import '../network/end_points.dart';
import '../network/network_api_services.dart';
import '../../controller/create_account/model/request_verification_model.dart';

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
    return CommonResponseModel.fromJson(response);
  }


  Future<PostSendDataModel> postSendApi(Map<String, dynamic> data,
      ) async {
    final response = await apiService.post(
      EndPoints.postApi,
      data: data,
    );
    return PostSendDataModel.fromJson(response);
  }

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

  Future<CommonResponseModel> postPregnancyDataApi({Object? data}) async {
    final response = await apiService.post(EndPoints.pregnancysLogs,data: data);
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
    final response = await apiService.post(EndPoints.postpartumsLogs,data: data);
    return CommonResponseModel.fromJson(response);
  }

  Future<DailyLogsMenturalModel> addDailyLogsMentural(Map<String, dynamic> data) async {
    final response = await apiService.post(EndPoints.addDailyLogMentrual,data: data);
    return DailyLogsMenturalModel.fromJson(response);
  }

  Future<dynamic> addMenstrual(Map<String, dynamic> data) async {
    final response = await apiService.post(
      EndPoints.addMenstrual,
      data: data,
    );
    return response;
  }

 Future<MenturalAiInsightsModel> menturalAiInsights(Map<String, dynamic> data) async {
    final response = await apiService.get(EndPoints.insights,params: data);
    return MenturalAiInsightsModel.fromJson(response);
  }

 Future<GetUserModel> getUser() async {
    final response = await apiService.get(EndPoints.getUser);
    return GetUserModel.fromJson(response);
  }

  Future<PolicyModel> privacyPolicy(String policy) async {
    final response = await apiService.get(EndPoints.privacyPolicy+policy);
    return PolicyModel.fromJson(response);
  }

  Future<CommonResponseModel> updateUserProfile(Map<String,dynamic> data, {File? profileImage}) async {
    print("----- REPOSITORY updateUserProfile CALLED -----");
    print("Has Image: ${profileImage != null}");
    if (profileImage != null) {
      print("Image path: ${profileImage.path}");
      // Send as multipart with file under field name 'photo' (backend expects upload.single("photo"))
      final fields = <String, dynamic>{};
      data.forEach((key, value) {
        if (value is Map) {
          fields[key] = jsonEncode(value);
        } else if (value != null) {
          fields[key] = value;
        }
      });
      print("Sending fields: $fields");
      final files = <String, File>{'photo': profileImage};
      final response = await apiService.putApiMultiPart(
        EndPoints.updateUserProfile,
        fields,
        files,
      );
      print("Multipart response: $response");
      return CommonResponseModel.fromJson(response);
    } else {
      print("No image, sending fallback JSON PUT");
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
    return BabyGrowthApiData.fromJson(response);
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
