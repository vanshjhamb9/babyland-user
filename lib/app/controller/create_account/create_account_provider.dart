import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/controller/create_account/model/request_verification_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/core/auth/jwt_utils.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/network/network_api_services.dart';
import '../../data/response/api_response.dart';
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

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  static const int _otpPageIndex = 1;

  /// Moves the embedded signup [PageView] to the OTP step and syncs [currentIndex].
  Future<void> _goToPhoneOtpStep() async {
    if (!pageController.hasClients) {
      await Future<void>.delayed(Duration.zero);
    }
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

  void _onPhoneAuthStateChanged() {
    notifyListeners();
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


//-------------------------- NEW AUTH FLOW: signup
  ApiResponse<CommonResponseModel>? _signupApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get signupApiData => _signupApiData;
  Future<void> signup() async {
    _signupApiData = ApiResponse.loading();
    notifyListeners();
    Map<String, String> data = {
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text.trim(),
    };
    pt(name: "Signup Payload:", "$data");
    print("Signup Payload: $data");
    try {
      // Backend requires Firebase idToken on /verify-otp — SMS must come from Firebase.
      await sl.firebasePhoneAuthService.sendOtp(phoneController.text.trim());

      if (!sl.firebasePhoneAuthService.hasPendingPhoneVerification) {
        final msg = sl.firebasePhoneAuthService.userFacingMessage ??
            'Could not start phone verification. Check Firebase setup.';
        _signupApiData = ApiResponse.error(msg);
        AppPopUp.showToast(message: msg, duration: const Duration(seconds: 8));
        notifyListeners();
        return;
      }

      _signupApiData = ApiResponse.completed(
        CommonResponseModel(success: true, message: 'OTP sent'),
      );
      await _goToPhoneOtpStep();
      AppPopUp.showToast(message: 'OTP sent. Please verify.');
      notifyListeners();
    } catch (e, s) {
      pt("Error signup $e $s ");
      final msg = sl.firebasePhoneAuthService.userFacingMessage ??
          e.toString();
      _signupApiData = ApiResponse.error(msg);
      AppPopUp.showToast(message: msg, duration: const Duration(seconds: 6));
      notifyListeners();
    }
  }

  //-------------------------- NEW AUTH FLOW: verify otp
  ApiResponse<CommonResponseModel>? _verifyOtpSignupData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get verifyOtpSignupData => _verifyOtpSignupData;
  Future<void> verifyOtpSignup() async {
    _verifyOtpSignupData = ApiResponse.loading();
    notifyListeners();
    
    try {
      // 1. Verify SMS code with Firebase first
      final userCredential = await sl.firebasePhoneAuthService.verifySmsCode(otpController.text.trim());
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception("Failed to retrieve Firebase ID token");
      }

      // 1.5 Create User in Backend NOW (since SMS was valid!)
      Map<String, String> signupData = {
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "password": passwordController.text.trim(),
      };
      final signupResult = await repo.signup(signupData);
      if (signupResult.success != true) {
        throw Exception(signupResult.message ?? "Failed to create user on backend");
      }

      // 2. Send idToken and phone to backend
      Map<String, String> data = {
        "phone": phoneController.text.trim(),
        "idToken": idToken,
      };
      
      pt(name: "Verify OTP (Firebase ID Token) Payload:", "$data");
      
      final value = await repo.verifyOtpSignup(data);
      pt(name: "Auth Response:", "$value");
      print("Auth Response: ${value.toJson()}");
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

        await UserLocalData.setNeedsBasicProfile(true);
        Navigator.pushReplacementNamed(
          navigatorKey.currentContext!,
          AppRoutes.basicProfileView,
        );
      } else {
        _verifyOtpSignupData = ApiResponse.error(value.message);
        AppPopUp.showToast(message: value.message ?? "OTP failed");
      }
      notifyListeners();
    } catch (e, s) {
      pt("Error verify otp $e $s ");
      final msg = sl.firebasePhoneAuthService.userFacingMessage ??
          e.toString();
      _verifyOtpSignupData = ApiResponse.error(msg);
      AppPopUp.showToast(message: msg, duration: const Duration(seconds: 6));
      notifyListeners();
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
