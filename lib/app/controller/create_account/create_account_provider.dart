import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/controller/create_account/model/request_verification_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/core/auth/jwt_utils.dart';
import 'package:babyland/core/auth/phone_normalize.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/error/error_handler.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/set_password_model.dart';

class CreateAccountProvider extends ChangeNotifier {
  CreateAccountProvider() {
    sl.firebasePhoneAuthService.addListener(_onPhoneAuthStateChanged);
  }

  final repo = Provider.of<Repository>(navigatorKey.currentContext!, listen: false);
  final api = NetworkApiServices();

  final emailKey = GlobalKey<FormState>();
  final passwordKey = GlobalKey<FormState>();
  final verifyKey = GlobalKey<FormState>();

  bool _disposed = false;

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    _currentIndex = index;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  static const int _otpPageIndex = 1;

  /// Moves the embedded signup [PageView] to the OTP step and syncs [currentIndex].
  Future<void> _goToPhoneOtpStep() async {
    if (_disposed) return;
    if (!pageController.hasClients) {
      await Future<void>.delayed(Duration.zero);
    }
    if (_disposed) return;
    if (pageController.hasClients) {
      final current = pageController.page?.round() ?? _currentIndex;
      if (current != _otpPageIndex) {
        await pageController.animateToPage(
          _otpPageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    }
    if (_disposed) return;
    changeIndex(_otpPageIndex);
  }

  bool _isShowPass = true;
  bool get isShowPass => _isShowPass;

  setIsShowPass(bool value){
    _isShowPass = value;
    notifyListeners();
  }
  //strong password validation
  bool hasMinLength = false;
  bool hasLetter = false;
  bool hasNumberOrSymbol = false;

  int trueConditionsCount = 0;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final PageController pageController = PageController();

  // NEW AUTH FLOW
  TextEditingController phoneController = TextEditingController();

  /// Dial code without `+`. Default India.
  String _countryCallingCode = '91';
  String get countryCallingCode => _countryCallingCode;

  void setCountryCallingCode(String dial) {
    final next = dial.replaceAll('+', '').trim();
    if (next.isEmpty || next == _countryCallingCode) return;
    _countryCallingCode = next;
    _safeNotify();
  }

  void _onPhoneAuthStateChanged() {
    _safeNotify();
  }

  bool get isSendingPhoneOtp => sl.firebasePhoneAuthService.isSendingOtp;
  int get resendCooldownSeconds => sl.firebasePhoneAuthService.resendCooldownSeconds;
  bool get canResendPhoneOtp => sl.firebasePhoneAuthService.canResendOtp;
  String? get phoneAuthMessage => sl.firebasePhoneAuthService.userFacingMessage;

  //--------------------------request verification
  ApiResponse<RequestVerificationModel>? _forgotPassRequestOtpData = ApiResponse.completed(null);
  ApiResponse<RequestVerificationModel>? get forgotPassRequestOtpData => _forgotPassRequestOtpData;
  void setRequestApiData(ApiResponse<RequestVerificationModel> response) {
    _forgotPassRequestOtpData = response;
    notifyListeners();
  }
  
 Future<void> requestVerification()async{
   _forgotPassRequestOtpData = ApiResponse.loading();
   notifyListeners();
   Map<String, String> data = {
     "name": nameController.text,
     "email": emailController.text,
   };
   try{
     await repository.requestVerification(data).then((value) {
       if(value.success == true){
         _forgotPassRequestOtpData = ApiResponse.completed(value);
         pt(name: "response","${value.message}");
         AppPopUp.showToast(message: "${ value.message} - ${value.data?.code}",duration: Duration(seconds: 10));
         pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
       }else{
         _forgotPassRequestOtpData = ApiResponse.error(value.message);
         pt(name: "response error","${value.message}");
         AppPopUp.showToast(message: value.message ?? "");
       }
       notifyListeners();
     },);
   }catch(e,s){
     pt("Error request varification $e $s ");
     _forgotPassRequestOtpData = ApiResponse.error(e.toString());
     notifyListeners();
   }
 }

//--------------------------otp verification
  ApiResponse<CommonResponseModel>? _otpApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get otpApiData => _otpApiData;
  void setOtpRequestApiData(ApiResponse<CommonResponseModel> response) {
    _otpApiData = response;
    notifyListeners();
  }

 Future<void> otpVerification()async{
   _otpApiData = ApiResponse.loading();
   notifyListeners();

   Map<String, String> data = {
     "email": emailController.text,
     "code": otpController.value.text ,
   };
   try{
     final value = await repository.otpVerification(data);
     if(value.success == true){
       _otpApiData = ApiResponse.completed(value);
       pt(name: "response","${value.message}");
       AppPopUp.showToast(message: value.message ?? "");
       
       // Save token to both legacy and new architecture
       final token = value.token ?? "";
       await SecureStorage.saveToken(token);
       await sl.authService.saveToken(token);
       
       pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
     }else{
       _otpApiData = ApiResponse.error(value.message);
       pt(name: "response error","${value.message}");
       AppPopUp.showToast(message: value.message ?? "");
     }
     notifyListeners();
   }catch(e,s){
     pt("Error request varification $e $s ");
     _otpApiData = ApiResponse.error(e.toString());
     notifyListeners();

   }
 }


  /// Backend + Firebase expect the same E.164 phone (e.g. +9198…).
  String get _phoneE164 => PhoneNormalize.toE164(
        phoneController.text.trim(),
        defaultCountryCallingCode: _countryCallingCode,
      );

  /// Display form for OTP screen (full E.164 when valid).
  String get phoneDisplayE164 {
    final err = PhoneNormalize.validationError(
      phoneController.text.trim(),
      dialCode: _countryCallingCode,
    );
    if (err != null) return phoneController.text.trim();
    return _phoneE164;
  }

  /// True when last `/auth/signup` returned email/phone already exists.
  bool _lastSignupWasConflict = false;
  String? _lastSignupConflictMessage;

  bool _isBenignSignupConflict(String? message, {String? code}) {
    final c = (code ?? '').toUpperCase();
    if (c == 'PHONE_EXISTS' || c == 'EMAIL_EXISTS' || c == 'USER_EXISTS') {
      return true;
    }
    final m = (message ?? '').toLowerCase();
    return m.contains('already') ||
        m.contains('exist') ||
        m.contains('registered') ||
        m.contains('duplicate');
  }

  bool _isNoAccountForPhone(String? message) {
    final m = (message ?? '').toLowerCase();
    return m.contains('no account found') ||
        (m.contains('not found') && m.contains('phone'));
  }

  /// Backend verifies against the Firebase token phone claim — must exist in DB.
  Future<CommonResponseModel> _ensureBackendUser(String phone) async {
    final signupData = <String, String>{
      'email': emailController.text.trim(),
      'phone': phone,
      'password': passwordController.text.trim(),
    };
    pt(name: 'Backend signup payload', '$signupData');
    print('Backend signup payload: $signupData');
    print('Signup API URL: will post to auth/signup');
    final result = await repo.signup(signupData);
    pt(
      name: 'Backend signup result',
      'success=${result.success} message=${result.message}',
    );
    print('Backend signup result: success=${result.success} message=${result.message}');
    return result;
  }

  Future<CommonResponseModel> _verifyOtpWithPhone({
    required String phone,
    required String idToken,
  }) async {
    final data = <String, String>{
      'phone': phone,
      'idToken': idToken,
    };
    pt(name: 'Verify OTP payload', '{phone: $phone, idToken: ***}');
    final value = await repo.verifyOtpSignup(data);
    pt(
      name: 'Verify OTP result',
      'success=${value.success} message=${value.message}',
    );
    print('Auth Response: ${value.toJson()}');
    return value;
  }

  /// verify-otp may look up body.phone or token phone; try common formats.
  Future<CommonResponseModel> _verifyOtpWithVariants({
    required String phone,
    required String idToken,
  }) async {
    CommonResponseModel? last;
    for (final variant in PhoneNormalize.lookupVariants(
      phone,
      defaultCountryCallingCode: _countryCallingCode,
    )) {
      last = await _verifyOtpWithPhone(phone: variant, idToken: idToken);
      if (last.success == true) return last;
      if (!_isNoAccountForPhone(last.message)) return last;
      pt(name: 'Verify OTP', 'no account for $variant — try next format');
    }
    return last ??
        CommonResponseModel(
          success: false,
          message: 'No account found for this phone number',
        );
  }

//-------------------------- NEW AUTH FLOW: signup
  ApiResponse<CommonResponseModel>? _signupApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get signupApiData => _signupApiData;
  bool _signupInFlight = false;

  String _signupErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString();
        final code = data['code']?.toString() ??
            data['error']?['code']?.toString();
        if (code == 'RATE_LIMIT_AUTH' ||
            (msg ?? '').toLowerCase().contains('too many auth')) {
          return 'Too many signup/login attempts. Please wait about 15 minutes and try again.';
        }
        if (msg != null && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 429) {
        return 'Too many signup/login attempts. Please wait about 15 minutes and try again.';
      }
      return ErrorHandler.handle(e).message;
    }
    final phoneAuthMsg = sl.firebasePhoneAuthService.userFacingMessage;
    if (phoneAuthMsg != null) return phoneAuthMsg;
    final raw = e.toString();
    if (raw.toLowerCase().contains('recaptcha')) {
      return 'reCAPTCHA verification failed. Please check your internet connection '
          'and try again. If the issue persists, the app may need SHA fingerprints '
          'registered in Firebase Console.';
    }
    return raw;
  }

