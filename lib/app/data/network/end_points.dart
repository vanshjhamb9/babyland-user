import 'package:babyland/core/environment/app_environment.dart';

class EndPoints {
  static String get baseUrl => AppEnvironment.baseUrl;
  static String get apiRoot => AppEnvironment.apiRoot;

  static String get agoraRtcTokenApi => '${baseUrl}/agoras/rtc';
  static String get checkModeOnboard => '${baseUrl}/users/check-mode-onboard/';

  static String get requestVerification => '${baseUrl}/auth/request-verification';
  static String get otpVerification => '${baseUrl}/auth/verification';
  static String get setPassword => '${baseUrl}/auth/set-password';
  static String get login => '${baseUrl}/auth/login-with-password';
  static String get onboardingCompleted => '${baseUrl}/users/onboarding/complete';
  static String get forgot => '${baseUrl}/auth/request-forget-password';

  static String get signup => '${baseUrl}/auth/signup';
  static String get sendOtp => '${baseUrl}/auth/send-otp';
  static String get verifyOtp => '${baseUrl}/auth/verify-otp';
  static String get googleLogin => '${baseUrl}/auth/google';
  static String get appleLogin => '${baseUrl}/auth/apple';
  static String get updatePhone => '${baseUrl}/auth/update-phone';
  static String get authRefresh => '${baseUrl}/auth/refresh';
  static String get authsRefresh => '${baseUrl}/auth/refresh';

  static String get menstrualsDashboardPredict =>
      '${baseUrl}/menstruals/dashboard/predict';
  static String get predictMenstrual => '${baseUrl}/menstruals/predict';
  static String getMenstrualCycleById(String cycleId) =>
      '${baseUrl}/menstruals/cycle/$cycleId';
  static String get getMenstrualLogs => '${baseUrl}/menstruals/logs';

  static String get pregnancyInfo => '${baseUrl}/pregnancys/info';
  static String get addAppointment => '${baseUrl}/pregnancys/doctor-appointment';
  static String get getAppointment => '${baseUrl}/pregnancys/doctor-appointments';
  static String get getPregnancyDashBoard =>
      '${baseUrl}/pregnancys/dashboard/predict';
  static String get pregnancysLogs => '${baseUrl}/pregnancys/logs';
  static String get pregnancysSymptom => '${baseUrl}/pregnancys/symptom';
  static String get getPregnancyPredict => '${baseUrl}/pregnancys/predict';

  static String get getCommunities => '${baseUrl}/communities/all';
  static String get likeApi => '${baseUrl}/communities/toggle-like/';
  static String get postApi => '${baseUrl}/communities/add';
  static String communityComment(String postId) =>
      '${baseUrl}/communities/comment/$postId';

  static String get getMyGroups => '${baseUrl}/groups/my';
  static String getGroupPosts(String id) => '${baseUrl}/groups/$id/posts';
  static String get createGroupPost => '${baseUrl}/posts';
  static String likeGroupPost(String id) => '${baseUrl}/posts/$id/like';
  static String commentGroupPost(String id) =>
      '${baseUrl}/posts/$id/comment';
  static String saveGroupPost(String id) => '${baseUrl}/posts/$id/save';
  static String get getSavedPosts => '${baseUrl}/posts/saved';
  static String addGroupMember(String groupId) =>
      '${baseUrl}/groups/$groupId/members';

  static String get postpartumsAdd => '${baseUrl}/postpartums/add';
  static String get postpartumsDoctorAppointments =>
      '${baseUrl}/postpartums/doctor-appointment';
  static String get getPostpartumsDoctorAppointments =>
      '${baseUrl}/postpartums/doctor-appointments';
  static String get menstruals => '${baseUrl}/menstruals/cycles';

  static String get insights => '${apiRoot}/ai/insights';
  static String get menstrualsDashboardInsight =>
      '${baseUrl}/menstruals/dashboard/insight';
  static String get addDailyLogMentrual => '${baseUrl}/menstruals/logs';
  static String get addMenstrual => '${baseUrl}/menstruals/add-cycle';
  static String get dashboardCurrentMood =>
      '${baseUrl}/menstruals/dashboard/current-mood';
  static String get predictCalenderMentrual =>
      '${baseUrl}/menstruals/dashboard/predict-calender';
  static String get postpartumsDoctorAppointmentAdd =>
      '${baseUrl}/postpartums/doctor-appointment';
  static String get recoveryProgressAdd =>
      '${baseUrl}/postpartums/recovery-task/add/';
  static String get postpartumsAppappointment =>
      '${baseUrl}/postpartums/doctor-appointment';
  static String get feedingGet => '${baseUrl}/postpartums/feeding';
  static String get feedingAdd => '${baseUrl}/postpartums/feeding/add';
  static String get getPostpartumRecoveryTasks =>
      '${baseUrl}/postpartums/get/recovery-task';
  static String get postpartumsLogsAdd => '${baseUrl}/postpartums/logs';

