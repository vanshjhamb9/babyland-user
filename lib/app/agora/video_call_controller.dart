import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common_model/common_model.dart';
import '../data/response/api_response.dart';
import '../widgets/app_popup.dart';
import 'agora.dart';

enum CallState { connecting, waitingForRemote, inCall, ended }

class VideoCallProvider with ChangeNotifier {
  // Call state
  CallState _callState = CallState.connecting;
  CallState get callState => _callState;

  int _callDurationForAppbar = 0;
  int get callDurationForAppbar => _callDurationForAppbar;

  bool _isInCall = false;
  bool get isInCall => _isInCall;


  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late RtcEngine _engine;
  RtcEngine get engine => _engine;

  int? _remoteUid;
  int? get remoteUid => _remoteUid;

  bool _isJoined = false;
  bool get isJoined => _isJoined;

  bool _isMicrophoneMuted = false;
  bool get isMicrophoneMuted => _isMicrophoneMuted;

  bool _isVideoMuted = false;
  bool get isVideoMuted => _isVideoMuted;

  String _currentRole = "";
  String get currentRole => _currentRole;

  bool _isCaller = false;
  bool get isCaller => _isCaller;

  String _sessionId = "";
  String get sessionId => _sessionId;

  Duration _callDuration = Duration.zero;
  Duration get callDuration => _callDuration;

  Timer? _callTimer;

  String _error = "";
  String get error => _error;
  String? token;


  ApiResponse<TokenGeneratorModel>? _apiData = ApiResponse.completed(null);
  ApiResponse<TokenGeneratorModel>? get apiData => _apiData;

  void setTokenApiData(ApiResponse<TokenGeneratorModel> response) {
    _apiData = response;
    notifyListeners();
  }
/*
  Future<void> getVideoCallToken({
    required BuildContext context,
    required String channelName,
    required String uid,
    required String role,
    required String sessionId,
    bool isCaller = false,
  }) async {
    if (_isLoading) return;
    setTokenApiData(ApiResponse.loading());
    try {
      _isLoading = true;
      _isCaller = isCaller;
      _sessionId = sessionId;
      _currentRole = "publisher";
      _error = "";
      notifyListeners();

      final numericUid = _generateNumericUid(uid);

      log("🎥 Video Call Setup:");
      log("   User ID: $uid");
      log("   Numeric UID: $numericUid");
      log("   Channel: $channelName");
      log("   Role: $_currentRole");
      log("   Is Caller: $isCaller");

      // Get token from API
      Map<String, dynamic> data = {
        "channelName": channelName,
        "uid": numericUid.toString(),
        "role": _currentRole,
      };


      await repository.getCallTokenGeneratorApi(data).then((value)async {
        _isLoading = false;
        setTokenApiData(ApiResponse.completed(value));

        token = apiData?.data?.token;
        log("📡 Requesting token with data: $data");


        if (!_isInitialized) {
          await initializeAgoraEngine(context);
        }

        await joinChannel(
        channelName: channelName,
        uid: uid,
        numericUid: numericUid,
        token: apiData?.data?.token ?? "",
        );

      },);
      log("✅ Token API Response received ${apiData?.data?.token})");


      // _debugToken(token ?? "null token");


    } catch (error, stackTrace) {
      log("❌ Error in video call setup: $error");
      log("Stack trace: $stackTrace");
      _error = error.toString();

      if (context.mounted) {
        AppPopUp.showToast(message: "Failed to start video call: $error");
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
*/

