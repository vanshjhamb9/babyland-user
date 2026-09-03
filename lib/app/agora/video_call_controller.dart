import 'package:babyland/core/consultation/agora_rtc_session_dto.dart';
import 'package:babyland/core/consultation/patient_consultation_rtc_repository.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:babyland/core/observability/app_audit_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
 
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

  RtcEngine? _engineOrNull;
  RtcEngine get engine {
    final e = _engineOrNull;
    if (e == null) {
      throw StateError('Video engine not initialized');
    }
    return e;
  }

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

  AgoraRtcSessionDto? _activeBackendSession;
  AgoraRtcSessionDto? get activeBackendSession => _activeBackendSession;

  Timer? _tokenExpiryTimer;
  bool _channelBusy = false;

  final PatientConsultationRtcRepository _rtcRepository =
      PatientConsultationRtcRepository();

  bool _sessionJoinInFlight = false;
  Completer<void>? _joinChannelCompleter;
  RtcEngineEventHandler? _registeredEventHandler;

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

  /// Authoritative join path — all Agora credentials come from [dto] (backend).
  Future<void> joinConsultationWithBackendRtc({
    required BuildContext context,
    required AgoraRtcSessionDto dto,
  }) async {
    if (_channelBusy && !_sessionJoinInFlight) {
      log('⚠️ _channelBusy stuck true (stale from previous attempt), resetting');
      _channelBusy = false;
    }
    if (_channelBusy) {
      log('⚠️ joinConsultationWithBackendRtc blocked: _channelBusy=true');
      throw StateError('Video call is already being established. Please wait.');
    }
    if (dto.isExpired || dto.expiresTooSoon) {
      AppAuditLog.instance.log(
        'token_expired',
        component: 'VideoCallProvider',
        consultationId: dto.consultationId,
      );
      throw StateError('Video session link expired. Refresh and try again.');
    }

    _channelBusy = true;
    _sessionJoinInFlight = true;
    _isLoading = true;
    _error = '';
    _sessionId = dto.sessionId;
    notifyListeners();

    AppAuditLog.instance.log(
      'join_attempt',
      component: 'VideoCallProvider',
      consultationId: dto.consultationId,
      traceId: dto.sessionId,
    );

    try {
      _activeBackendSession = dto;
      log('📡 Step 1: Requesting permissions...');
      await _requestPermissions();
      log('📡 Step 2: Resolving Agora App ID...');
      final agoraAppId = _resolveAgoraAppId(dto);
      log('📡 Step 3: Preparing engine (App ID: ${agoraAppId.substring(0, math.min(8, agoraAppId.length))})...');

      await _prepareEngineForJoin(context, agoraAppId: agoraAppId);
      log('📡 Step 4: Engine ready. Joining channel...');

      await joinChannel(
        channelName: dto.channelName,
        uid: dto.uid.toString(),
        numericUid: dto.uid,
        token: dto.token,
      );
      log('📡 Step 5: Channel joined successfully');

      _scheduleTokenRenewal(dto.consultationId);

      AppAuditLog.instance.log(
        'join_success',
        component: 'VideoCallProvider',
        consultationId: dto.consultationId,
        traceId: dto.sessionId,
      );
    } catch (e, st) {
      log('joinConsultationWithBackendRtc failed: $e\n$st');
      _error = e.toString();
      AppAuditLog.instance.log(
        'join_failure',
        component: 'VideoCallProvider',
        consultationId: dto.consultationId,
        outcome: e.toString(),
      );
      if (context.mounted) {
        AppPopUp.showToast(
          message: 'Failed to start video call. Refresh and try again.',
        );
      }
      rethrow;
    } finally {
      _channelBusy = false;
      _sessionJoinInFlight = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  String _resolveAgoraAppId(AgoraRtcSessionDto dto) {
    final fromBackend = dto.appId?.trim();
    if (fromBackend != null && fromBackend.isNotEmpty) return fromBackend;
    final fromEnv = AppEnvironment.agoraAppIdFromEnv;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    AppAuditLog.instance.log(
      'join_failure',
      component: 'VideoCallProvider',
      consultationId: dto.consultationId,
      reason: 'agora_app_id_unresolved',
    );
    throw StateError(
      'Video is not configured: server did not return appId and '
      'AGORA_APP_ID is not set for this build.',
    );
  }

  void _scheduleTokenRenewal(String consultationId) {
    _tokenExpiryTimer?.cancel();
    final exp = _activeBackendSession?.expiresAt;
    if (exp == null) return;
    final untilMs = exp.difference(DateTime.now().toUtc()).inMilliseconds;
    final delayMs = math.max(untilMs - 45000, 20000);
    AppAuditLog.instance.log(
      'token_renew_scheduled',
      component: 'VideoCallProvider',
      consultationId: consultationId,
      reason: '${delayMs}ms',
    );
    _tokenExpiryTimer = Timer(Duration(milliseconds: delayMs), () async {
      try {
        await _renewBackendToken(consultationId);
        _scheduleTokenRenewal(consultationId);
      } catch (e) {
        AppAuditLog.instance.log(
          'token_expired',
          component: 'VideoCallProvider',
          consultationId: consultationId,
          outcome: e.toString(),
        );
      }
    });
  }

  Future<void> _renewBackendToken(String consultationId) async {
    final fresh =
        await _rtcRepository.fetchPatientRtcToken(consultationId: consultationId);
    final active = _activeBackendSession;
    if (active == null || active.consultationId != fresh.consultationId) {
      AppAuditLog.instance.log(
        'channel_mismatch',
        component: 'VideoCallProvider',
        consultationId: consultationId,
        reason: 'token_refresh_consultation_mismatch',
      );
      throw StateError('Token refresh mismatched consultation');
    }
    if (active.channelName != fresh.channelName) {
      AppAuditLog.instance.log(
        'channel_mismatch',
        component: 'VideoCallProvider',
        consultationId: consultationId,
        reason: active.channelName,
        outcome: fresh.channelName,
      );
      throw StateError('Token refresh channel mismatch');
    }
    _activeBackendSession = fresh;
    token = fresh.token;
    try {
      await _engineOrNull!.renewToken(_cleanToken(fresh.token));
    } catch (_) {
      if (_isJoined) await _engineOrNull!.leaveChannel();
      await joinChannel(
        channelName: fresh.channelName,
        uid: fresh.uid.toString(),
        numericUid: fresh.uid,
        token: fresh.token,
      );
    }
    AppAuditLog.instance.log(
      'token_renewed',
      component: 'VideoCallProvider',
      consultationId: consultationId,
    );
    notifyListeners();
  }

  /// Legacy join path — do not use for new code.
  @Deprecated('Use joinConsultationWithBackendRtc')
  Future<void> getVideoCallToken({
    required BuildContext context,
    required String channelName,
    required String uid,
    required String role,
    required String sessionId,
    bool isCaller = false,
  }) async {
    if (_sessionJoinInFlight) {
      AppAuditLog.instance.log(
        'session_join_blocked_duplicate',
        component: 'VideoCallProvider',
        traceId: sessionId,
      );
      return;
    }
    if (_isLoading) return;
    _sessionJoinInFlight = true;
    AppAuditLog.instance.log(
      'session_join_attempt',
      component: 'VideoCallProvider',
      traceId: sessionId,
    );
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
      log("✅ Token received (length: ${token?.length ?? 0})  $token");

      if (token == null || token!.isEmpty) {
        throw Exception('Token is null or empty');
      }

      if (!_isInitialized) {
        await initializeAgoraEngine(
          context,
          agoraAppId: _resolveAgoraAppId(
            AgoraRtcSessionDto(
              token: token!,
              channelName: channelName,
              uid: numericUid,
              consultationId: sessionId,
              sessionId: sessionId,
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            ),
          ),
        );
      }

      await joinChannel(
        channelName: channelName,
        uid: uid,
        numericUid: numericUid,
        token: token!, // Use the extracted token
      );
      AppAuditLog.instance.log(
        'session_join_success',
        component: 'VideoCallProvider',
        traceId: sessionId,
      );
    } catch (error, stackTrace) {
      log("❌ Error in video call setup: $error");
      log("Stack trace: $stackTrace");
      _error = error.toString();

      if (context.mounted) {
        AppPopUp.showToast(message: "Failed to start video call: $error");
      }
      AppAuditLog.instance.log(
        'session_join_failure',
        component: 'VideoCallProvider',
        traceId: sessionId,
        outcome: error.toString(),
      );
      rethrow;
    } finally {
      _sessionJoinInFlight = false;
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _requestPermissions() async {
    try {
      log('🔐 Requesting permissions (Platform: ${Platform.isIOS ? "iOS" : "Android"})');

      final camStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      log('🔐 Current status — camera: $camStatus, mic: $micStatus');

      if (camStatus.isGranted && micStatus.isGranted) {
        log('✅ Permissions already granted, skipping request');
        return;
      }

      final permissions = <Permission>[
        Permission.microphone,
        Permission.camera,
      ];
      if (Platform.isAndroid) {
        permissions.add(Permission.bluetoothConnect);
      }

      final statuses = await permissions.request().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          log('⚠️ Permission request timed out');
          return <Permission, PermissionStatus>{};
        },
      );

      log('🔐 Permission results: $statuses');

      if (statuses[Permission.microphone]?.isGranted != true ||
          statuses[Permission.camera]?.isGranted != true) {
        throw StateError(
          'Camera and microphone access are required to join the video consultation.',
        );
      }

      log('✅ Camera and microphone permissions granted');
    } catch (e) {
      log('❌ Error requesting permissions: $e');
      rethrow;
    }
  }

  /// Ensures a clean RTC engine for each join attempt (provider is app-wide).
  Future<void> _prepareEngineForJoin(
    BuildContext context, {
    required String agoraAppId,
  }) async {
    await _releaseEngine();
    await initializeAgoraEngine(context, agoraAppId: agoraAppId);
  }

  Future<void> _releaseEngine() async {
    _joinChannelCompleter?.completeError(
      StateError('Video engine reset before join completed'),
    );
    _joinChannelCompleter = null;
    _tokenExpiryTimer?.cancel();
    _tokenExpiryTimer = null;

    if (_registeredEventHandler != null) {
      try {
        _engineOrNull?.unregisterEventHandler(_registeredEventHandler!);
      } catch (e) {
        log('⚠️ unregisterEventHandler: $e');
      }
      _registeredEventHandler = null;
    }

    if (_isInitialized) {
      try {
        if (_isJoined) await _engineOrNull?.leaveChannel();
        await _engineOrNull?.release();
      } catch (e) {
        log('⚠️ Engine release: $e');
      }
    }

    _isInitialized = false;
    _isJoined = false;
    _remoteUid = null;
  }

  void _signalJoinSuccess() {
    final completer = _joinChannelCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _signalJoinFailure(Object error) {
    final completer = _joinChannelCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  Future<void> _awaitJoinChannelConfirmation({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _joinChannelCompleter = Completer<void>();
    try {
      await _joinChannelCompleter!.future.timeout(timeout);
    } on TimeoutException {
      throw StateError(
        'Timed out joining the video channel. Check your connection and try again.',
      );
    } finally {
      _joinChannelCompleter = null;
    }
  }


  /// Maps a string user id to a stable Agora numeric uid.
  ///
  /// Agora uids must be unique per participant within a channel; a collision
  /// makes the second joiner evict the first, so patient and doctor would
  /// silently fail to stay connected. The previous byte-sum `% 100000` hash
  /// collided far too easily (e.g. hex ObjectIds/UUIDs), so we use a 32-bit
  /// FNV-1a hash over the full uid and keep it in Agora's positive int range
  /// (1..2^31-1, never 0 which Agora treats as "auto-assign").
  int _generateNumericUid(String uid) {
    const int fnvOffsetBasis = 0x811c9dc5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffsetBasis;
    for (final byte in utf8.encode(uid)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    // Constrain to a positive 32-bit signed int and avoid 0.
    final numericUid = hash & 0x7fffffff;
    return numericUid == 0 ? 1 : numericUid;
  }

  Future<void> initializeAgoraEngine(
    BuildContext context, {
    required String agoraAppId,
  }) async {
    try {
      log('🚀 Initializing Agora Engine (appId prefix: ${agoraAppId.substring(0, math.min(8, agoraAppId.length))})');

      _engineOrNull = createAgoraRtcEngine();
      await _engineOrNull!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioDefault,
        areaCode: 4294967295,
      ));

      await _engineOrNull!.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );

      await _engineOrNull!.enableVideo();
      await _engineOrNull!.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 800,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ));

      _setupEventHandlers(context);

      _isInitialized = true;
      log("✅ Agora engine initialized successfully");

      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

    } catch (e) {
      log("❌ Error initializing Agora engine: $e");
      rethrow;
    }
  }

  void _setupEventHandlers(BuildContext context) {
    if (_registeredEventHandler != null) {
      try {
        _engineOrNull?.unregisterEventHandler(_registeredEventHandler!);
      } catch (e) {
        log('⚠️ unregisterEventHandler before re-register: $e');
      }
    }

    _registeredEventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        log("✅ Joined channel: ${connection.channelId}, UID: ${connection.localUid}");
        _isJoined = true;
        _isInCall = true;
        _callState = CallState.waitingForRemote;
        _signalJoinSuccess();
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
        _signalJoinFailure(StateError('Agora error $err: $msg'));
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
        if (state == ConnectionStateType.connectionStateFailed &&
            !_isJoined) {
          _signalJoinFailure(
            StateError('Video connection failed ($reason). Try again.'),
          );
        }
      },

      onRtcStats: (connection, stats) {
        _callDurationForAppbar = stats.duration ?? 0;
        if ((stats.duration ?? 0) % 10 == 0) {
          log("📊 Call stats - Duration: ${stats.duration}s, Users: ${stats.userCount}");
        }
        notifyListeners();
      },
    );
    _engineOrNull!.registerEventHandler(_registeredEventHandler!);
  }

  Future<void> joinChannel({
    required String channelName,
    required String uid,
    required int numericUid,
    required String token,
  }) async {
    try {
      log("🎬 Joining channel:");
      log("   Channel: $channelName");
      log("   Numeric UID: $numericUid");
      log("   Token length: ${token.length}");

      try {
        await _engineOrNull!.startPreview().timeout(
          const Duration(seconds: 8),
          onTimeout: () => log('⚠️ startPreview timed out on iOS, continuing'),
        );
      } catch (e) {
        log('⚠️ startPreview failed (non-fatal): $e');
      }

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

      await _engineOrNull!.joinChannel(
        token: cleanToken,
        channelId: channelName,
        uid: numericUid,
        options: options,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw StateError(
          'Agora joinChannel call timed out. Check your network and try again.',
        ),
      );

      await _awaitJoinChannelConfirmation();
      log('✅ Join channel confirmed');

    } catch (e, stackTrace) {
      _signalJoinFailure(e);
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
    await _engineOrNull!.muteLocalAudioStream(_isMicrophoneMuted);
    log("🎤 Microphone ${_isMicrophoneMuted ? 'muted' : 'unmuted'}");
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    _isVideoMuted = !_isVideoMuted;
    await _engineOrNull!.muteLocalVideoStream(_isVideoMuted);
    log("📹 Video ${_isVideoMuted ? 'muted' : 'unmuted'}");
    notifyListeners();
  }

  Future<void> switchCamera() async {
    try {
      await _engineOrNull!.switchCamera();
      log("📸 Camera switched");
    } catch (e) {
      log("❌ Error switching camera: $e");
    }
  }

  Future<void> reinitializeForRemoteVideo() async {
    log("🔄 Reinitializing for remote video...");
    try {
      if (_isJoined) {
        await _engineOrNull?.leaveChannel();
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

  Future<void> cleanup() async {
    try {
      log('🧹 Cleaning up video call...');
      _stopCallTimer();
      await _releaseEngine();

      _channelBusy = false;
      _sessionJoinInFlight = false;
      _isInCall = false;
      _callState = CallState.ended;
      _isMicrophoneMuted = false;
      _isVideoMuted = false;
      _isLoading = false;
      _error = '';
      _activeBackendSession = null;

      log('✅ Video call provider cleaned up');
      notifyListeners();
    } catch (e) {
      log('❌ Error during cleanup: $e');
    }
  }

  /// Fetches a fresh RTC session from the backend (for retry after failure).
  Future<AgoraRtcSessionDto> refreshBackendSession() async {
    final active = _activeBackendSession;
    if (active == null) {
      throw StateError('No active consultation session to refresh');
    }
    final fresh = await _rtcRepository.fetchPatientRtcToken(
      consultationId: active.consultationId,
    );
    _activeBackendSession = fresh;
    return fresh;
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

      await _releaseEngine();

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

    _channelBusy = false;
    _sessionJoinInFlight = false;
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
    log('🚨 Force cleaning up...');

    try {
      _joinChannelCompleter?.completeError(StateError('Force cleanup'));
      _joinChannelCompleter = null;
      _callTimer?.cancel();
      _callTimer = null;

      if (_registeredEventHandler != null) {
        try {
        _engineOrNull?.unregisterEventHandler(_registeredEventHandler!);
        } catch (_) {}
        _registeredEventHandler = null;
      }

      if (_isInitialized) {
        try {
          _engineOrNull?.leaveChannel();
        } catch (_) {}
        try {
          _engineOrNull?.release();
        } catch (_) {}
      }

      _resetCallState();
      _isInitialized = false;

      log('✅ Force cleanup completed');
    } catch (e) {
      log('❌ Error in force cleanup: $e');
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
      await cleanup();
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}