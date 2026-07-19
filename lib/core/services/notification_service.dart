import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/core/notifications/notification_dedup_service.dart';
import 'package:babyland/core/observability/app_runtime_audit_trail.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';
import '../runtime/phase8_notification_bridge.dart';

/// Notification types supported by the app.
enum NotificationType {
  appointmentReminder,
  aiAssistant,
  pregnancyMilestone,
  communityReply,
  videoConsultation,
  general,
}

/// Top-level background message handler (required by Firebase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await UserPreference.init();

  final key = NotificationDedupService.dedupeKeyFrom(
    Map<String, dynamic>.from(message.data),
    messageId: message.messageId,
  );
  if (!await NotificationDedupService.instance.tryProcess(dedupeKey: key)) {
    AppRuntimeAuditTrail.log(
      AppRuntimeEvent.notificationDeduped,
      component: 'FCMBackground',
      reason: key,
    );
    return;
  }

  await UserPreference.setPendingSilentRefresh(true);
  log(
    'Background FCM stored silent refresh intent id=${message.messageId}',
    name: 'Notification',
  );
}

/// Production-grade push notification service.
///
/// Supports:
/// - FCM foreground/background/terminated handling
/// - Local notifications with channels
/// - Deep linking
/// - Notification categorization
class NotificationService {
  static NotificationService? _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationStream.stream;

  String? fcmToken;

  /// Callback for handling deep link navigation.
  void Function(String route, Map<String, dynamic>? args)? onDeepLink;

  NotificationService._();

  factory NotificationService() {
    _instance ??= NotificationService._();
    return _instance!;
  }

  // ─── Initialization ─────────────────────────────────────

  Future<void> init({
    void Function(String route, Map<String, dynamic>? args)? deepLinkHandler,
  }) async {
    onDeepLink = deepLinkHandler;

    // Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('Notification permission: ${settings.authorizationStatus}',
        name: 'Notification');

    // Initialize local notifications
    await _initLocalNotifications();

    // Create notification channels
    await _createChannels();

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Message opened from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Get and cache FCM token (with error handling)
    try {
      fcmToken = await _fcm.getToken();
      log('FCM Token: $fcmToken', name: 'Notification');
    } catch (e) {
      log('Failed to get FCM token: $e', name: 'Notification');
      // App should continue even if FCM token fails
      // Token can be retrieved later when Firebase service is available
    }

    // Listen for token refresh (only if initial token was successful)
    if (fcmToken != null) {
      _fcm.onTokenRefresh.listen((token) {
        fcmToken = token;
        log('FCM Token refreshed', name: 'Notification');
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    final channels = [
      const AndroidNotificationChannel(
        AppConstants.notifChannelGeneral,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        AppConstants.notifChannelAI,
        AppConstants.aiAssistantDisplayName,
        description:
            '${AppConstants.aiAssistantDisplayName} notifications and insights',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        AppConstants.notifChannelAppointment,
        'Appointments',
        description: 'Appointment reminders and updates',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        AppConstants.notifChannelCommunity,
        'Community',
        description: 'Community replies and mentions',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        AppConstants.notifChannelVideoCall,
        'Video Calls',
        description: 'Incoming video consultation alerts',
        importance: Importance.max,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // ─── Message Handlers ───────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('Foreground message: ${message.data}', name: 'Notification');

    final data = Map<String, dynamic>.from(message.data);
    final dedupeKey = NotificationDedupService.dedupeKeyFrom(
      data,
      messageId: message.messageId,
    );
    if (!await NotificationDedupService.instance.tryProcess(
          dedupeKey: dedupeKey,
        )) {
      AppRuntimeAuditTrail.log(
        AppRuntimeEvent.notificationDeduped,
        component: 'FCMForeground',
        reason: dedupeKey,
      );
      return;
    }

    final type = _parseNotificationType(message.data['type']);
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Babyland';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    final silentDataOnly = title.trim().isEmpty && body.trim().isEmpty;
    if (!silentDataOnly) {
      await _showLocalNotification(
        title: title.isEmpty ? 'Babyland' : title,
        body: body.isEmpty ? ' ' : body,
        type: type,
        payload: jsonEncode(message.data),
      );
    }

    await Phase8NotificationBridge.reconcile(
      ReconcileTrigger.foregroundTransition,
    );

    _notificationStream.add(message.data);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    log('Message opened: ${message.data}', name: 'Notification');
    final data = Map<String, dynamic>.from(message.data);
    unawaited(() async {
      await Phase8NotificationBridge.reconcile(
        ReconcileTrigger.notificationTap,
      );
      _navigateFromNotification(data);
    }());
  }

  void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped: ${response.payload}', name: 'Notification');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromNotification(data);
      } catch (e) {
        log('Error parsing notification payload: $e', name: 'Notification');
      }
    }
  }

  // ─── Deep Linking ───────────────────────────────────────

  void _navigateFromNotification(Map<String, dynamic> data) {
    if (onDeepLink == null) return;

    final type = _parseNotificationType(data['type']);

    switch (type) {
      case NotificationType.appointmentReminder:
        onDeepLink!('appointmentView', data);
        break;
      case NotificationType.aiAssistant:
        onDeepLink!('aiAssistantView', data);
        break;
      case NotificationType.pregnancyMilestone:
        onDeepLink!('pregnancyHomeView', data);
        break;
      case NotificationType.communityReply:
        onDeepLink!('navbarView', {'tab': 'community', ...data});
        break;
      case NotificationType.videoConsultation:
        onDeepLink!('videoCallScreen', data);
        break;
      case NotificationType.general:
        onDeepLink!('navbarView', data);
        break;
    }
  }

  // ─── Show Local Notification ────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    final channelId = _getChannelId(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Shows a notification programmatically (for AI alerts, milestones, etc.).
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      type: type,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // ─── Helpers ────────────────────────────────────────────

  NotificationType _parseNotificationType(dynamic typeString) {
    switch (typeString?.toString()) {
      case 'appointment':
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'ai':
      case 'ai_assistant':
        return NotificationType.aiAssistant;
      case 'milestone':
      case 'pregnancy_milestone':
        return NotificationType.pregnancyMilestone;
      case 'community':
      case 'community_reply':
        return NotificationType.communityReply;
      case 'video':
      case 'video_call':
        return NotificationType.videoConsultation;
      default:
        return NotificationType.general;
    }
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
        return AppConstants.notifChannelAppointment;
      case NotificationType.aiAssistant:
        return AppConstants.notifChannelAI;
      case NotificationType.pregnancyMilestone:
        return AppConstants.notifChannelGeneral;
      case NotificationType.communityReply:
        return AppConstants.notifChannelCommunity;
      case NotificationType.videoConsultation:
        return AppConstants.notifChannelVideoCall;
      case NotificationType.general:
        return AppConstants.notifChannelGeneral;
    }
  }

  // ─── Topic Subscriptions ────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // ─── Cleanup ────────────────────────────────────────────

  Future<void> clearAll() async {
    await _localNotifications.cancelAll();
  }

  void dispose() {
    _notificationStream.close();
  }
}