  /// Step 1 of signup: validate phone and send Firebase OTP only.
  /// Backend `/auth/signup` runs **after** OTP succeeds in [verifyOtpSignup].
  Future<void> signup() async {
    if (_signupInFlight) return;
    _signupInFlight = true;
    _signupApiData = ApiResponse.loading();
    _lastSignupWasConflict = false;
    _lastSignupConflictMessage = null;
    _safeNotify();

    final phoneErr = PhoneNormalize.validationError(
      phoneController.text.trim(),
      dialCode: _countryCallingCode,
    );
    if (phoneErr != null) {
      _signupApiData = ApiResponse.error(phoneErr);
      AppPopUp.showToast(message: phoneErr, duration: const Duration(seconds: 5));
      _signupInFlight = false;
      _safeNotify();
      return;
    }

    final phone = _phoneE164;
    pt(name: 'Signup OTP start', 'email=${emailController.text.trim()} phone=$phone');
    print('Signup OTP start: phone=$phone (backend account deferred until OTP verify)');
    try {
      await sl.firebasePhoneAuthService.sendOtp(
        phone,
        defaultCountryCallingCode: _countryCallingCode,
      );

      if (_disposed) return;

      if (!sl.firebasePhoneAuthService.hasPendingPhoneVerification) {
        final msg = sl.firebasePhoneAuthService.userFacingMessage ??
            'Could not start phone verification. Check Firebase setup.';
        _signupApiData = ApiResponse.error(msg);
        AppPopUp.showToast(message: msg, duration: const Duration(seconds: 8));
        _safeNotify();
        return;
      }

      _signupApiData = ApiResponse.completed(
        CommonResponseModel(success: true, message: 'OTP sent'),
      );
      await _goToPhoneOtpStep();
      AppPopUp.showToast(message: 'OTP sent. Please verify.');
      _safeNotify();
    } catch (e, s) {
      pt("Error signup $e $s ");
      if (_disposed) return;
      final msg = _signupErrorMessage(e);
      _signupApiData = ApiResponse.error(msg);
      AppPopUp.showToast(message: msg, duration: const Duration(seconds: 8));
      _safeNotify();
    } finally {
      _signupInFlight = false;
    }
  }

