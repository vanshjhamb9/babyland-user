import 'package:babyland/core/environment/app_environment.dart';

/// Centralized API endpoint definitions.
/// All endpoints are relative to the base URL.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Base ───────────────────────────────────────────────
  static String get baseUrl => AppEnvironment.baseUrl;

  /// API root without `/v1` — category insights mount at `/api/ai/insights`.
  static String get apiRoot => AppEnvironment.apiRoot;

  /// Full URL for `GET /api/ai/insights` (Dio accepts absolute paths).
  static String get aiInsightsCategory => '$apiRoot/ai/insights';

  // ─── Authentication ─────────────────────────────────────
  static const String requestVerification = '/auth/send-otp';
  static const String otpVerification = '/auth/verify-otp';
  static const String setPassword = '/auth/signup';
  static const String login = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authsRefresh = '/auth/refresh';
  static const String forgotPassword = '/auth/request-forget-password';

  // ─── User ───────────────────────────────────────────────
  static const String getUser = '/patients/me';
  static const String profileUpdate = '/patients/me';
  static const String onboardingComplete = '/patients/me/onboarding/complete';
  static String checkModeOnboard(String type) =>
      '/patients/check-mode-onboard/$type';

  // ─── AI Chat (New Endpoints) ────────────────────────────
  static const String chat = '/chat';
  static const String chatStream = '/chat/stream';

  // ─── AI Assistant (NEW Gateway) ─────────────────────────
  static const String aiChat = '/ai/chat';
  static const String aiChatVoice = '/ai/chat/voice';
  static const String aiFeedback = '/ai/feedback';
  static const String aiHealth = '/ai/health';
  static const String aiInsights = '/ai/insights';
  static const String aiMemoryStore = '/ai/memory/store';
  static const String aiObserverEvent = '/ai/observer/event';

  // ─── AI Intelligence ────────────────────────────────────
  static const String aiRecommendations = '/ai/recommendations';
  static const String aiPredictiveAlerts = '/ai/predictive-alerts';
  static const String aiTrends = '/ai/trends';
  static const String aiAnalysis = '/ai/analysis';

  // ─── AI Assistant ────────────────────────────────────────
  static const String legacyAiCreateRoom = '/aichats/create-chat';
  static const String legacyAiAllMessages = '/aichats/all-messages';
  static const String legacyAiSendMessage = '/aichats/send-message';

  // ─── Pregnancy ──────────────────────────────────────────
  static const String pregnancyInfo = '/pregnancys/info';
  static const String pregnancyDoctorAppointment =
      '/pregnancys/doctor-appointment';
  static const String pregnancyDoctorAppointments =
      '/pregnancys/doctor-appointments';
  static const String pregnancyDashboardPredict =
      '/pregnancys/dashboard/predict';
  static const String pregnancyLogs = '/pregnancys/logs';

  // ─── Community ──────────────────────────────────────────
  static const String communitiesAll = '/communities/all';
  static String communityToggleLike(String id) =>
      '/communities/toggle-like/$id';
  static const String communityAdd = '/communities/add';

  // ─── Menstrual ──────────────────────────────────────────
  static const String menstrualDashboardPredict =
      '/menstruals/dashboard/predict';
  static const String menstrualPredict = '/menstruals/predict';
  static const String menstrualAddCycle = '/menstruals/add-cycle';
  static const String menstrualLogs = '/menstruals/logs';
  static const String menstrualDashboardMood =
      '/menstruals/dashboard/current-mood';
  static const String menstrualDashboardInsight =
      '/menstruals/dashboard/insight';
  static const String menstrualPredictCalendar =
      '/menstruals/dashboard/predict-calender';

  // ─── Postpartum ─────────────────────────────────────────
  static const String postpartumAdd = '/postpartums/add';
  static const String postpartumDoctorAppointment =
      '/postpartums/doctor-appointment';
  static const String postpartumDoctorAppointments =
      '/postpartums/doctor-appointments';
  static const String postpartumLogs = '/postpartums/logs';
  static const String postpartumJournal = '/postpartums/journal';
  static const String postpartumFeeding = '/postpartums/feeding';
  static const String postpartumFeedingAdd = '/postpartums/feeding/add';
  static const String postpartumAiInsights = '/postpartums/ai-insights';
  static String postpartumRecoveryTask(String? id) =>
      '/postpartums/recovery-task/add/${id ?? ""}';
  static String getRecoveryTask = '/postpartums/get/recovery-task/';

  // ─── Baby Growth ────────────────────────────────────────
  static const String babyGrowthAdd = '/babygrowths/add';
  static const String babyGrowthGet = '/babygrowths/get';
  static const String babyGrowthUpdate = '/babygrowths/update';
  static const String babyGrowthAddMilestone = '/babygrowths/add/milestone';
  static const String babyGrowthGetMilestones = '/babygrowths/get/milestones';
  static const String babyGrowthGetPhotos = '/babygrowths/get/photos';
  static const String babyGrowthAddPhoto = '/babygrowths/add/photo';
  static const String babyGrowthGetVaccinations =
      '/babygrowths/get/vaccinations';
  static String babyGrowthUpdateVaccination(String id) =>
      '/babygrowths/update/vaccination/status/$id';
  static const String babyGrowthAddGrowth = '/babygrowths/add/baby-growth';

  // ─── Expert Consultation ────────────────────────────────
  static const String bookingUpcoming = '/consultations/upcoming';
  static const String bookingPast = '/consultations/past';
  static const String bookingAdd = '/consultations/add';
  static String bookingCancel(String id) => '/consultations/cancel/$id';
  static const String doctors = '/doctors/doctors';
  static String doctorAvailableSlots(String doctorId) =>
      '/consultations/doctor/$doctorId/available-slots';

  /// Live-slots grid (Section B §8). Pass `date=YYYY-MM-DD` + `includePast=false`
  /// as query parameters. Richer per-slot status than the legacy endpoint.
  static String doctorLiveSlots(String doctorId) =>
      '/doctors/$doctorId/live-slots';

  /// Patient consultation — slot lock & PhonePe (server projection is source of truth).
  static const String patientConsultationSlotLock =
      '/patient/consultations/slot-lock';
  static String patientConsultationSlotLockByToken(String lockToken) =>
      '/patient/consultations/slot-lock/$lockToken';
  static const String patientConsultationPhonePeIntent =
      '/patient/consultations/payments/phonepe/intent';
  static String patientConsultationProjection(String consultationId) =>
      '/patient/consultations/$consultationId/projection';
  static String patientConsultationPaymentProjection(
    String merchantTransactionId,
  ) => '/patient/consultations/payments/$merchantTransactionId/projection';

  static const String medicalRecordUpload = '/medical-record/upload';

  // ─── Subscription ───────────────────────────────────────
  static const String getAllPlans = '/plans/get-all';
  static const String subscriptionAdd = '/payments/create';

  // ─── Policies ───────────────────────────────────────────
  static String policy(String type) => '/policies/$type';

  // ─── File Upload ────────────────────────────────────────
  static const String uploadSingleFile = '/fileuploads/single';

  // ─── Video Call (Agora) ─────────────────────────────────
  static const String agoraRtcToken = '/agoras/rtc';

  // ─── Phase 3 Health Trackers ────────────────────────────

  // Hydration Tracker
  static const String hydration = '/hydration';
  static String hydrationById(String id) => '/hydration/$id';

  // Sleep Tracker
  static const String sleep = '/sleep';
  static String sleepById(String id) => '/sleep/$id';

  // Symptom Tracker
  static const String symptoms = '/symptoms';
  static String symptomById(String id) => '/symptoms/$id';

  // Medication Tracker
  static const String medication = '/medication';
  static String medicationById(String id) => '/medication/$id';

  // Supplement Tracker
  static const String supplements = '/supplements';
  static String supplementById(String id) => '/supplements/$id';

  // Baby Growth Tracker (Phase 3)
  static const String babyGrowthV1 = '/baby-growth';
  static String babyGrowthV1ById(String id) => '/baby-growth/$id';

  // Postpartum Recovery Tracker (Phase 3)
  static const String postpartumRecovery = '/postpartum-recovery';
  static String postpartumRecoveryById(String id) => '/postpartum-recovery/$id';
  static const String postpartumLog = '/postpartum-log';
  static String patientPostpartumLogs(String userId) =>
      '/postpartum-logs/patient/$userId';

  // ─── Dashboard & Health Insights ────────────────────────
  static const String healthInsights = '/health-insights';
  static const String predictiveAlerts = '/predictive-alerts';
  static const String recommendations = '/recommendations';

  // ─── System Health ─────────────────────────────────────
  static const String systemHealth = '/health';
}