  static String get getBookingUpcoming => '${baseUrl}/consultations/upcoming';
  static String get getBookingPast => '${baseUrl}/consultations/past';
  static String get getDoctorApi => '${baseUrl}/doctors/doctors';
  static String getAvailableSlotApi(String doctorId) =>
      '${baseUrl}/consultations/doctor/$doctorId/available-slots';
  static String getDoctorLiveSlotsApi(String doctorId) =>
      '${baseUrl}/doctors/$doctorId/live-slots';
  static String get bookingAdd => '${baseUrl}/consultations/add';
  static String get cancelBooking => '${baseUrl}/consultations/cancel/';
  static String get medicalRecordUpload => '${baseUrl}/medical-record/upload';
  static String get medicalRecordGetAll => '${baseUrl}/medical-record/gettall';

  static String get patientConsultationSlotLock =>
      '${baseUrl}/patient/consultations/slot-lock';
  static String patientConsultationSlotLockByToken(String lockToken) =>
      '${baseUrl}/patient/consultations/slot-lock/$lockToken';
  static String get patientConsultationPhonePeIntent =>
      '${baseUrl}/patient/consultations/payments/phonepe/intent';
  static String patientConsultationProjection(String consultationId) =>
      '${baseUrl}/patient/consultations/$consultationId/projection';
  static String patientConsultationPaymentProjection(
    String merchantTransactionId,
  ) =>
      '${baseUrl}/patient/consultations/payments/$merchantTransactionId/projection';

  static String get postpartumsLogs => '${baseUrl}/postpartums/logs';
  static String get postpartumsJournal => '${baseUrl}/postpartums/journal';
  static String get getUser => '${baseUrl}/users/getUser';
  static String get updateUserProfile => '${baseUrl}/users/profile-update';
  static String get uploadFiles => '${baseUrl}/upload';
  static String get uploadSingleFile => '${baseUrl}/fileuploads/single';

  static String get addBabygrowths => '${baseUrl}/babygrowths/add';
  static String get babygrowthsDetails => '${baseUrl}/babygrowths/get';
  static String get babygrowthsAdd => '${baseUrl}/babygrowths/add';
  static String get babygrowthsUpdate => '${baseUrl}/babygrowths/update';
  static String get babygrowthsAddData => '${baseUrl}/babygrowths/';
  static String get addMildStones => '${baseUrl}/babygrowths/add/milestone';
  static String get getMildStone => '${baseUrl}/babygrowths/get/milestones';
  static String get getBabyPhotos => '${baseUrl}/babygrowths/get/photos';
  static String get addBabyPhotos => '${baseUrl}/babygrowths/add/photo';
  static String get getVaccinations => '${baseUrl}/babygrowths/get/vaccinations';
  static String get updateVaccinations =>
      '${baseUrl}/babygrowths/update/vaccination/status/';
  static String get addBabyGrowthApi => '${baseUrl}/babygrowths/add/baby-growth';
  static String get babygrowthsLogs => '${baseUrl}/babygrowths/logs';
  static String get getBabygrowthsDailyLogs =>
      '${baseUrl}/babygrowths/get/daily-logs';
  static String get addBabygrowthsVaccination =>
      '${baseUrl}/babygrowths/add/vaccination';

  static String get getAllSubscriptionPlan => '${baseUrl}/plans/get-all';
  static String get subscriptionsAdd => '${baseUrl}/subscriptions/add';
  static String get getMySubscription => '${baseUrl}/subscriptions/me';
  /// iOS StoreKit receipt / transaction verification → activates 1-month Pro.
  static String get subscriptionsAppleVerify =>
      '${baseUrl}/subscriptions/apple/verify';
  static String get getPublicPlans => '${baseUrl}/plans/public';

  /// UGC moderation (Guideline 1.2).
  static String get moderationReports => '${baseUrl}/moderation/reports';
  static String blockUser(String userId) => '${baseUrl}/users/$userId/block';
  static String get blockedUsers => '${baseUrl}/users/blocked';

  /// Permanent account deletion (Guideline 5.1.1(v)).
  static String get deleteAccount => '${baseUrl}/users/me';

  static String get aiChatCreateRoom => '${baseUrl}/aichats/create-chat';
  static String get aiChatAllMessages => '${baseUrl}/aichats/all-messages';
  static String get aiChatSendMessage => '${baseUrl}/aichats/send-message';

  static String get recoveryTask => '${baseUrl}/postpartums/recovery-task/add/';
  static String get getRecoveryTask =>
      '${baseUrl}/postpartums/get/recovery-task/';

  @Deprecated('Use insights (GET /api/v1/ai/insights) per API contract')
  static String get getAisInsights => '${baseUrl}/aisinsights/';
  static String get directChat => '${baseUrl}/chat/';
  static String get streamChat => '${baseUrl}/chat/stream';
  static String getNotifications(String userId) =>
      '${baseUrl}/notifications/getAll/$userId';

  static String get privacyPolicy => '${baseUrl}/policies/';
  static String get returnPolicy => '${baseUrl}/policies/return';
  static String get termPolicy => '${baseUrl}/policies/terms';
  static String get shippingPolicy => '${baseUrl}/policies/shipping';
}