  //-------------------------- NEW AUTH FLOW: verify otp
  ApiResponse<CommonResponseModel>? _verifyOtpSignupData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get verifyOtpSignupData => _verifyOtpSignupData;
  bool _verifyOtpInFlight = false;

  /// Step 2 of signup: Firebase SMS verify → backend create account → verify-otp → onboarding.
  Future<void> verifyOtpSignup() async {
    if (_verifyOtpInFlight) return;
    _verifyOtpInFlight = true;
    _verifyOtpSignupData = ApiResponse.loading();
    _safeNotify();
    
    try {
      // 1. Verify SMS with Firebase — phone claim on idToken is source of truth.
      final userCredential = await sl.firebasePhoneAuthService.verifySmsCode(
        otpController.text.trim(),
      );
      // Force refresh so phone_number claim is present for backend verify.
      final idToken = await userCredential.user?.getIdToken(true);
      
      if (idToken == null) {
        throw Exception("Failed to retrieve Firebase ID token");
      }

      final phone = userCredential.user?.phoneNumber?.trim().isNotEmpty == true
          ? userCredential.user!.phoneNumber!.trim()
          : (sl.firebasePhoneAuthService.phoneE164 ?? _phoneE164);

      pt(
        name: 'Verify OTP',
        'firebasePhone=$phone variants=${PhoneNormalize.lookupVariants(phone, defaultCountryCallingCode: _countryCallingCode)}',
      );
      print('Post-OTP: creating backend account for phone=$phone');

      // 2. Create account once with Firebase canonical E.164 (avoid multi-format orphans).
      final created = await _ensureBackendUser(phone);
      pt(
        name: 'Post-OTP signup result',
        'success=${created.success} message=${created.message}',
      );
      if (created.success != true &&
          !_isBenignSignupConflict(created.message)) {
        final raw = created.message ?? 'Failed to create user on backend';
        final msg = raw.toLowerCase().contains('too many')
            ? 'Too many signup/login attempts. Please wait about 15 minutes and try again.'
            : raw;
        throw Exception(msg);
      }
      if (created.success != true &&
          _isBenignSignupConflict(created.message)) {
        _lastSignupWasConflict = true;
        _lastSignupConflictMessage = created.message;
        pt(
          name: 'Post-OTP signup',
          'email/phone already exists — trying verify-otp anyway',
        );
      } else if (created.success == true) {
        _lastSignupWasConflict = false;
        _lastSignupConflictMessage = null;
        print('Post-OTP: backend account created for $phone');
      }

      // 3. Verify phone with backend (issues app tokens).
      final value = await _verifyOtpWithVariants(phone: phone, idToken: idToken);

      if (value.success == true) {
        _verifyOtpSignupData = ApiResponse.completed(value);
        AppPopUp.showToast(message: value.message ?? "OTP Verified");
        
        final token = value.token ?? "";
        final refreshToken = value.refreshToken ?? "";
        if (token.isNotEmpty) {
           await SecureStorage.saveToken(token);
           await sl.authService.saveToken(token);
           final uid = extractUserIdFromAccessJwt(token);
           if (uid != null && uid.isNotEmpty) {
             await SecureStorage.saveUserId(uid);
             await sl.authService.saveUserId(uid);
           }
        }
        if (refreshToken.isNotEmpty) {
          await SecureStorage.saveRefreshToken(refreshToken);
          await sl.authService.saveRefreshToken(refreshToken);
        }

        // 4. Onboarding (basic profile) after successful verified signup.
        await UserLocalData.setNeedsBasicProfile(true);
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(
            navigatorKey.currentContext!,
            AppRoutes.basicProfileView,
          );
        }
      } else if (_isNoAccountForPhone(value.message)) {
        final conflictHint = _lastSignupWasConflict
            ? ' Server said: "${_lastSignupConflictMessage ?? 'already exists'}". '
                'That email/phone may belong to another incomplete account — use a new email+phone or clear the orphan in DB.'
            : '';
        pt(
          name: 'Verify OTP FAILED',
          'no account for $phone after variants. conflict=$_lastSignupWasConflict '
          'serverMsg=${value.message}',
        );
        final msg =
            'Phone OTP is valid, but the server has no account for $phone.$conflictHint';
        _verifyOtpSignupData = ApiResponse.error(msg);
        AppPopUp.showToast(message: msg, duration: const Duration(seconds: 10));
      } else {
        _verifyOtpSignupData = ApiResponse.error(value.message);
        AppPopUp.showToast(message: value.message ?? "OTP failed");
      }
      _safeNotify();
    } catch (e, s) {
      pt("Error verify otp $e $s ");
      if (_disposed) return;
      final msg = sl.firebasePhoneAuthService.userFacingMessage ??
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      _verifyOtpSignupData = ApiResponse.error(msg);
      AppPopUp.showToast(message: msg, duration: const Duration(seconds: 6));
      _safeNotify();
    } finally {
      _verifyOtpInFlight = false;
    }
  }

  Future<void> resendSignupOtp() async {
    try {
      await sl.firebasePhoneAuthService.resendOtp();
      AppPopUp.showToast(message: "OTP resent successfully");
      otpController.clear();
      notifyListeners();
    } catch (e) {
      AppPopUp.showToast(
        message: sl.firebasePhoneAuthService.userFacingMessage ??
            "Unable to resend OTP. Please try again.",
      );
    }
  }


