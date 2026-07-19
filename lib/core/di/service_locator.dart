import '../ai/ai_context_builder.dart';
import '../ai/ai_gateway_service.dart';
import '../ai/ai_observability_service.dart';
import '../ai/ai_response_parser.dart';
import '../ai/ai_risk_detector.dart';
import '../network/api_client.dart';
import '../services/ai_service.dart';
import '../services/ai_intelligence_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/dashboard_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/health_tracker_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../../features/ai_assistant/repositories/ai_chat_repository.dart';
import '../../features/ai_insights/repositories/ai_insights_repository.dart';
import '../../features/ai_insights/services/ai_notification_service.dart';
import '../../features/symptom_checker/repositories/symptom_checker_repository.dart';
import '../../features/smart_community/repositories/smart_community_repository.dart';
import '../../features/conversation_memory/repositories/conversation_memory_repository.dart';

/// Simple service locator for dependency injection.
/// Initializes all core services and provides them to the app.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  factory ServiceLocator() => _instance;

  // Core services
  late final AuthService authService;
  late final ApiClient apiClient;
  late final CacheService cacheService;
  late final AIService aiService;
  late final AiGatewayService aiGatewayService;
  late final AiContextBuilder aiContextBuilder;
  late final AiResponseParser aiResponseParser;
  late final AiRiskDetector aiRiskDetector;
  late final AiObservabilityService aiObservabilityService;
  late final AnalyticsService analyticsService;
  late final NotificationService notificationService;
  late final ConnectivityService connectivityService;
  
  // New integration services
  late final HealthTrackerService healthTrackerService;
  late final DashboardService dashboardService;
  late final FirebasePhoneAuthService firebasePhoneAuthService;
  late final UserService userService;
  late final AIIntelligenceService aiIntelligenceService;

  // Repositories
  late final AiChatRepository aiChatRepository;
  late final AiInsightsRepository aiInsightsRepository;
  late final SymptomCheckerRepository symptomCheckerRepository;
  late final SmartCommunityRepository smartCommunityRepository;
  late final ConversationMemoryRepository conversationMemoryRepository;

  // AI Notification Service
  late final AiNotificationService aiNotificationService;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Auth service (must be first — API client depends on it)
    authService = AuthService();

    firebasePhoneAuthService = FirebasePhoneAuthService();

    // 2. API client
    apiClient = ApiClient(authService: authService);

    // 3. Cache service
    cacheService = CacheService();
    await cacheService.init();

    // 4. Analytics service
    analyticsService = AnalyticsService();
    await analyticsService.init();

    // 5. AI core integration services
    aiContextBuilder = AiContextBuilder();
    aiResponseParser = AiResponseParser();
    aiRiskDetector = AiRiskDetector();
    aiGatewayService = AiGatewayService(apiClient: apiClient);
    aiObservabilityService = AiObservabilityService(
      analyticsService: analyticsService,
      apiClient: apiClient,
    );

    // 6. AI service
    aiService = AIService(
      apiClient: apiClient,
      authService: authService,
      analyticsService: analyticsService,
      gatewayService: aiGatewayService,
      contextBuilder: aiContextBuilder,
      responseParser: aiResponseParser,
      riskDetector: aiRiskDetector,
      observabilityService: aiObservabilityService,
    );

    // 7. Notification service
    notificationService = NotificationService();

    // 8. Connectivity service
    connectivityService = ConnectivityService();
    await connectivityService.init();

    // 9. New integration services
    healthTrackerService = HealthTrackerService(apiClient: apiClient);
    dashboardService = DashboardService(apiClient: apiClient);
    userService = UserService(apiClient: apiClient);
    aiIntelligenceService = AIIntelligenceService(apiClient: apiClient);

    // 10. Repositories
    aiChatRepository = AiChatRepository(
      aiService: aiService,
      cacheService: cacheService,
    );

    aiInsightsRepository = AiInsightsRepository(
      apiClient: apiClient,
      cacheService: cacheService,
      connectivityService: connectivityService,
    );

    symptomCheckerRepository = SymptomCheckerRepository(
      aiService: aiService,
    );

    smartCommunityRepository = SmartCommunityRepository(
      apiClient: apiClient,
      cacheService: cacheService,
      analyticsService: analyticsService,
    );

    conversationMemoryRepository = ConversationMemoryRepository(
      aiService: aiService,
      cacheService: cacheService,
    );

    // 11. AI Notification Service
    aiNotificationService = AiNotificationService(
      notificationService: notificationService,
    );

    _initialized = true;
  }
}

/// Global accessor for services (convenience).
final sl = ServiceLocator();
