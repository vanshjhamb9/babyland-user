// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
// import '../routes/app_routes.dart';
//
// String? fcmToken;
//
// // Global instance of FlutterLocalNotificationsPlugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// FlutterLocalNotificationsPlugin();
//
// // Global instance for notification handling
// DoctoConPushNotificationService? _globalNotificationService;
//
// // Global AudioPlayer instance for ringtone
//
// // ✅ FIX: Use a more robust duplicate prevention mechanism
// final Map<String, int> _notificationHistory = {};
// final Map<String, String> _notificationPayloads = {};
//
// // ✅ FIX: Use Isolate-compatible storage for background handler
// const String _backgroundStorageKey = 'processed_notifications';
// final Set<String> _processedNotifications = {};
//
// /// ✅ FIX: Top-level function for background notification handling
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("=== BACKGROUND MESSAGE HANDLER ===");
//
//   // ✅ CRITICAL FIX: Stop all audio first to prevent multiple ringtones
//   try {
//     await _globalAudioPlayer.stop();
//     FlutterRingtonePlayer().stop();
//     RingtoneService.stopRingtone();
//   } catch (e) {
//     print('⚠️ Error stopping audio in background: $e');
//   }
//
//   // ✅ CRITICAL FIX: Create unique notification ID
//   final String notificationId = _createNotificationId(message);
//
//   // ✅ CRITICAL FIX: Check if this notification was already processed
//   if (_isDuplicateNotification(notificationId, isBackground: true)) {
//     print('⏭️ BACKGROUND: Duplicate notification skipped: $notificationId');
//     return;
//   }
//
//   // ✅ Mark as processed immediately
//   _markNotificationProcessed(notificationId);
//
//   print("Background message ID: ${message.messageId}");
//   print("Background message data: ${message.data}");
//   print("Background notification: ${message.notification}");
//
//   // Check for maintenance mode
//   final isMaintenance = _isMaintenanceMode(message);
//   if (isMaintenance) {
//     print("Maintenance mode message suppressed (background)");
//     return;
//   }
//
//   // ✅ FIX: Initialize local notifications in background
//   const initializationSettings = InitializationSettings(
//     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//     iOS: DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     ),
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) {
//       print('🔔 Background notification tapped: ${response.payload}');
//       // Stop audio when notification is tapped
//       _stopAllAudioPlayers();
//     },
//   );
//
//   // ✅ FIX: Handle data-only payloads (server should send data-only for custom handling)
//   final type = message.data['type']?.toString() ?? '';
//   final title = _getNotificationTitle(message);
//   final body = _getNotificationBody(message);
//
//   // Skip if no title or body
//   if (title == null || body == null || (title.isEmpty && body.isEmpty)) {
//     print("Notification skipped: title and body are empty");
//     return;
//   }
//
//   switch (type) {
//     case 'video':
//     case 'audio':
//       print("📞 Background: Call notification received");
//       await _showCallNotificationInBackground(
//         title: title,
//         body: body,
//         data: message.data,
//         notificationId: notificationId,
//       );
//       break;
//
//     case 'chat':
//       print("💬 Background: Chat notification received");
//       await _showChatNotificationInBackground(
//         title: title,
//         body: body,
//         data: message.data,
//         notificationId: notificationId,
//       );
//       break;
//
//     default:
//     // For other notifications, only show if it's a data-only message
//     // (FCM will auto-show system notifications if notification field exists)
//       if (message.notification == null && title.isNotEmpty && body.isNotEmpty) {
//         await _showRegularNotificationInBackground(
//           title: title,
//           body: body,
//           data: message.data,
//           notificationId: notificationId,
//         );
//       } else if (message.notification != null) {
//         print('ℹ️ FCM will show system notification automatically');
//       }
//       break;
//   }
//
//   // ✅ Clean up old processed notifications to prevent memory issues
//   _cleanupOldNotifications();
//
//   print("=== BACKGROUND HANDLER COMPLETED ===");
// }
//
// /// ✅ FIXED: Helper function to create unique notification ID
// String _createNotificationId(RemoteMessage message) {
//   final messageId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
//   final type = message.data['type']?.toString() ?? '';
//   final sessionId = message.data['sessionId']?.toString() ?? '';
//   final conversationId = message.data['conversationId']?.toString() ?? '';
//   final title = _getNotificationTitle(message) ?? '';
//   final body = _getNotificationBody(message) ?? '';
//
//   // Create a hash of relevant data to identify duplicates
//   final hash = '$type-$sessionId-$conversationId-$title-$body-$messageId';
//   return hash.hashCode.toString();
// }
//
// /// ✅ FIXED: Check for duplicate notifications
// bool _isDuplicateNotification(String notificationId, {bool isBackground = false}) {
//   final currentTime = DateTime.now().millisecondsSinceEpoch;
//   final lastTime = _notificationHistory[notificationId] ?? 0;
//
//   // Check if same notification was shown within last 15 seconds
//   // (Increased time window to be safe)
//   if (currentTime - lastTime < 15000) {
//     return true;
//   }
//
//   // Check if this exact payload was already processed
//   if (_processedNotifications.contains(notificationId)) {
//     return true;
//   }
//
//   return false;
// }
//
// /// ✅ FIXED: Mark notification as processed
// void _markNotificationProcessed(String notificationId) {
//   final currentTime = DateTime.now().millisecondsSinceEpoch;
//   _notificationHistory[notificationId] = currentTime;
//   _processedNotifications.add(notificationId);
// }
//
// /// ✅ FIXED: Clean up old notifications
// void _cleanupOldNotifications() {
//   final currentTime = DateTime.now().millisecondsSinceEpoch;
//
//   // Remove notifications older than 2 minutes
//   _notificationHistory.removeWhere((key, timestamp) {
//     return currentTime - timestamp > 120000;
//   });
//
//   // Keep only last 50 processed notifications
//   if (_processedNotifications.length > 50) {
//     final toRemove = _processedNotifications.take(_processedNotifications.length - 50).toList();
//     toRemove.forEach(_processedNotifications.remove);
//   }
// }
//
// /// ✅ FIXED: Check for maintenance mode
// bool _isMaintenanceMode(RemoteMessage message) {
//   final notificationBody = message.notification?.body?.toLowerCase();
//   final dataBody = message.data['body']?.toString().toLowerCase();
//   return notificationBody == "maintenance_mode" || dataBody == "maintenance_mode";
// }
//
// /// ✅ FIXED: Get notification title
// String? _getNotificationTitle(RemoteMessage message) {
//   return message.notification?.title ??
//       message.data['title']?.toString() ??
//       message.data['notification_title']?.toString();
// }
//
// /// ✅ FIXED: Get notification body
// String? _getNotificationBody(RemoteMessage message) {
//   return message.notification?.body ??
//       message.data['body']?.toString() ??
//       message.data['notification_body']?.toString();
// }
//
// /// ✅ FIXED: Show call notification in background
// Future<void> _showCallNotificationInBackground({
//   required String title,
//   required String body,
//   required Map<String, dynamic> data,
//   required String notificationId,
// }) async {
//   try {
//
//     final androidDetails = AndroidNotificationDetails(
//       'CALL_CHANNEL_ID',
//       'Call Notifications',
//       channelDescription: 'Incoming call notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       icon: '@mipmap/ic_launcher',
//       playSound: false, // We play sound manually
//       enableVibration: true,
//       enableLights: true,
//       fullScreenIntent: true,
//       color: Colors.green,
//       ledColor: Colors.green,
//       ledOnMs: 1000,
//       ledOffMs: 500,
//       actions: [
//         AndroidNotificationAction(
//           'accept',
//           'Accept',
//           showsUserInterface: true,
//         ),
//         AndroidNotificationAction(
//           'reject',
//           'Reject',
//           showsUserInterface: true,
//         ),
//       ],
//     );
//
//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       categoryIdentifier: "call",
//     );
//
//     final details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     final payload = jsonEncode(data);
//     _notificationPayloads[notificationId] = payload;
//
//     // Convert notificationId to int for show() method
//     final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//     await flutterLocalNotificationsPlugin.show(
//       notificationIdInt,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//
//     print("📞 Background call notification shown: $title");
//
//     // Auto-stop ringtone after 30 seconds for calls
//     Future.delayed(const Duration(seconds: 30), () {
//       _stopAllAudioPlayers();
//     });
//
//   } catch (e) {
//     print('❌ Error showing call notification in background: $e');
//   }
// }
//
// /// ✅ FIXED: Show chat notification in background
// Future<void> _showChatNotificationInBackground({
//   required String title,
//   required String body,
//   required Map<String, dynamic> data,
//   required String notificationId,
// }) async {
//   try {
//     // Play ringtone for chat
//     await _playRingtoneInBackground(isCall: false);
//
//     final androidDetails = AndroidNotificationDetails(
//       'CHAT_CHANNEL_ID',
//       'Chat Notifications',
//       channelDescription: 'New message notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       icon: '@mipmap/ic_launcher',
//       playSound: false, // We play sound manually
//       enableVibration: true,
//       enableLights: true,
//       color: Colors.blue,
//       ledColor: Colors.blue,
//       ledOnMs: 1000,
//       ledOffMs: 500,
//     );
//
//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       categoryIdentifier: "chat",
//     );
//
//     final details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     final payload = jsonEncode(data);
//     _notificationPayloads[notificationId] = payload;
//
//     // Convert notificationId to int for show() method
//     final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//     await flutterLocalNotificationsPlugin.show(
//       notificationIdInt,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//
//     print("💬 Background chat notification shown: $title");
//
//     // Auto-stop ringtone after 8 seconds for chats
//     Future.delayed(const Duration(seconds: 8), () {
//       _stopAllAudioPlayers();
//     });
//
//   } catch (e) {
//     print('❌ Error showing chat notification in background: $e');
//   }
// }
//
// /// ✅ FIXED: Show regular notification in background
// Future<void> _showRegularNotificationInBackground({
//   required String title,
//   required String body,
//   required Map<String, dynamic> data,
//   required String notificationId,
// }) async {
//   try {
//     final androidDetails = AndroidNotificationDetails(
//       'DOCTOCON_CHANNEL_ID',
//       'DOCTOCON Notifications',
//       channelDescription: 'Notifications for DOCTOCON app',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       icon: '@mipmap/ic_launcher',
//       playSound: true,
//       enableVibration: true,
//       enableLights: true,
//       color: Colors.transparent,
//       ledColor: Colors.transparent,
//       ledOnMs: 1000,
//       ledOffMs: 500,
//       styleInformation: BigTextStyleInformation(
//         body,
//         htmlFormatBigText: true,
//         contentTitle: title,
//         htmlFormatContentTitle: true,
//       ),
//     );
//
//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     final details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     final payload = jsonEncode(data);
//     _notificationPayloads[notificationId] = payload;
//
//     // Convert notificationId to int for show() method
//     final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//     await flutterLocalNotificationsPlugin.show(
//       notificationIdInt,
//       title,
//       body,
//       details,
//       payload: payload,
//     );
//
//     print("📢 Background regular notification shown: $title");
//
//   } catch (e) {
//     print('❌ Error showing regular notification in background: $e');
//   }
// }
//
// /// ✅ FIXED: Play ringtone in background
// Future<void> _playRingtoneInBackground({bool isCall = false}) async {
//   try {
//     // First stop any existing audio
//     await _stopAllAudioPlayers();
//
//     if (isCall) {
//       // For calls, use louder/longer ringtone
//       await _globalAudioPlayer.play(
//         AssetSource('assets/incoming_call.mp3'),
//         volume: 1.0,
//         mode: PlayerMode.lowLatency,
//       );
//       print('🔔 Call ringtone started in background');
//     } else {
//       // For chats, use message tone
//       await _globalAudioPlayer.play(
//         AssetSource('assets/incoming_message.mp3'),
//         volume: 0.8,
//         mode: PlayerMode.lowLatency,
//       );
//       print('📬 Message ringtone started in background');
//     }
//   } catch (e) {
//     print('❌ Error playing ringtone in background: $e');
//     // Fallback to FlutterRingtonePlayer
//     try {
//       if (isCall) {
//         FlutterRingtonePlayer().play(
//           fromAsset: "assets/incoming_call.mp3",
//           volume: 1.0,
//         );
//       } else {
//         FlutterRingtonePlayer().play(
//           fromAsset: "assets/incoming_message.mp3",
//           volume: 0.8,
//         );
//       }
//     } catch (e2) {
//       print('❌ Fallback ringtone also failed: $e2');
//     }
//   }
// }
//
// /// ✅ Helper function to stop all audio players
// _stopAllAudioPlayers() {
//   try {
//     FlutterRingtonePlayer().stop();
//     _globalAudioPlayer.stop();
//     AudioPlayer().stop();
//     RingtoneService.stopRingtone();
//     print('🔇 All audio players stopped');
//   } catch (e) {
//     print('⚠️ Error stopping audio players: $e');
//   }
// }
//
// /// Navigation handler for chat notifications
// void _navigateToChatFromNotification(Map<String, dynamic> data) {
//   print("📨 Navigating to chat from notification");
//
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     try {
//       _stopAllAudioPlayers();
//
//       // Check if already on chat screen
//       if (Get.currentRoute.contains('chatScreen')) {
//         print("⚠️ Already on chat screen, refreshing instead");
//         return;
//       }
//
//       Get.toNamed(
//         AppRoutes.chatScreen,
//         arguments: {
//           "sessionId": data["sessionId"]?.toString() ?? "",
//           "userId": data["senderId"]?.toString() ?? "",
//           "doctorId": data["receiverId"]?.toString() ?? "",
//           "conversationId": data["conversationId"]?.toString() ?? "",
//           "profile": data["profile"]?.toString() ?? "",
//           "name": data["name"]?.toString() ?? "",
//           "type": data["type"]?.toString() ?? "chat",
//           "fromPopUP": false,
//           "fromNotification": true,
//         },
//       );
//       clearNotificationsOnNavigation();
//
//       print("✅ Successfully navigated to chat screen from notification");
//     } catch (e) {
//       print('❌ Error navigating to chat from notification: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to open chat: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         duration: const Duration(seconds: 3),
//       );
//     }
//   });
// }
//
// Future<void> clearNotificationsOnNavigation() async {
//   try {
//     // 1. Stop all audio players immediately
//     _stopAllAudioPlayers();
//
//     // 2. Clear all local notifications from notification tray
//     await flutterLocalNotificationsPlugin.cancelAll();
//
//     // 3. Clear notification history to prevent reappearance
//     _notificationHistory.clear();
//     _processedNotifications.clear();
//     _notificationPayloads.clear();
//
//     // 4. Clear badge count on iOS
//     if (Platform.isIOS) {
//       await flutterLocalNotificationsPlugin.cancelAll();
//       // You can also set badge to 0 if needed
//       // await flutterLocalNotificationsPlugin.setBadgeCount(0);
//     }
//
//     print('✅ All notifications cleared on navigation');
//   } catch (e) {
//     print('❌ Error clearing notifications on navigation: $e');
//   }
// }
// /// Navigation handler for call notifications
// void handleCallNotification(Map<String, dynamic> data) {
//   try {
//     print("📞 Handling call notification: $data");
//     final sessionId = data['sessionId']?.toString();
//     final type = data['type']?.toString();
//
//     if (sessionId == null || sessionId.isEmpty) {
//       print("❌ Invalid sessionId: $sessionId");
//       Get.snackbar('Error', 'Invalid call session ID');
//       return;
//     }
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _stopAllAudioPlayers();
//
//       final currentRoute = Get.currentRoute;
//       if (currentRoute.contains('CallScreen')) {
//         print("⚠️ Already on call screen ($currentRoute), skipping navigation");
//         return;
//       }
//
//       if (type == 'video') {
//         print("🎬 Navigating to VIDEO call screen");
//         Get.to(() => VideoCallScreen(
//           isCaller: false,
//           sessionId: sessionId,
//         ));
//       } else if (type == 'audio') {
//         print("🎧 Navigating to AUDIO call screen");
//         Get.to(() => AudioCallScreen(
//           isCaller: false,
//           sessionId: sessionId,
//         ));
//       } else {
//         print("❌ Unknown call type: $type");
//         Get.snackbar('Error', 'Unknown call type: $type');
//       }
//     });
//   } catch (e) {
//     print('❌ Error handling call notification: $e');
//     Get.snackbar(
//       'Error',
//       'Failed to join call: $e',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
// }
//
// /// ✅ FIXED: Push Notification Service class for DoctoCon
// class DoctoConPushNotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final StreamController<Map<String, dynamic>> _notificationStream =
//   StreamController.broadcast();
//
//   Stream<Map<String, dynamic>> get notificationStream => _notificationStream.stream;
//
//   Future<void> initialize() async {
//     print("🚀 Initializing DoctoCon Push Notifications");
//
//     // Store global reference
//     _globalNotificationService = this;
//
//     // Clear all existing notifications
//     await flutterLocalNotificationsPlugin.cancelAll();
//
//     // Request notification permissions
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     print('📱 Notification permission status: ${settings.authorizationStatus}');
//
//     // Initialize local notifications
//     await _initializeLocalNotifications();
//
//     // ✅ FIX: Set up background message handler
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//     // ✅ FIXED: Handle foreground messages with duplicate prevention
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       await _handleForegroundMessage(message);
//     });
//
//     // Handle notification opened from background
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//       await _handleNotificationOpened(message);
//     });
//
//     // Handle notification opened from terminated state
//     RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
//     if (initialMessage != null) {
//       await _handleNotificationOpened(initialMessage);
//     }
//
//     // Get FCM token
//     _firebaseMessaging.getToken().then((token) {
//       fcmToken = token;
//       print('🔥 DoctoCon FCM Token: $fcmToken');
//     });
//
//     // Token refresh listener
//     _firebaseMessaging.onTokenRefresh.listen((token) {
//       fcmToken = token;
//       print('🔄 FCM Token refreshed: $fcmToken');
//     });
//
//     print("✅ DoctoCon Push Notifications Initialized Successfully");
//   }
//
//   /// ✅ FIXED: Handle foreground messages
//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     print('\n=== FOREGROUND MESSAGE RECEIVED ===');
//
//     // Create unique notification ID
//     final String notificationId = _createNotificationId(message);
//
//     // Check for duplicates
//     if (_isDuplicateNotification(notificationId, isBackground: false)) {
//       print('⏭️ FOREGROUND: Duplicate notification skipped: $notificationId');
//       return;
//     }
//
//     // Mark as processed
//     _markNotificationProcessed(notificationId);
//
//     print('📨 Message Type: ${message.data['type']}');
//
//     // Check for maintenance mode
//     if (_isMaintenanceMode(message)) {
//       print("🔕 Maintenance mode message suppressed (foreground)");
//       return;
//     }
//
//     // Extract data
//     final type = message.data['type']?.toString() ?? '';
//     final title = _getNotificationTitle(message) ?? 'New Notification';
//     final body = _getNotificationBody(message) ?? '';
//
//     // Skip if no content
//     if (body.isEmpty && title == 'New Notification') {
//       print('📭 Empty notification skipped');
//       return;
//     }
//
//     // Handle different message types
//     switch (type) {
//       case 'video':
//       case 'audio':
//         await _handleForegroundCallNotification(
//           type: type,
//           title: title,
//           body: body,
//           data: message.data,
//           notificationId: notificationId,
//         );
//         break;
//
//     // case 'chat':
//     //   await _handleForegroundChatNotification(
//     //     title: title,
//     //     body: body,
//     //     data: message.data,
//     //     notificationId: notificationId,
//     //   );
//     //   break;
//
//       default:
//         await _handleForegroundRegularNotification(
//           title: title,
//           body: body,
//           data: message.data,
//           notificationId: notificationId,
//         );
//         break;
//     }
//
//     // Add to notification stream
//     _notificationStream.add(message.data);
//
//     print('=== END OF MESSAGE ===\n');
//   }
//
//   /// Handle foreground call notification
//   Future<void> _handleForegroundCallNotification({
//     required String type,
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//     required String notificationId,
//   }) async {
//     print("📞 Foreground: Call notification received");
//
//     try {
//       // Play ringtone for call
//       await _playRingtoneInForeground(isCall: true);
//
//       final androidDetails = AndroidNotificationDetails(
//         'CALL_CHANNEL_ID',
//         'Call Notifications',
//         channelDescription: 'Incoming call notifications',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         icon: '@mipmap/ic_launcher',
//         playSound: false,
//         enableVibration: true,
//         enableLights: true,
//         fullScreenIntent: true,
//         color: Colors.green,
//         ledColor: Colors.green,
//         ledOnMs: 1000,
//         ledOffMs: 500,
//         actions: [
//           AndroidNotificationAction(
//             'accept',
//             'Accept',
//             showsUserInterface: true,
//           ),
//           AndroidNotificationAction(
//             'reject',
//             'Reject',
//             showsUserInterface: true,
//           ),
//         ],
//       );
//
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         categoryIdentifier: "call",
//       );
//
//       final details = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       final payload = jsonEncode(data);
//       final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//       await flutterLocalNotificationsPlugin.show(
//         notificationIdInt,
//         title,
//         body,
//         details,
//         payload: payload,
//       );
//
//       print("📞 Foreground call notification shown");
//
//       // Auto-stop ringtone after 30 seconds
//       Future.delayed(const Duration(seconds: 30), () {
//         _stopAllAudioPlayers();
//       });
//
//     } catch (e) {
//       print('❌ Error showing call notification: $e');
//     }
//   }
//
//   /// Handle foreground chat notification
//   Future<void> _handleForegroundChatNotification({
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//     required String notificationId,
//   }) async {
//     print("💬 Foreground: Chat notification received");
//
//     try {
//       // Play ringtone for chat
//       await _playRingtoneInForeground(isCall: false);
//
//       final androidDetails = AndroidNotificationDetails(
//         'CHAT_CHANNEL_ID',
//         'Chat Notifications',
//         channelDescription: 'New message notifications',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         icon: '@mipmap/ic_launcher',
//         playSound: false,
//         enableVibration: true,
//         enableLights: true,
//         color: Colors.blue,
//         ledColor: Colors.blue,
//         ledOnMs: 1000,
//         ledOffMs: 500,
//       );
//
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         categoryIdentifier: "chat",
//       );
//
//       final details = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       final payload = jsonEncode(data);
//       final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//       await flutterLocalNotificationsPlugin.show(
//         notificationIdInt,
//         title,
//         body,
//         details,
//         payload: payload,
//       );
//
//       print("💬 Foreground chat notification shown");
//
//       // Auto-stop ringtone after 8 seconds
//       Future.delayed(const Duration(seconds: 8), () {
//         _stopAllAudioPlayers();
//       });
//
//     } catch (e) {
//       print('❌ Error showing chat notification: $e');
//     }
//   }
//
//   /// Handle foreground regular notification
//   Future<void> _handleForegroundRegularNotification({
//     required String title,
//     required String body,
//     required Map<String, dynamic> data,
//     required String notificationId,
//   }) async {
//     try {
//       final androidDetails = AndroidNotificationDetails(
//         'DOCTOCON_CHANNEL_ID',
//         'DOCTOCON Notifications',
//         channelDescription: 'Notifications for DOCTOCON app',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         icon: '@mipmap/ic_launcher',
//         playSound: true,
//         enableVibration: true,
//         enableLights: true,
//         color: Colors.transparent,
//         ledColor: Colors.transparent,
//         ledOnMs: 1000,
//         ledOffMs: 500,
//         styleInformation: BigTextStyleInformation(
//           body,
//           htmlFormatBigText: true,
//           contentTitle: title,
//           htmlFormatContentTitle: true,
//         ),
//       );
//
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );
//
//       final details = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       final payload = jsonEncode(data);
//       final int notificationIdInt = notificationId.hashCode.abs() % 2147483647;
//
//       await flutterLocalNotificationsPlugin.show(
//         notificationIdInt,
//         title,
//         body,
//         details,
//         payload: payload,
//       );
//
//       print("📢 Foreground regular notification shown");
//
//     } catch (e) {
//       print('❌ Error showing regular notification: $e');
//     }
//   }
//
//   /// Play ringtone in foreground
//   Future<void> _playRingtoneInForeground({bool isCall = false}) async {
//     try {
//       _stopAllAudioPlayers();
//
//       if (isCall) {
//         await FlutterRingtonePlayer().play(
//           fromAsset: "assets/incoming_call.mp3",
//           volume: 1.0,
//         );
//         print('🔔 Call ringtone started in foreground');
//       } else {
//         await FlutterRingtonePlayer().play(
//           fromAsset: "assets/incoming_message.mp3",
//           volume: 0.8,
//         );
//         print('📬 Message ringtone started in foreground');
//       }
//     } catch (e) {
//       print('❌ Error playing ringtone in foreground: $e');
//     }
//   }
//
//   /// Handle notification opened
//   Future<void> _handleNotificationOpened(RemoteMessage message) async {
//     print('\n📱 NOTIFICATION OPENED (APP WAS IN BACKGROUND/TERMINATED)');
//     print('📦 Data: ${message.data}');
//
//     _stopAllAudioPlayers();
//     _handleNotificationData(message.data);
//   }
//
//   /// Handle notification data for navigation
//   void _handleNotificationData(Map<String, dynamic> data) {
//     final type = data['type']?.toString() ?? '';
//     switch (type) {
//       case 'video':
//       case 'audio':
//         print('🎯 Handling call notification from background/terminated');
//         handleCallNotification(data);
//         break;
//       case 'chat':
//         print('📨 Handling chat notification from background/terminated');
//         _navigateToChatFromNotification(data);
//         break;
//       default:
//         print('ℹ️ Regular notification, no special handling');
//         break;
//     }
//   }
//
//   /// Initialize local notification settings
//   Future<void> _initializeLocalNotifications() async {
//     print("🔧 Initializing local notifications");
//
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await flutterLocalNotificationsPlugin.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         _onNotificationTapped(response);
//       },
//     );
//
//     // Create notification channels
//     await _createNotificationChannels();
//     print("✅ Local notifications initialized");
//   }
//
//   /// Handle notification tap
//   void _onNotificationTapped(NotificationResponse response) {
//     print('\n🔔 NOTIFICATION TAPPED');
//     print('📦 Payload: ${response.payload}');
//
//     try {
//       _stopAllAudioPlayers();
//
//       if (response.payload != null && response.payload!.isNotEmpty) {
//         final payload = response.payload!;
//         final data = _parseNotificationPayload(payload);
//
//         // Handle action buttons
//         if (response.actionId?.isNotEmpty == true) {
//           _handleNotificationAction(response.actionId!, data);
//           return;
//         }
//
//         // Handle different notification types
//         final type = data['type']?.toString() ?? '';
//         switch (type) {
//           case 'video':
//           case 'audio':
//             print('🎯 Handling call notification tap');
//             handleCallNotification(data);
//             break;
//           case 'chat':
//             print('💬 Handling chat notification tap');
//             _navigateToChatFromNotification(data);
//             break;
//           default:
//             print('ℹ️ Regular notification, no special handling');
//             break;
//         }
//       }
//     } catch (e) {
//       print('❌ Error handling notification tap: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to handle notification: $e',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
//
//   /// Handle notification action buttons
//   void _handleNotificationAction(String actionId, Map<String, dynamic> data) {
//     print('🔄 Handling notification action: $actionId');
//     _stopAllAudioPlayers();
//
//     switch (actionId) {
//       case 'accept':
//         print('✅ Call accepted via notification');
//         if (data['type'] == 'video' || data['type'] == 'audio') {
//           handleCallNotification(data);
//         }
//         break;
//       case 'reject':
//         print('❌ Call rejected via notification');
//         Get.snackbar('Call Rejected', 'You rejected the incoming call');
//         break;
//       default:
//         print('❓ Unknown notification action: $actionId');
//     }
//   }
//
//   /// Parse notification payload
//   Map<String, dynamic> _parseNotificationPayload(String payload) {
//     try {
//       if (payload.trim().startsWith('{') && payload.trim().endsWith('}')) {
//         return jsonDecode(payload) as Map<String, dynamic>;
//       }
//       return {};
//     } catch (e) {
//       print('❌ Error parsing payload: $e');
//       return {};
//     }
//   }
//
//   /// Create notification channels
//   Future<void> _createNotificationChannels() async {
//     if (Platform.isAndroid) {
//       const mainChannel = AndroidNotificationChannel(
//         'DOCTOCON_CHANNEL_ID',
//         'DOCTOCON Notifications',
//         description: 'Notifications for DOCTOCON app',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//       );
//
//       const callChannel = AndroidNotificationChannel(
//         'CALL_CHANNEL_ID',
//         'Call Notifications',
//         description: 'Incoming call notifications',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//       );
//
//       const chatChannel = AndroidNotificationChannel(
//         'CHAT_CHANNEL_ID',
//         'Chat Notifications',
//         description: 'New message notifications',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//       );
//
//       final androidImplementation = flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>();
//
//       if (androidImplementation != null) {
//         await androidImplementation.createNotificationChannel(mainChannel);
//         await androidImplementation.createNotificationChannel(callChannel);
//         await androidImplementation.createNotificationChannel(chatChannel);
//         print('✅ Android notification channels created');
//       }
//     }
//   }
//
//   /// Subscribe to topics
//   Future<void> subscribeToTopic(String topic) async {
//     await _firebaseMessaging.subscribeToTopic(topic);
//     print('✅ Subscribed to topic: $topic');
//   }
//
//   /// Unsubscribe from topics
//   Future<void> unsubscribeFromTopic(String topic) async {
//     await _firebaseMessaging.unsubscribeFromTopic(topic);
//     print('✅ Unsubscribed from topic: $topic');
//   }
//
//   /// Get current FCM token
//   Future<String?> getFCMToken() async {
//     return await _firebaseMessaging.getToken();
//   }
//
//   /// Delete FCM token (for logout)
//   Future<void> deleteFCMToken() async {
//     await _firebaseMessaging.deleteToken();
//     fcmToken = null;
//     print('✅ FCM token deleted');
//   }
//
//   /// Clear all notifications
//   Future<void> clearAllNotifications() async {
//     await flutterLocalNotificationsPlugin.cancelAll();
//     _notificationHistory.clear();
//     _processedNotifications.clear();
//     _notificationPayloads.clear();
//     print('✅ All notifications cleared');
//   }
//
//   /// Dispose stream controller
//   void dispose() {
//     _notificationStream.close();
//     _notificationHistory.clear();
//     _processedNotifications.clear();
//     _notificationPayloads.clear();
//     _globalAudioPlayer.dispose();
//   }
// }