import 'dart:async';
import 'dart:developer' as developer;

import 'package:babyland/core/auth/phone_normalize.dart';
import 'package:babyland/core/debug/agent_debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Phone Authentication with logging, resend, loading state, and timeouts.
///
/// **Console / project checklist (OTP not sending is usually config, not code):**
/// - Firebase Console → Authentication → Sign-in method → **Phone** enabled.
/// - **Android:** Add **SHA-1** and **SHA-256** (debug + release) in Project settings
///   → Your apps → Android app. Must match the keystore used to build the APK.
/// - **google-services.json** in `android/app/` must match package `applicationId`.
/// - **iOS:** Upload APNs key/certs if required; add `GoogleService-Info.plist`.
/// - **Rate limits:** Too many requests → wait or use Firebase **test phone numbers**
///   (Authentication → Phone → Phone numbers for testing).
/// - **E.164:** Numbers must include country code, e.g. `+919876543210`.
///
/// Wire this service in your UI with [ChangeNotifierProvider] or listen with [addListener].
class FirebasePhoneAuthService extends ChangeNotifier {
  FirebasePhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  bool _isSendingOtp = false;
  bool _isVerifyingCode = false;
  String? _lastErrorCode;
  String? _lastErrorMessage;
  String? _userFacingMessage;

  String? _verificationId;
  int? _resendToken;
  String? _e164Phone;

  /// Set only after a successful [codeSent] for the current send attempt.
  bool _otpCodeSent = false;

  /// Countdown seconds until resend is allowed (0 = allowed).
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _operationTimeoutTimer;

  static const Duration _verifyPhoneTimeout = Duration(seconds: 60);
  static const Duration _operationHardTimeout = Duration(seconds: 120);
  static const int _defaultResendCooldown = 60;

  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingCode => _isVerifyingCode;
  bool get isBusy => _isSendingOtp || _isVerifyingCode;

  String? get lastErrorCode => _lastErrorCode;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get userFacingMessage => _userFacingMessage;

  String? get verificationId => _verificationId;
  int get resendCooldownSeconds => _resendCooldownSeconds;

  /// True after [codeSent] (or timeout callback) — safe gate before OTP UI.
  bool get hasPendingPhoneVerification => _verificationId != null;

  bool get canResendOtp => _resendCooldownSeconds == 0 && !_isSendingOtp && _e164Phone != null;

  /// E.164 number used for the current / last OTP request (for UI labels).
  String? get phoneE164 => _e164Phone;

  /// Clears SMS verification state (e.g. before a new number).
  void resetVerificationState() {
    _verificationId = null;
    _resendToken = null;
    _e164Phone = null;
    _otpCodeSent = false;
    _cooldownTimer?.cancel();
    _resendCooldownSeconds = 0;
    _clearError();
    notifyListeners();
  }

  /// Always logged (debug + release APK) + forwarded to Crashlytics for device logs.
  void _logAuthCallback(String name, String detail) {
    final line = '[FirebasePhoneAuth] $name: $detail';
    developer.log(line, name: 'FirebasePhoneAuth');
    // ignore: avoid_print
    print(line);
    try {
      FirebaseCrashlytics.instance.log(line);
    } catch (_) {}
  }

  void _log(String message, {Object? error, StackTrace? stack}) {
    final msg = '[FirebasePhoneAuth] $message';
    if (kDebugMode) {
      developer.log(msg, name: 'FirebasePhoneAuth', error: error, stackTrace: stack);
    }
    // ignore: avoid_print
    print('$msg${error != null ? ' | $error' : ''}');
  }

  void _setError(FirebaseAuthException e) {
    _lastErrorCode = e.code;
    _lastErrorMessage = e.message;
    _userFacingMessage = mapFirebaseAuthExceptionToMessage(e);
    _log('FirebaseAuthException: code=${e.code} message=${e.message} '
        'credential=${e.credential} email=${e.email}', error: e);
    notifyListeners();
  }

  void _clearError() {
    _lastErrorCode = null;
    _lastErrorMessage = null;
    _userFacingMessage = null;
  }

