import 'package:babyland/app/agora/video_call_controller.dart';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/controller/experts_consultation/records/records_controller.dart';
import 'package:babyland/app/controller/photo/photo_controller.dart';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/features/post_pregnancy/state/postpartum_dashboard_notifier.dart';
import 'package:babyland/app/navbar/post_pregnancy/post_pregnancy_navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/app/widgets/print.dart';

// ─── New Architecture Imports ─────────────────────────────
import 'package:babyland/core/config/phone_otp_config.dart';
import 'package:babyland/core/debug/agent_debug_log.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/firebase_phone_auth_service.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:babyland/core/services/analytics_service.dart';
import 'package:babyland/core/services/auth_service.dart';
import 'package:babyland/features/ai_assistant/controllers/ai_chat_controller.dart';

// ─── AI Product Experience Layer Imports ──────────────────
import 'package:babyland/features/ai_insights/controllers/ai_insights_controller.dart';
import 'package:babyland/features/ai_insights/controllers/dynamic_ai_insights_controller.dart';
import 'package:babyland/features/symptom_checker/controllers/symptom_checker_controller.dart';
import 'package:babyland/features/conversation_memory/controllers/conversation_memory_controller.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_controller.dart';
import 'package:babyland/features/patient_consultation/consultation_checkout_repository.dart';
import 'package:babyland/features/smart_community/controllers/smart_community_controller.dart';
import 'package:babyland/core/runtime/app_lifecycle_host.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/subscription/subscription_payment_coordinator.dart';
import 'package:babyland/core/sync/polling_consultation_sync.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:babyland/core/error/error_handler.dart';

// ─── Legacy Imports (preserved for backward compatibility) ─
import 'app/controller/ai_assistant/ai_assistant_controller.dart';
import 'app/controller/baby_growth/baby_growth_controller.dart';
import 'app/controller/forgot_password/forgot_pass_controller.dart';
import 'app/controller/policies/policies_controller.dart';
import 'app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'app/controller/group_controller/group_controller.dart';
import 'app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'app/view/Pre_pregnancy_flow/Mentrual_cycle.dart';
import 'app/view/Pre_pregnancy_flow/cycle_calendar/cycle_calendar_view.dart';
import 'app/view/Pregnancy_Flow/pregnancy_home_view.dart';
import 'app/view/Post_pregnancy_flow/post_pre_baby_growth_view.dart';
import 'app/data/network/network_api_services.dart';
import 'app/data/repository/repository.dart';
import 'app/navbar/pregnancy/navbar_controller.dart';
import 'app/view/Post_pregnancy_flow/controller/post_appoitment_controller.dart';
import 'app/view/Pre_pregnancy_flow/nav_bar/pre_pregnancy_nav_controller.dart';
import 'package:babyland/core/navigation/root_navigator.dart';

import 'firebase_options.dart';

/// Same key as [rootNavigatorKey] — kept for existing `import ... main.dart` usages.
final GlobalKey<NavigatorState> navigatorKey = rootNavigatorKey;

// Legacy singletons (preserved for backward compatibility with existing screens)
final networkApi = NetworkApiServices();
final repository = Repository(apiService: networkApi);

/// Shared consultation invalidation bus (polling today; socket later).
final PollingConsultationSyncService globalConsultationSync =
    PollingConsultationSyncService();

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) {
      ErrorHandler.logError(details.exception, details.stack);
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              kDebugMode
                  ? details.exceptionAsString()
                  : 'A display error occurred. Please go back and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };

    startApp();
  }, (Object error, StackTrace stack) {
    ErrorHandler.logError(error, stack);
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });
}

Future<void> startApp() async {
  await UserPreference.init();

  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {}

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _activateFirebaseAppCheck();
  await _configureFirebaseAuthForDev();

  await AppEnvironment.init(env: Environment.production);

  await sl.init();

  final crashlytics = FirebaseCrashlytics.instance;

  FlutterError.onError = (FlutterErrorDetails details) {
    crashlytics.recordFlutterError(details);
    FlutterError.presentError(details);
    ErrorHandler.handleFlutterFrameworkError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    crashlytics.recordError(error, stack, fatal: true);
    ErrorHandler.logError(error, stack);
    return true;
  };

  await sl.authService.checkAuthState();

  try {
    await sl.notificationService.init(
      deepLinkHandler: (route, args) {
        if (route.isEmpty || route == '/') return;
        navigatorKey.currentState?.pushNamed(route, arguments: args);
      },
    );
  } catch (e) {
    pt('Notification service initialization failed: $e', name: 'Main');
  }

  try {
    final token = await FirebaseMessaging.instance.getToken() ?? '';
    pt(token, name: 'Firebase token');
  } catch (e) {
    pt(e.toString(), name: 'Failed to get firebase token');
  }

  runApp(const Babyland());
}

