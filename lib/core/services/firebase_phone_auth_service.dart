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
  String? _codeSentVerificationId;
  String? _timeoutVerificationId;
  int? _resendToken;
  String? _e164Phone;

  /// Set only after a successful [codeSent] for the current send attempt.
  bool _otpCodeSent = false;

  /// Play Store SMS retriever signed in without the user typing the code.
  bool _isAutoVerified = false;
  UserCredential? _lastUserCredential;
  Future<UserCredential>? _signInInFlight;
  bool _sendFailed = false;

  /// Countdown seconds until resend is allowed (0 = allowed).
  int _resendCooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _operationTimeoutTimer;

  /// Auto-retrieval window. Play Integrity SMS retriever needs more than 60s
  /// or the session id is invalidated before the user (or autofill) submits.
  static const Duration _verifyPhoneTimeout = Duration(seconds: 120);
  static const Duration _operationHardTimeout = Duration(seconds: 150);
  static const int _defaultResendCooldown = 60;

  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingCode => _isVerifyingCode;
  bool get isBusy => _isSendingOtp || _isVerifyingCode;

  String? get lastErrorCode => _lastErrorCode;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get userFacingMessage => _userFacingMessage;

  String? get verificationId => _verificationId;
  int get resendCooldownSeconds => _resendCooldownSeconds;

  /// True after [codeSent], auto-retrieval timeout, or Play Store auto-verify.
  bool get hasPendingPhoneVerification =>
      _verificationId != null || _isAutoVerified;

  /// Play Integrity / SMS retriever already consumed the one-time code.
  bool get isAutoVerified => _isAutoVerified;

  UserCredential? get lastUserCredential => _lastUserCredential;

  bool get canResendOtp =>
      _resendCooldownSeconds == 0 && !_isSendingOtp && _e164Phone != null;

  /// E.164 number used for the current / last OTP request (for UI labels).
  String? get phoneE164 => _e164Phone;

  /// Clears SMS verification state (e.g. before a new number).
  void resetVerificationState() {
    _verificationId = null;
    _codeSentVerificationId = null;
    _timeoutVerificationId = null;
    _resendToken = null;
    _e164Phone = null;
    _otpCodeSent = false;
    _isAutoVerified = false;
    _lastUserCredential = null;
    _sendFailed = false;
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
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
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
        if (isIos) {
          return 'Security verification failed on iOS.\n\n'
              'Phone OTP needs an APNs Authentication Key in Firebase '
              '(Project settings → Cloud Messaging → Apple apps). '
              'Without it, SMS verification cannot complete on TestFlight.\n\n'
              'Also confirm Phone sign-in is enabled and the iOS app '
              'bundle ID is com.thebabyland.';
        }
        return 'Security verification failed. This usually happens when:\n'
            '• App is not installed from Play Store (reCAPTCHA required)\n'
            '• SHA-1/SHA-256 not configured in Firebase\n\n'
            'For testing, use Firebase test numbers in Console.\n'
            'For production, ensure SHA fingerprints are registered.';
      case 'captcha-check-failed':
        if (isIos) {
          return 'Security check failed on iOS.\n\n'
              'Upload an APNs key to Firebase Cloud Messaging for '
              'com.thebabyland, then try again. '
              'If a browser page opens for verification, complete it and return to the app.';
        }
        return 'Security check failed. Please:\n'
            '• Ensure Play Services is up to date\n'
            '• Try again in a moment\n'
            '• If persistent, use a Firebase test number';
      case 'missing-recaptcha-token':
        return 'Security verification required. Please wait a moment and try again.';
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
          if (isIos) {
            return 'Security verification failed on iOS.\n\n'
                'Firebase could not verify this TestFlight build.\n'
                'Most common fix: Firebase Console → Project settings → '
                'Cloud Messaging → upload APNs Authentication Key (.p8) '
                'for Apple apps (bundle com.thebabyland).\n\n'
                'Also check internet and try again. '
                'If a Safari verification page appears, complete it.';
          }
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

  static bool _phonesMatch(String a, String b) {
    final da = PhoneNormalize.digitsOnly(a);
    final db = PhoneNormalize.digitsOnly(b);
    if (da.isEmpty || db.isEmpty) return false;
    if (da == db) return true;
    final tail = da.length >= 10 ? da.substring(da.length - 10) : da;
    final tailB = db.length >= 10 ? db.substring(db.length - 10) : db;
    return tail == tailB;
  }

  bool _phoneMatchesCurrentUser() {
    final expected = _e164Phone;
    final actual = _auth.currentUser?.phoneNumber;
    if (expected == null || actual == null) return false;
    return _phonesMatch(expected, actual);
  }

  UserCredential? _existingVerifiedCredential() {
    final last = _lastUserCredential;
    if (last == null) return null;
    if (_isAutoVerified) return last;
    final lastPhone = last.user?.phoneNumber;
    if (lastPhone != null &&
        _e164Phone != null &&
        _phonesMatch(lastPhone, _e164Phone!)) {
      return last;
    }
    if (_phoneMatchesCurrentUser()) return last;
    return null;
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

  static const Duration _recaptchaRetryDelay = Duration(seconds: 3);

  /// Sends or re-sends the SMS OTP via [FirebaseAuth.verifyPhoneNumber].
  ///
  /// [isResend]: pass `true` after first [codeSent] to use [forceResendingToken] when supported.
  /// Automatically retries once on `missing-recaptcha-token` errors.
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
    _sendFailed = false;
    _isAutoVerified = false;
    _lastUserCredential = null;
    if (!isResend) {
      _verificationId = null;
      _codeSentVerificationId = null;
      _timeoutVerificationId = null;
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

    // Drop a leftover Firebase session (previous OTP / Google mix) so the
    // new phone credential is the only auth user after verify.
    try {
      if (_auth.currentUser != null) {
        _log('sendOtp: signing out leftover uid=${_auth.currentUser?.uid}');
        await _auth.signOut();
      }
    } catch (e) {
      _log('sendOtp: leftover signOut failed', error: e);
    }

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
      _startVerifyPhoneNumber(
        phone: phone,
        forceResendingToken: isResend ? _resendToken : null,
        completer: completer,
        completeOk: completeOk,
        completeErr: completeErr,
        allowRecaptchaRetry: true,
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

  void _startVerifyPhoneNumber({
    required String phone,
    required int? forceResendingToken,
    required Completer<void> completer,
    required void Function() completeOk,
    required void Function(Object e) completeErr,
    required bool allowRecaptchaRetry,
  }) async {
    _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: _verifyPhoneTimeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _handleVerificationCompleted(
          credential,
          completeOk: completeOk,
          completeErr: completeErr,
        );
      },
      verificationFailed: (FirebaseAuthException e) async {
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
            'allowRecaptchaRetry': allowRecaptchaRetry,
          },
        );
        _logAuthCallback(
          'verificationFailed',
          'code=${e.code} message=${e.message ?? ""} plugin=${e.plugin}',
        );
        _log('verificationFailed', error: e);

        final isRecaptchaError = e.code == 'missing-recaptcha-token' ||
            (e.message ?? '').toLowerCase().contains('recaptcha');
        if (isRecaptchaError && allowRecaptchaRetry && !completer.isCompleted) {
          _log('verificationFailed: reCAPTCHA error — retrying with recaptcha flow');
          _otpCodeSent = false;
          _verificationId = null;
          _codeSentVerificationId = null;
          _timeoutVerificationId = null;
          _resendToken = null;
          _endSendOtp();
          _clearOperationTimeout();
          _userFacingMessage = 'Retrying with security verification...';
          notifyListeners();
          await Future.delayed(_recaptchaRetryDelay);
          if (completer.isCompleted) return;
          try {
            await _auth.setSettings(
              appVerificationDisabledForTesting: false,
              forceRecaptchaFlow: true,
            );
            _log('setSettings: forceRecaptchaFlow=true for retry');
          } catch (_) {}
          _beginSendOtp();
          _clearOperationTimeout();
          _operationTimeoutTimer = Timer(_operationHardTimeout, () {
            if (!completer.isCompleted) {
              _log('sendOtp HARD TIMEOUT after recaptcha retry');
              if (_isSendingOtp) {
                _endSendOtp();
                _userFacingMessage =
                    'Request timed out. Check network, Firebase config (SHA-1), and try again.';
                notifyListeners();
              }
              completer.completeError(TimeoutException('verifyPhoneNumber'));
            }
          });
          _startVerifyPhoneNumber(
            phone: phone,
            forceResendingToken: null,
            completer: completer,
            completeOk: completeOk,
            completeErr: completeErr,
            allowRecaptchaRetry: false,
          );
          return;
        }

        _sendFailed = true;
        _otpCodeSent = false;
        _verificationId = null;
        _codeSentVerificationId = null;
        _timeoutVerificationId = null;
        _resendToken = null;
        _isAutoVerified = false;
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
        _codeSentVerificationId = verificationId;
        _timeoutVerificationId = null;
        _resendToken = resendToken;
        _endSendOtp();
        _clearOperationTimeout();
        _startResendCooldown();
        completeOk();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _handleAutoRetrievalTimeout(verificationId);
      },
    );
  }

  Future<void> _handleVerificationCompleted(
    PhoneAuthCredential credential, {
    required void Function() completeOk,
    required void Function(Object e) completeErr,
  }) async {
    _log('verificationCompleted (auto) — signing in');
    try {
      final userCred = await _signInWithCredentialOnce(credential);
      _isAutoVerified = true;
      _otpCodeSent = true;
      _lastUserCredential = userCred;
      final vid = credential.verificationId;
      if (vid != null && vid.isNotEmpty) {
        _verificationId = vid;
        _codeSentVerificationId = vid;
      }
      _log('verificationCompleted: signIn success uid=${userCred.user?.uid}');
      _endSendOtp();
      _clearOperationTimeout();
      notifyListeners();
      completeOk();
    } catch (e, st) {
      _log('verificationCompleted signIn failed', error: e, stack: st);
      _endSendOtp();
      _clearOperationTimeout();
      completeErr(e is Exception ? e : Exception(e.toString()));
    }
  }

  void _handleAutoRetrievalTimeout(String verificationId) {
    _logAuthCallback(
      'codeAutoRetrievalTimeout',
      'verificationIdLen=${verificationId.length}',
    );
    _log('codeAutoRetrievalTimeout verificationId=$verificationId');
    if (_sendFailed || _isAutoVerified) return;
    // Play Store may mint a new session id when auto-retrieval ends.
    // Sticking with the codeSent id causes session-expired on manual entry.
    if (verificationId.isNotEmpty) {
      _timeoutVerificationId = verificationId;
      _verificationId = verificationId;
      _otpCodeSent = true;
      notifyListeners();
    }
  }

  Future<UserCredential> _signInWithCredentialOnce(
    PhoneAuthCredential credential,
  ) async {
    final existing = _existingVerifiedCredential();
    if (existing != null) {
      _log('_signInWithCredentialOnce: already signed in as ${existing.user?.uid}');
      return existing;
    }
    final inFlight = _signInInFlight;
    if (inFlight != null) {
      _log('_signInWithCredentialOnce: awaiting in-flight sign-in');
      return inFlight;
    }
    final future = _auth.signInWithCredential(credential);
    _signInInFlight = future;
    try {
      final userCred = await future;
      _lastUserCredential = userCred;
      return userCred;
    } finally {
      _signInInFlight = null;
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
  ///
  /// Play Store auto-verify may have already signed in; this must not call
  /// [FirebaseAuth.signInWithCredential] a second time (session-expired).
  Future<UserCredential> verifySmsCode(String smsCode) async {
    final inFlight = _signInInFlight;
    if (inFlight != null) {
      _log('verifySmsCode: waiting for in-flight auto sign-in');
      try {
        await inFlight;
      } catch (_) {}
    }

    final already = _existingVerifiedCredential();
    if (already != null) {
      _log('verifySmsCode: already verified uid=${already.user?.uid}');
      _isAutoVerified = true;
      return already;
    }

    if (_isVerifyingCode) {
      _log('verifySmsCode ignored: already in progress');
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Verification already in progress.',
      );
    }

    if (!_otpCodeSent) {
      throw StateError('No verification in progress. Request OTP first.');
    }

    final trimmed = smsCode.trim();
    if (trimmed.isEmpty) {
      throw StateError('No verification in progress. Request OTP first.');
    }

    _isVerifyingCode = true;
    _clearError();
    notifyListeners();

    try {
      final candidates = <String>[
        if (_verificationId != null && _verificationId!.isNotEmpty)
          _verificationId!,
        if (_codeSentVerificationId != null &&
            _codeSentVerificationId!.isNotEmpty &&
            _codeSentVerificationId != _verificationId)
          _codeSentVerificationId!,
        if (_timeoutVerificationId != null &&
            _timeoutVerificationId!.isNotEmpty &&
            _timeoutVerificationId != _verificationId &&
            _timeoutVerificationId != _codeSentVerificationId)
          _timeoutVerificationId!,
      ];
      if (candidates.isEmpty) {
        throw StateError('No verification in progress. Request OTP first.');
      }

      FirebaseAuthException? lastAuthError;
      for (final vid in candidates) {
        try {
          _log('verifySmsCode: trying verificationId=${vid.substring(0, vid.length > 8 ? 8 : vid.length)}...');
          final credential = PhoneAuthProvider.credential(
            verificationId: vid,
            smsCode: trimmed,
          );
          final userCred = await _signInWithCredentialOnce(credential);
          _verificationId = vid;
          _log('verifySmsCode: success uid=${userCred.user?.uid}');
          return userCred;
        } on FirebaseAuthException catch (e) {
          lastAuthError = e;
          final recoverable = e.code == 'session-expired' ||
              e.code == 'invalid-verification-code' ||
              e.code == 'invalid-verification-id';
          if (!recoverable) rethrow;
          _log('verifySmsCode: candidate failed code=${e.code}; trying next candidate');
          continue;
        }
      }
      if (lastAuthError != null) throw lastAuthError;
      throw StateError('No verification in progress. Request OTP first.');
    } on FirebaseAuthException catch (e) {
      final recovered = _existingVerifiedCredential();
      if (recovered != null &&
          (e.code == 'session-expired' ||
              e.code == 'invalid-verification-code' ||
              e.code == 'invalid-verification-id')) {
        _log('verifySmsCode: recovered after ${e.code} (already signed in)');
        _isAutoVerified = true;
        return recovered;
      }
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
    _codeSentVerificationId = null;
    _timeoutVerificationId = null;
    _resendToken = null;
    _e164Phone = null;
    _otpCodeSent = false;
    _isAutoVerified = false;
    _lastUserCredential = null;
    _sendFailed = false;
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