  /// Maps [FirebaseAuth] error codes to user-readable strings.
  static String mapFirebaseAuthExceptionToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use country code with + (e.g. +91…).';
      case 'missing-phone-number':
        return 'Phone number is missing.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later or use a test number in Firebase Console.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'missing-client-identifier':
      case 'invalid-app-credential':
        return 'Security verification failed. This usually happens when:\n'
            '• App is not installed from Play Store (reCAPTCHA required)\n'
            '• SHA-1/SHA-256 not configured in Firebase\n\n'
            'For testing, use Firebase test numbers in Console.\n'
            'For production, ensure SHA fingerprints are registered.';
      case 'captcha-check-failed':
        return 'Security check failed. Please:\n'
            '• Ensure Play Services is up to date\n'
            '• Try again in a moment\n'
            '• If persistent, use a Firebase test number';
      case 'missing-recaptcha-token':
        return 'Security verification required. Please wait for the '
            'reCAPTCHA verification to complete.';
      case 'session-expired':
      case 'invalid-verification-code':
        return 'Invalid or expired code. Request a new SMS and try again.';
      case 'invalid-verification-id':
        return 'Verification expired. Request a new code.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        final msg = (e.message ?? '').toLowerCase();
        if (msg.contains('recaptcha') || msg.contains('reCAPTCHA')) {
          return 'Security verification (reCAPTCHA) failed.\n\n'
              'This happens when the app cannot complete reCAPTCHA verification. '
              'Please check:\n'
              '• SHA-1 and SHA-256 fingerprints are registered in Firebase Console\n'
              '• Internet connection is active\n'
              '• Play Services is up to date\n\n'
              'If the issue persists, contact support.';
        }
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Authentication failed (${e.code}).';
    }
  }

  /// Normalize to E.164: digits with leading +. If no +, prepends [defaultCountryCallingCode] without +.
  /// Example: default `91` → input `9876543210` becomes `+919876543210`.
  static String normalizeToE164(
    String raw, {
    String defaultCountryCallingCode = '91',
  }) {
    // Keep in sync with [PhoneNormalize.toE164] (auth signup / verify-otp).
    return PhoneNormalize.toE164(
      raw,
      defaultCountryCallingCode: defaultCountryCallingCode,
    );
  }

  void _startResendCooldown([int seconds = _defaultResendCooldown]) {
    _cooldownTimer?.cancel();
    _resendCooldownSeconds = seconds;
    notifyListeners();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldownSeconds <= 1) {
        _resendCooldownSeconds = 0;
        t.cancel();
      } else {
        _resendCooldownSeconds--;
      }
      notifyListeners();
    });
  }

  void _clearOperationTimeout() {
    _operationTimeoutTimer?.cancel();
    _operationTimeoutTimer = null;
  }

  void _beginSendOtp() {
    _isSendingOtp = true;
    _clearError();
    notifyListeners();
  }

  void _endSendOtp() {
    _isSendingOtp = false;
    notifyListeners();
  }

  /// Sends or re-sends the SMS OTP via [FirebaseAuth.verifyPhoneNumber].
  ///
  /// [isResend]: pass `true` after first [codeSent] to use [forceResendingToken] when supported.
  Future<void> sendOtp(
    String phoneRaw, {
    bool isResend = false,
    String defaultCountryCallingCode = '91',
  }) async {
    if (_isSendingOtp) {
      _log('sendOtp ignored: already in progress');
      return;
    }

    final phone = normalizeToE164(phoneRaw, defaultCountryCallingCode: defaultCountryCallingCode);
    _e164Phone = phone;
    if (!isResend) {
      _verificationId = null;
      _resendToken = null;
      _otpCodeSent = false;
    }
    _log('sendOtp start phone=$phone isResend=$isResend');
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H12',
      location: 'firebase_phone_auth_service:sendOtp',
      message: 'verifyPhoneNumber starting',
      runId: const String.fromEnvironment(
        'APP_BUILD_TAG',
        defaultValue: 'otp-v5',
      ),
      data: {
        'phoneLen': phone.length,
        'isResend': isResend,
        'kDebugMode': kDebugMode,
      },
    );
    // #endregion

    _beginSendOtp();
    _clearOperationTimeout();

    final completer = Completer<void>();
    _operationTimeoutTimer = Timer(_operationHardTimeout, () {
      if (!completer.isCompleted) {
        _log('sendOtp HARD TIMEOUT after $_operationHardTimeout');
        if (_isSendingOtp) {
          _endSendOtp();
          _userFacingMessage =
              'Request timed out. Check network, Firebase config (SHA-1), and try again.';
          notifyListeners();
        }
        completer.completeError(TimeoutException('verifyPhoneNumber'));
      }
    });

    void completeOk() {
      if (!completer.isCompleted) completer.complete();
    }

    void completeErr(Object e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    try {
      // Do not rely on the Future from verifyPhoneNumber alone — use callbacks.
      _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: _verifyPhoneTimeout,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _log('verificationCompleted (auto) — signing in');
          try {
            await _auth.signInWithCredential(credential);
            _log('verificationCompleted: signIn success uid=${_auth.currentUser?.uid}');
            _endSendOtp();
            _clearOperationTimeout();
            completeOk();
          } catch (e, st) {
            _log('verificationCompleted signIn failed', error: e, stack: st);
            _endSendOtp();
            _clearOperationTimeout();
            completeErr(e is Exception ? e : Exception(e.toString()));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          // #region agent log
          agentDebugLog(
            hypothesisId: 'H10',
            location: 'firebase_phone_auth_service:verificationFailed',
            message: 'Phone OTP verificationFailed',
            runId: const String.fromEnvironment(
              'APP_BUILD_TAG',
              defaultValue: 'otp-v5',
            ),
            data: {
              'code': e.code,
              'message': e.message ?? '',
              'phone': phone,
            },
          );
          // #endregion
          _logAuthCallback(
            'verificationFailed',
            'code=${e.code} message=${e.message ?? ""} plugin=${e.plugin}',
          );
          _log('verificationFailed', error: e);
          _otpCodeSent = false;
          _verificationId = null;
          _resendToken = null;
          _setError(e);
          _endSendOtp();
          _clearOperationTimeout();
          try {
            FirebaseCrashlytics.instance.recordError(
              e,
              null,
              reason: 'Firebase PhoneAuth verificationFailed ${e.code}',
              fatal: false,
            );
          } catch (_) {}
          completeErr(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _logAuthCallback(
            'codeSent',
            'verificationIdLen=${verificationId.length} resendToken=${resendToken ?? "null"}',
          );
          _log('codeSent verificationId=$verificationId resendToken=$resendToken');
          _otpCodeSent = true;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _endSendOtp();
          _clearOperationTimeout();
          _startResendCooldown();
          completeOk();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logAuthCallback('codeAutoRetrievalTimeout', 'verificationIdLen=${verificationId.length}');
          _log('codeAutoRetrievalTimeout verificationId=$verificationId');
          // Backup: some devices deliver timeout before codeSent is processed.
          // Never accept after verificationFailed — that would reuse a stale ID.
          if (!_otpCodeSent &&
              _verificationId == null &&
              verificationId.isNotEmpty) {
            _verificationId = verificationId;
            notifyListeners();
          }
        },
      );

      await completer.future;
    } on FirebaseAuthException catch (e) {
      _setError(e);
      _endSendOtp();
      _clearOperationTimeout();
      rethrow;
    } on TimeoutException {
      _endSendOtp();
      _clearOperationTimeout();
      rethrow;
    } catch (e, st) {
      _log('sendOtp unexpected error', error: e, stack: st);
      _userFacingMessage = 'Something went wrong. Please try again.';
      _endSendOtp();
      _clearOperationTimeout();
      rethrow;
    }
  }

  /// Resend SMS using stored [forceResendingToken] when available.
  Future<void> resendOtp({String defaultCountryCallingCode = '91'}) async {
    if (_e164Phone == null) {
      _userFacingMessage = 'Enter phone number first.';
      notifyListeners();
      return;
    }
    if (!canResendOtp && _resendCooldownSeconds > 0) {
      _userFacingMessage = 'Please wait ${_resendCooldownSeconds}s before resending.';
      notifyListeners();
      return;
    }
    _log('resendOtp');
    await sendOtp(_e164Phone!, isResend: true, defaultCountryCallingCode: defaultCountryCallingCode);
  }

  /// Verifies the 6-digit SMS code and signs in.
  Future<UserCredential> verifySmsCode(String smsCode) async {
    if (_isVerifyingCode) {
      _log('verifySmsCode ignored: already in progress');
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Verification already in progress.',
      );
    }

    final vid = _verificationId;
    if (vid == null || !_otpCodeSent) {
      throw StateError('No verification in progress. Request OTP first.');
    }

    _isVerifyingCode = true;
    _clearError();
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode.trim(),
      );
      _log('verifySmsCode: calling signInWithCredential');
      final userCred = await _auth.signInWithCredential(credential);
      _log('verifySmsCode: success uid=${userCred.user?.uid}');
      return userCred;
    } on FirebaseAuthException catch (e) {
      _setError(e);
      rethrow;
    } finally {
      _isVerifyingCode = false;
      notifyListeners();
    }
  }

  /// Sign out (clears local verification state for UI).
  Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _resendToken = null;
    _e164Phone = null;
    _otpCodeSent = false;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _clearOperationTimeout();
    super.dispose();
  }
}