/// Optional App Check — off by default until attestation is configured per platform.
Future<void> _activateFirebaseAppCheck() async {
  if (kIsWeb) return;

  const buildTag = String.fromEnvironment('APP_BUILD_TAG', defaultValue: 'otp-v5');
  const appCheckEnabled = bool.fromEnvironment(
    'FIREBASE_APP_CHECK_ENABLED',
    defaultValue: false,
  );
  if (!appCheckEnabled) {
    agentDebugLog(
      hypothesisId: 'H11',
      location: 'main.dart:_activateFirebaseAppCheck',
      message: 'App Check skipped (enable after debug token registered)',
      runId: buildTag,
      data: {'appCheckEnabled': false, 'buildTag': buildTag},
    );
    pt(
      'App Check disabled for this build ($buildTag). '
      'To enable: configure attestation in Firebase, then build with '
      '--dart-define=FIREBASE_APP_CHECK_ENABLED=true',
      name: 'Firebase',
    );
    return;
  }

  const useDebugProvider = bool.fromEnvironment(
    'FIREBASE_APP_CHECK_DEBUG',
    defaultValue: false,
  );
  final useDebugAttestation = kDebugMode || useDebugProvider;

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final provider = useDebugAttestation
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity;
      await FirebaseAppCheck.instance.activate(androidProvider: provider);
      agentDebugLog(
        hypothesisId: 'H11',
        location: 'main.dart:_activateFirebaseAppCheck',
        message: 'App Check activated',
        runId: buildTag,
        data: {
          'platform': 'android',
          'provider': provider == AndroidProvider.debug ? 'debug' : 'playIntegrity',
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final provider = useDebugAttestation
          ? AppleProvider.debug
          : AppleProvider.deviceCheck;
      await FirebaseAppCheck.instance.activate(appleProvider: provider);
      agentDebugLog(
        hypothesisId: 'H11',
        location: 'main.dart:_activateFirebaseAppCheck',
        message: 'App Check activated',
        runId: buildTag,
        data: {
          'platform': 'ios',
          'provider': provider == AppleProvider.debug ? 'debug' : 'deviceCheck',
        },
      );
    } else {
      return;
    }

    if (useDebugAttestation) {
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        pt(
          'App Check DEBUG token — Firebase → App Check → Manage debug tokens → Add: $token',
          name: 'Firebase',
        );
      } catch (e) {
        pt(
          'App Check token failed ($e). Add debug token in Firebase Console, or set '
          'FIREBASE_APP_CHECK_ENABLED=false.',
          name: 'Firebase',
        );
      }
    }
  } catch (e) {
    agentDebugLog(
      hypothesisId: 'H11',
      location: 'main.dart:_activateFirebaseAppCheck',
      message: 'App Check activate failed',
      runId: buildTag,
      data: {'error': e.toString()},
    );
    pt('App Check activate failed: $e', name: 'Firebase');
  }
}

Future<void> _configureFirebaseAuthForDev() async {
  final emulatorHost = PhoneOtpConfig.authEmulatorHost;
  if (kDebugMode && emulatorHost != null) {
    final port = PhoneOtpConfig.authEmulatorPort;
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, port);
    pt(
      'Firebase Auth Emulator active at $emulatorHost:$port — '
      'run: firebase emulators:start --only auth',
      name: 'Firebase',
    );
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final disableFromDefine = const bool.fromEnvironment(
      'FIREBASE_AUTH_DISABLE_APP_VERIFICATION',
    );
    final disableFromEnv =
        dotenv.env['FIREBASE_AUTH_DISABLE_APP_VERIFICATION']?.toLowerCase() ==
            'true';
    // Test-only bypass (Firebase Console → Phone → test numbers). Does NOT fix real SMS.
    const skipAppVerification = bool.fromEnvironment(
      'FIREBASE_SKIP_APP_VERIFICATION',
      defaultValue: false,
    );
    // Debug + profile builds: allow Firebase Console test phone numbers without Play Integrity.
    final disableAppVerification = disableFromDefine ||
        disableFromEnv ||
        skipAppVerification ||
        !kReleaseMode;
    // Sideloaded APKs: Play Integrity fails → force reCAPTCHA (needs SHA-1+SHA-256 in Firebase).
    // Hardcoded true so plain `flutter build apk` works without extra --dart-define flags.
    const forceRecaptchaFromDefine = bool.fromEnvironment(
      'FIREBASE_FORCE_RECAPTCHA',
      defaultValue: true,
    );
    final forceRecaptchaFromEnv =
        dotenv.env['FIREBASE_FORCE_RECAPTCHA']?.toLowerCase() != 'false';
    final forceRecaptchaFlow = forceRecaptchaFromDefine &&
        forceRecaptchaFromEnv &&
        !disableAppVerification;

    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: disableAppVerification,
      forceRecaptchaFlow: forceRecaptchaFlow,
    );

    const buildTag = String.fromEnvironment('APP_BUILD_TAG', defaultValue: 'otp-v5');
    agentDebugLog(
      hypothesisId: 'H9',
      location: 'main.dart:_configureFirebaseAuthForDev',
      message: 'Firebase Auth settings applied',
      runId: buildTag,
      data: {
        'projectId': Firebase.app().options.projectId,
        'kDebugMode': kDebugMode,
        'kReleaseMode': kReleaseMode,
        'disableAppVerification': disableAppVerification,
        'forceRecaptchaFlow': forceRecaptchaFlow,
        'buildTag': buildTag,
      },
    );

    pt(
      'Firebase Phone Auth: project=${Firebase.app().options.projectId} '
      'debug=$kDebugMode '
      'appVerificationDisabledForTesting=$disableAppVerification '
      'forceRecaptchaFlow=$forceRecaptchaFlow '
      'skipAppVerification=$skipAppVerification. '
      'If OTP fails: Firebase → Android app → SHA-1+SHA-256 (tools/print_firebase_sha.ps1), '
      'enable Phone sign-in, re-download google-services.json, reinstall APK.',
      name: 'Firebase',
    );
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    pt(
      'Firebase (iOS): project=${Firebase.app().options.projectId} '
      'bundle=com.thebabyland — register the iOS app in Firebase Console, add '
      'GoogleService-Info.plist, upload APNs key for Phone Auth + FCM, and enable '
      'Sign in with Apple in Xcode before release.',
      name: 'Firebase',
    );
  }
}