  Future<void> getVideoCallToken({
    required BuildContext context,
    required String channelName,
    required String uid,
    required String role,
    required String sessionId,
    bool isCaller = false,
  }) async {
    if (_isLoading) return;
    setTokenApiData(ApiResponse.loading());
    try {
      _isLoading = true;
      _isCaller = isCaller;
      _sessionId = sessionId;
      _currentRole = "publisher";
      _error = "";
      notifyListeners();
      await _requestPermissions();

      final numericUid = _generateNumericUid(uid);

      log("🎥 Video Call Setup:");
      log("   User ID: $uid");
      log("   Numeric UID: $numericUid");
      log("   Channel: $channelName");
      log("   Role: $_currentRole");
      log("   Is Caller: $isCaller");

      // Get token from API
      Map<String, dynamic> data = {
        "channelName": channelName,
        "uid": numericUid.toString(),
        "role": _currentRole,
      };

      log("📡 Requesting token with data: $data");

      final response = await repository.getCallTokenGeneratorApi(data);
      _isLoading = false;
      setTokenApiData(ApiResponse.completed(response));

      // Extract token from response
      token = response.token?.token; // Directly get token from response
      log("✅ Token received (length: ${token?.length ?? 0})  ${token}");

      if (token == null || token!.isEmpty) {
        throw Exception('Token is null or empty');
      }

      if (!_isInitialized) {
        await initializeAgoraEngine(context);
      }

      await joinChannel(
        channelName: channelName,
        uid: uid,
        numericUid: numericUid,
        token: token!, // Use the extracted token
      );

    } catch (error, stackTrace) {
      log("❌ Error in video call setup: $error");
      log("Stack trace: $stackTrace");
      _error = error.toString();

      if (context.mounted) {
        AppPopUp.showToast(message: "Failed to start video call: $error");
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _requestPermissions() async {
    try {
      await [
        Permission.microphone,
        Permission.camera,
        Permission.bluetoothConnect,
      ].request();

      log("✅ Permissions requested");
    } catch (e) {
      log("❌ Error requesting permissions: $e");
    }
  }


  void _debugToken(String token) {
    log("🔍 Token Debug Analysis:");
    log("   Length: ${token.length}");
    log("   First 20 chars: ${token.substring(0, min(token.length, 20))}");
    log("   Starts with '006': ${token.startsWith('006')}");
    log("   Contains App ID: ${token.contains('ba2833372cbb4b84a169be6808c63706')}");
    log("   Contains '{': ${token.contains('{')}");
    log("   Contains 'token': ${token.contains('token')}");

    if (token.contains('{') || token.contains('token')) {
      log("⚠️ WARNING: Token appears to contain JSON/object structure!");
      log("   It should be a plain token string starting with '006'");
      log("   Current token starts with: ${token.substring(0, 50)}");
    }

    if (!token.startsWith('006')) {
      log("❌ ERROR: Token doesn't start with '006' - invalid Agora token!");
    }
  }

  int _generateNumericUid(String uid) {
    final bytes = utf8.encode(uid);
    final hash = bytes.fold(0, (prev, element) => prev + element);
    return (hash % 100000).abs();
  }

  Future<void> initializeAgoraEngine(BuildContext context) async {
    if (_isInitialized) return;

    try {
      log("🚀 Initializing Agora Engine");

      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: "ba2833372cbb4b84a169be6808c63706",
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioDefault,
        areaCode: 4294967295,
      ));

      await _engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );

      await _engine.enableVideo();
      await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 800,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ));

      _setupEventHandlers(context);

