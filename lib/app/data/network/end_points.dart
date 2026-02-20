class EndPoints {
  static const String baseUrl = "https://api-babyland.duckdns.org/api";
  // static const String baseUrl = "https://baby-land-node-servers.onrender.com/api";
  // static const String baseUrl = "http://91.203.133.76:5000/api";

  /* ---------------- video call -----------------------------------------  */
  static const String agoraRtcTokenApi = "$baseUrl/agoras/rtc";


  static const String checkModeOnboard = "$baseUrl/users/check-mode-onboard/";


  /* ---------------- Authentication -----------------------------------------  */
   static const String requestVerification = "$baseUrl/auths/request-verification";
   static const String otpVerification = "$baseUrl/auths/verification";
   static const String setPassword = "$baseUrl/auths/set-password";
   static const String login = "$baseUrl/auths/login-with-password";
   static const String onboardingCompleted = "$baseUrl/users/onboarding/complete";
   static const String forgot = "$baseUrl/auths/request-forget-password";

  static const String menstrualsDashboardPredict = "$baseUrl/menstruals/dashboard/predict";
  static const String predictMenstrual = "$baseUrl/menstruals/predict";

   //pregnancy
  static const String pregnancyInfo = "$baseUrl/pregnancys/info";
  static const String addAppointment = "$baseUrl/pregnancys/doctor-appointment";
  static const String getAppointment = "$baseUrl/pregnancys/doctor-appointments";
  static const String getPregnancyDashBoard = "$baseUrl/pregnancys/dashboard/predict";
  // static const String getPregnancy = "$baseUrl/pregnancys/info";
  static const String pregnancysLogs = "$baseUrl/pregnancys/logs";
  static const String getCommunities = "$baseUrl/communities/all";
  static const String likeApi = "$baseUrl/communities/toggle-like/";
  static const String postApi = "$baseUrl/communities/add";

  //post pregnancy
  static const String postpartumsAdd = "$baseUrl/postpartums/add";
  static const String postpartumsDoctorAppointments = "$baseUrl/postpartums/doctor-appointment";
  static const String getPostpartumsDoctorAppointments = "$baseUrl/postpartums/doctor-appointments";
  static const String menstruals = "$baseUrl/menstruals/cycles";

  static const String insights = "$baseUrl/ai/insights";
  static const String menstrualsDashboardInsight = "$baseUrl/menstruals/dashboard/insight";
  static const String addDailyLogMentrual = "$baseUrl/menstruals/logs";
  static const String addMenstrual = "$baseUrl/menstruals/add-cycle";
  static const String dashboardCurrentMood = "$baseUrl/menstruals/dashboard/current-mood";
  static const String predictCalenderMentrual = "$baseUrl/menstruals/dashboard/predict-calender";
  static const String postpartumsDoctorAppointmentAdd = "$baseUrl/postpartums/doctor-appointment";
  static const String recoveryProgressAdd = "$baseUrl/postpartums/recovery-task/add/";
  static const String postpartumsAppappointment = "$baseUrl/postpartums/doctor-appointment";
  static const String feedingGet = "$baseUrl/postpartums/feeding";
  static const String feedingAdd = "$baseUrl/postpartums/feeding/add";


  /// Expert Consultation Screens
  static const String getBookingUpcoming = "$baseUrl/bookings/upcoming";
  static const String getBookingPast = "$baseUrl/bookings/past";
  static const String getDoctorApi = "$baseUrl/doctors/doctors";
  /// Dynamic: pass doctorId to build the URL
  static String getAvailableSlotApi(String doctorId) =>
      "$baseUrl/bookings/doctor/$doctorId/available-slots";
  static const String bookingAdd = "$baseUrl/bookings/add";
  static const String cancelBooking = "$baseUrl/bookings/cancel/";
  static const String medicalRecordUpload = "$baseUrl/medical-record/upload";
  static const String medicalRecordGetAll = "$baseUrl/medical-record/gettall";

  static const String postpartumsLogs = "$baseUrl/postpartums/logs";
  static const String getUser = "$baseUrl/users/getUser";
  static const String updateUserProfile = "$baseUrl/users/profile-update";
  static const String uploadFiles = "$baseUrl/upload"; // legacy generic upload
  static const String uploadSingleFile = "$baseUrl/fileuploads/single";


  //baby growth

  static const String addBabygrowths = "$baseUrl/babygrowths/add";
  static const String babygrowthsDetails = "$baseUrl/babygrowths/get";
  static const String babygrowthsAdd = "$baseUrl/babygrowths/add";
  static const String babygrowthsUpdate = "$baseUrl/babygrowths/update";
  static const String babygrowthsAddData = "$baseUrl/babygrowths/";
  static const String addMildStones = "$baseUrl/babygrowths/add/milestone";
  static const String getMildStone = "$baseUrl/babygrowths/get/milestones";
  static const String getBabyPhotos = "$baseUrl/babygrowths/get/photos";
  static const String addBabyPhotos = "$baseUrl/babygrowths/add/photo";
  static const String getVaccinations = "$baseUrl/babygrowths/get/vaccinations";
  static const String updateVaccinations = "$baseUrl/babygrowths/update/vaccination/status/";
  static const String addBabyGrowthApi = "$baseUrl/babygrowths/add/baby-growth";

///------------------------------------Subscription
  static const String getAllSubscriptionPlan = "$baseUrl/plans/get-all";
  static const String subscriptionsAdd = "$baseUrl/subscriptions/add";

  ///------------------------------------AI CHAT

  static const String aiChatCreateRoom = '$baseUrl/aichats/create-chat';
  static const String aiChatAllMessages = '$baseUrl/aichats/all-messages';
  static const String aiChatSendMessage = '$baseUrl/aichats/send-message';

///------------------------------------Postpartum Api
  static const String recoveryTask = '$baseUrl/postpartums/recovery-task/add/';
  static const String getRecoveryTask = '$baseUrl/postpartums/get/recovery-task/';


//policies
  static const String privacyPolicy = '$baseUrl/policies/';
  static const String returnPolicy = '$baseUrl/policies/return';
  static const String termPolicy = '$baseUrl/policies/terms';
  static const String shippingPolicy = '$baseUrl/policies/shipping';

}