class Babyland extends StatelessWidget {
  const Babyland({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
    );

    return MultiProvider(
      providers: [
        // ─── New Architecture Providers ─────────────────────
        ChangeNotifierProvider<AuthService>.value(value: sl.authService),
        ChangeNotifierProvider<FirebasePhoneAuthService>.value(
          value: sl.firebasePhoneAuthService,
        ),
        Provider<AnalyticsService>.value(value: sl.analyticsService),
        ChangeNotifierProvider(
          create: (_) => AiChatController(
            repository: sl.aiChatRepository,
            analytics: sl.analyticsService,
          ),
        ),

        // ─── AI Product Experience Layer Providers ──────────
        ChangeNotifierProvider(
          create: (_) => AiInsightsController(
            repository: sl.aiInsightsRepository,
            analytics: sl.analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DynamicAiInsightsController(
            repository: repository,
            cacheService: sl.cacheService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SymptomCheckerController(
            repository: sl.symptomCheckerRepository,
            analytics: sl.analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationMemoryController(
            repository: sl.conversationMemoryRepository,
            analytics: sl.analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SmartCommunityController(
            repository: sl.smartCommunityRepository,
            analytics: sl.analyticsService,
          ),
        ),

        // ─── Legacy Providers (preserved for existing screens) ─
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider(create: (_) => NavBarProvider()),
        ChangeNotifierProvider(
          create: (_) => ConsultationCheckoutController(
            repository: ConsultationCheckoutRepository(api: networkApi),
          ),
        ),
        Provider<PollingConsultationSyncService>.value(
          value: globalConsultationSync,
        ),
        ChangeNotifierProvider<SubscriptionPaymentCoordinator>(
          create: (_) => SubscriptionPaymentCoordinator(),
        ),
        ChangeNotifierProvider(create: (_) => AppStateReconciliationCoordinator()),

        ChangeNotifierProvider(create: (_) => ExpertConsultationProvider()),
        ChangeNotifierProvider(create: (_) => BookingController()),
        ChangeNotifierProvider(create: (_) => PostPregnancyNavBarProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => PregnancyController()),
        ChangeNotifierProvider(create: (_) => PostpregnancyProvider()),
        ChangeNotifierProvider(create: (_) => PostpartumDashboardNotifier()),
        ChangeNotifierProvider(create: (_) => CycleCalenderProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPassController()),
        ChangeNotifierProvider(create: (_) => GetUserProvider()),
        ChangeNotifierProvider(create: (_) => BabyGrowthProvider()),
        ChangeNotifierProvider(create: (_) => PrePregancyNavBarProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => PoliciesProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(create: (_) => VideoCallProvider()),
        ChangeNotifierProvider(create: (_) => PostAppointmentController()),
        ChangeNotifierProvider(create: (_) => GroupController()),
      ],
      child: AppLifecycleHost(
        child: SafeArea(
          top: false,
          child: PopScope(
            canPop: false,
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              navigatorObservers: [
                sl.analyticsService.observer,
                MentrualCycle.routeObserver,
                CycleCalendarView.routeObserver,
                PregnancyHomeView.routeObserver,
                PostPreBabyGrowthView.routeObserver,
              ],
              debugShowCheckedModeBanner: false,
              title: 'Babyland',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              ),
              onGenerateRoute: AppRoutes.generateRoute,
              initialRoute: AppRoutes.splashView,
            ),
          ),
        ),
      ),
    );
  }
}