      _isInitialized = true;
      log("✅ Agora engine initialized successfully");

    } catch (e) {
      log("❌ Error initializing Agora engine: $e");
      rethrow;
    }
  }

  void _setupEventHandlers(BuildContext context) {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        log("✅ Joined channel: ${connection.channelId}, UID: ${connection.localUid}");
        _isJoined = true;
        _isInCall = true;
        _callState = CallState.waitingForRemote;
        notifyListeners();
      },

      onUserJoined: (connection, remoteUid, elapsed) {
        log("👤 Remote user joined: $remoteUid");
        _remoteUid = remoteUid;
        _startCallTimer();
        notifyListeners();
      },

      /*onUserOffline: (connection, remoteUid, reason) {
        log("❌ Remote user left: $remoteUid, reason: $reason");
        _remoteUid = null;
        _callState = CallState.ended;
        _stopCallTimer();
        _isInCall = false;
        notifyListeners();

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The other participant has left the call'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },*/
      onUserOffline: (connection, remoteUid, reason) {
        log("❌ Remote user left: $remoteUid, reason: $reason");

        // Don't navigate directly here, just update state
        _remoteUid = null;
        _callState = CallState.ended;
        _stopCallTimer();
        _isInCall = false;
        notifyListeners();

        if (context.mounted) {
          // Use the new endCall method
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              endCall(context);
              AppPopUp.showToast(message: "The other participant has left the call");
            }
          });
        }
      },

      onError: (err, msg) {
        log("❌ Agora error: $err, msg: $msg");
        _error = "Agora Error: $msg";
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agora Error: $msg (Code: $err)'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },

      onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
        log("📹 Remote video state - UID: $remoteUid, State: $state, Reason: $reason");
      },

      onConnectionStateChanged: (connection, state, reason) {
        log("📡 Connection state: $state, reason: $reason");
      },

      onRtcStats: (connection, stats) {
        _callDurationForAppbar = stats.duration ?? 0;
        if (stats.duration! % 10 == 0) {
          log("📊 Call stats - Duration: ${stats.duration}s, Users: ${stats.userCount}");
        }
        notifyListeners();
      },
    ));
  }

  Future<void> joinChannel({
    required String channelName,
    required String uid,
    required int numericUid,
    required String token,
  }) async {
    try {
      await _engine.startPreview();

      log("🎬 Joining channel:");
      log("   Channel: $channelName");
      log("   Numeric UID: $numericUid");
      log("   Token length: ${token.length}");

      // Clean token if it contains JSON structure
      String cleanToken = _cleanToken(token);
      log("   Clean token length: ${cleanToken.length}");
      log("   Clean token preview: ${cleanToken.substring(0, min(cleanToken.length, 50))}...");

      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      );

      if (cleanToken.isEmpty) {
        throw Exception('Token is empty after cleaning');
      }

      await _engine.joinChannel(
        token: cleanToken,
        channelId: channelName,
        uid: numericUid,
        options: options,
      );

      log("✅ Join channel completed");

    } catch (e, stackTrace) {
      log("❌ Error joining channel: $e");
      log("Stack trace: $stackTrace");
      _isJoined = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to join video call channel: $e');
    }
  }

  String _cleanToken(String token) {
    // If token contains JSON structure like "{token: 'actual_token', expireIn: 3600}"
    // We need to extract just the actual token
    String cleaned = token;

    // Remove any surrounding braces and extract token field
    if (token.contains('{') && token.contains('token')) {
      try {
        // Try to parse as JSON
        final parsed = json.decode(token);
        if (parsed is Map && parsed.containsKey('token')) {
          cleaned = parsed['token'].toString();
          log("🛠️ Extracted clean token from JSON");
        }
      } catch (e) {
        // If not valid JSON, try string extraction
        log("⚠️ Not valid JSON, trying string extraction");
        final match = RegExp(r'token["\s]*:["\s]*([^,}]+)').firstMatch(token);
        if (match != null && match.groupCount >= 1) {
          cleaned = match.group(1)!.replaceAll('"', '').replaceAll("'", '').trim();
          log("🛠️ Extracted token via regex: $cleaned");
        }
      }
    }

    // Also clean up any remaining quotes
    cleaned = cleaned.replaceAll('"', '').replaceAll("'", '');

    return cleaned;
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callDuration = Duration.zero;
    int minuteCounter = 0;

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);

      if (_callDuration.inSeconds % 60 == 0 && _callDuration.inSeconds > 0) {
        minuteCounter++;
        log("⏰ 1 minute completed... (Minute: $minuteCounter)");
      }
      notifyListeners();
    });

    log("⏰ Call timer started");
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callDuration = Duration.zero;
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    _isMicrophoneMuted = !_isMicrophoneMuted;
    await _engine.muteLocalAudioStream(_isMicrophoneMuted);
    log("🎤 Microphone ${_isMicrophoneMuted ? 'muted' : 'unmuted'}");
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    _isVideoMuted = !_isVideoMuted;
    await _engine.muteLocalVideoStream(_isVideoMuted);
    log("📹 Video ${_isVideoMuted ? 'muted' : 'unmuted'}");
    notifyListeners();
  }

  Future<void> switchCamera() async {
    try {
      await _engine.switchCamera();
      log("📸 Camera switched");
    } catch (e) {
      log("❌ Error switching camera: $e");
    }
  }

  Future<void> reinitializeForRemoteVideo() async {
    log("🔄 Reinitializing for remote video...");
    try {
      if (_isJoined) {
        await _engine.leaveChannel();
      }

      _remoteUid = null;
      _isJoined = false;
      _stopCallTimer();
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

    } catch (e) {
      log("❌ Error during reinitialization: $e");
    }
  }

  String get formattedCallDuration {
    final minutes = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void cleanup() {
    try {
      log("🧹 Cleaning up video call...");
      _stopCallTimer();

      if (_isInitialized && _engine != null) {
        _engine.leaveChannel();
        _engine.release();
        _isInitialized = false;
      }

      _remoteUid = null;
      _isJoined = false;
      _isInCall = false;
      _callState = CallState.ended;
      _isMicrophoneMuted = false;
      _isVideoMuted = false;
      _isLoading = false;
      _error = "";

      log("✅ Video call provider cleaned up");
    } catch (e) {
      log("❌ Error during cleanup: $e");
    }
  }

  String formatToMMSS(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final m = minutes.toString().padLeft(2, '0');
    final s = remainingSeconds.toString().padLeft(2, '0');
    return "$m:$s";
  }

  // Helper to get min of two numbers
  int min(int a, int b) => a < b ? a : b;


  Future<void> endCall(BuildContext? context, {bool isManual = false}) async {
    try {
      log("📞 Ending video call... (Manual: $isManual)");

      // Call state update
      _callState = CallState.ended;
      _isInCall = false;
      _isJoined = false;

      // Stop timer
      _stopCallTimer();

      // Leave channel if joined
      if (_isInitialized && _engine != null) {
        log("📤 Leaving Agora channel...");
        try {
          await _engine.leaveChannel();
          log("✅ Left Agora channel successfully");
        } catch (e) {
          log("⚠️ Error leaving channel: $e");
        }

        // Release engine resources
        log("🧹 Releasing Agora engine...");
        try {
          await _engine.release();
          _isInitialized = false;
          log("✅ Agora engine released");
        } catch (e) {
          log("⚠️ Error releasing engine: $e");
        }
      }

      // Reset all states
      _resetCallState();

      log("✅ Call ended and cleaned up successfully");

      // Navigate back if context provided
      if (context != null && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.canPop(context)) {
            log("🏠 Navigating back...");
            Navigator.pop(context);
          }
        });
      }

      // Show confirmation if manually ended
      if (isManual && context != null && context.mounted) {
        AppPopUp.showToast(message: "Call ended");
      }

      notifyListeners();

    } catch (e, stackTrace) {
      log("❌ Error ending call: $e");
      log("Stack trace: $stackTrace");
      _error = "Error ending call: $e";

      // Force cleanup even on error
      _forceCleanup();

      notifyListeners();
    }
  }