//--------------------------set password
  ApiResponse<SetPasswordModel>? _setPasswordApiData = ApiResponse.completed(null);
  ApiResponse<SetPasswordModel>? get setPasswordApiData => _setPasswordApiData;
  void setPasswordRequestApiData(ApiResponse<SetPasswordModel> response) {
    _setPasswordApiData = response;
    notifyListeners();
  }

 Future<void> setPassword({required String token})async{
   setPasswordRequestApiData(ApiResponse.loading());
   notifyListeners();

   Map<String, String> data = {
     "token": token,
     "password": confirmPasswordController.text ,
   };
   try{
     await repository.setPassword(data).then((value) async{
       if(value.success == true){
         setPasswordRequestApiData(ApiResponse.completed(value));
         pt(name: "response","${value.message}");
         pt(name: "authToken _setPasswordApiData","${_setPasswordApiData?.data?.data?.authToken}");
         AppPopUp.showToast(message: value.message ?? "");
         await SecureStorage.saveToken(_setPasswordApiData?.data?.data?.user?.sId ?? "");
        final newRefreshToken = _setPasswordApiData?.data?.data?.refreshToken ?? "";
        if (newRefreshToken.isNotEmpty) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
          await sl.authService.saveRefreshToken(newRefreshToken);
        }
        await SecureStorage.saveToken(_setPasswordApiData?.data?.data?.authToken ?? "").then((value) {
           if(setPasswordApiData?.data?.data?.authToken?.isNotEmpty ?? false){
             Navigator.pushReplacementNamed(navigatorKey.currentContext!,
                 AppRoutes.accountCreatedSuccessfullyView);
           }
         },);
         // pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
       }else{
         setPasswordRequestApiData(ApiResponse.error(value.message));
         pt(name: "response error","${value.message}");
         AppPopUp.showToast(message: value.message ?? "");
       }
       notifyListeners();
     },);
   }catch(e,s){
     pt("Error request varification $e $s ");
     setPasswordRequestApiData(ApiResponse.error(e.toString()));
     notifyListeners();
   }
 }


  void validatePassword(String value) {
      hasMinLength = value.length >= 8;
      hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
      bool hasNumber = RegExp(r'[0-9]').hasMatch(value);
      bool hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
      hasNumberOrSymbol = hasNumber || hasSymbol;

      trueConditionsCount = [
        hasMinLength,
        hasLetter,
        hasNumberOrSymbol
      ].where((c) => c).length;
    notifyListeners();
  }

  String getPasswordStrength() {
    switch (trueConditionsCount) {
      case 0:
      case 1:
        return "Weak";
      case 2:
        return "Medium";
      case 3:
        return "Strong";
      default:
        return "";
    }
  }

  Color getStrengthColor() {
    switch (trueConditionsCount) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    sl.firebasePhoneAuthService.removeListener(_onPhoneAuthStateChanged);
    nameController.dispose();
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    pageController.dispose();
    super.dispose();
  }
}