// Helper method: Reset all call states
  void _resetCallState() {
    log("🔄 Resetting call state...");

    _remoteUid = null;
    _isJoined = false;
    _isInCall = false;
    _callState = CallState.connecting;
    _isMicrophoneMuted = false;
    _isVideoMuted = false;
    _callDuration = Duration.zero;
    _callDurationForAppbar = 0;
    _isLoading = false;
    _error = "";
    _currentRole = "";
    _sessionId = "";
    _isCaller = false;
    token = null;

    // Clear API data
    setTokenApiData(ApiResponse.completed(null));

    // Cancel any pending operations
    _callTimer?.cancel();
    _callTimer = null;

    log("✅ Call state reset complete");
  }

// Emergency cleanup method
  void _forceCleanup() {
    log("🚨 Force cleaning up...");

    try {
      // Cancel timer
      _callTimer?.cancel();
      _callTimer = null;

      // Try to leave channel
      try {
        _engine?.leaveChannel();
      } catch (e) {
        log("⚠️ Error in force leave channel: $e");
      }

      // Try to release engine
      try {
        _engine?.release();
      } catch (e) {
        log("⚠️ Error in force release: $e");
      }

      // Reset all states
      _resetCallState();
      _isInitialized = false;

      log("✅ Force cleanup completed");
    } catch (e) {
      log("❌ Error in force cleanup: $e");
    }
  }

// Complete call termination
  Future<void> terminateCallCompletely() async {
    log("🛑 Terminating call completely...");

    await endCall(null);

    // Additional cleanup
    _currentRole = "";
    _sessionId = "";
    _isCaller = false;

    log("✅ Call terminated completely");
  }

// Screen se back jaane par call karen
  Future<void> onBackPressed(BuildContext context) async {
    log("🔙 Back pressed, ending call...");

    // Agar call chal raha hai to confirmation show karein
    if (_isInCall || _isJoined) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Leave Call"),
          content: const Text("Are you sure you want to leave the call?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Stay"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Leave", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (shouldLeave) {
        await endCall(context, isManual: true);
      }
    } else {
      // Agar call start nahi hua hai to direct cleanup
      cleanup();
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}