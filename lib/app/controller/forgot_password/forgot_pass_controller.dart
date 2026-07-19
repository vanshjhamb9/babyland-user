import 'dart:async';
import 'package:babyland/app/controller/forgot_password/model/forgot_password_model.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../common_model/common_model.dart';
import '../../data/repository/repository.dart';
import '../../data/response/api_response.dart';
import '../../data/storage/secure_storage.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_popup.dart';
import '../../widgets/print.dart';
import '../create_account/model/set_password_model.dart';
import 'package:babyland/core/di/service_locator.dart';

class ForgotPassController extends ChangeNotifier{
  final formKey = GlobalKey<FormState>();
  var emailController  = TextEditingController();
  final repository = Repository(apiService: networkApi);
  final otpController = TextEditingController();


  ApiResponse<forgot_password_model>? _forgotApiData = ApiResponse.completed(null);
  ApiResponse<forgot_password_model>? get forgotApiData => _forgotApiData;


  void setForgotApiData(ApiResponse<forgot_password_model> response) {
    _forgotApiData = response;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }


  Future<void> forgotPassApi() async {
    setLoading(true);
    setForgotApiData(ApiResponse.loading());

    final data = {
      "email": emailController.text.trim(),
    };

    try {
      final value = await repository.forgot(data);

      if (value.success == true) {
        startResendCountdown();
        setForgotApiData(ApiResponse.completed(value));
        pt("response data here ${value.data?.code}");

        final otpHint = value.data?.code != null
            ? ' Code: ${value.data!.code}'
            : '';
        AppPopUp.showToast(
          message: '${value.message ?? 'OTP sent'}$otpHint',
          duration: const Duration(seconds: 6),
        );

        if (navigatorKey.currentContext != null) {
          Navigator.pushNamed(navigatorKey.currentContext!
              , AppRoutes.forgotPasswordOtpVerifyView,
          );
        }

      } else {
        setForgotApiData(ApiResponse.error(value.message ?? "otp failed"));
        AppPopUp.showToast(message: value.message ?? "otp failed");
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setForgotApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoading(false);
    }
  }

  String? _receivedOtp;
  String? get receivedOtp => _receivedOtp;

  int _resendSeconds = 59;
  int get resendSeconds => _resendSeconds;

  bool _isResendAvailable = false;
  bool get isResendAvailable => _isResendAvailable;

  Timer? _resendTimer;

  bool verifyOtp(String inputOtp) {
    return _receivedOtp != null && inputOtp == _receivedOtp;
  }

  //--------------------------otp verification
  ApiResponse<CommonResponseModel>? _otpApiData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get otpApiData => _otpApiData;
  void setOtpRequestApiData(ApiResponse<CommonResponseModel> response) {
    _otpApiData = response;
    notifyListeners();
  }

  Future<void> otpVerification() async {
    final code = otpController.text.trim();
    if (code.length < 4) {
      AppPopUp.showToast(message: 'Please enter the complete OTP code.');
      return;
    }

    setOtpRequestApiData(ApiResponse.loading());
    notifyListeners();

    Map<String, String> data = {
      "email": emailController.text.trim(),
      "code": code,
    };
    try{
      await repository.otpVerification(data).then((value) {
        if(value.success == true){
          _otpApiData = ApiResponse.completed(value);
          pt(name: "response","${value.message}");
          AppPopUp.showToast(message: value.message ?? "");
          emailController.text = "";
          otpController.text = "";
          // Navigator.pushNamedAndRemoveUntil(navigatorKey.currentContext!, AppRoutes.signInView, (route) => false);
          Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.createNewPasswordView);
        }else{
          setOtpRequestApiData(
            ApiResponse.error(value.message ?? 'Invalid or expired code'),
          );
          pt(name: "response error","${value.message}");
          AppPopUp.showToast(
            message: value.message ?? 'Invalid or expired code',
          );
        }
        notifyListeners();

      },);
    } catch (e, s) {
      pt("Error request varification $e $s ");
      setOtpRequestApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(
        message: 'Verification failed. Check the code and try again.',
      );
      notifyListeners();
    }
  }


  // Resend OTP and reset resend timer
  Future<void> resendOtp(String email) async {
    if (_isResendAvailable == false) return;

    setLoading(true);
    try {
      final data = {
        "email": email.toString(),
      };
         pt("body data here $data");
      final value = await repository.forgot(data); // Call resend API same as forgotPassApi

      if (value.success == true) {
        setForgotApiData(ApiResponse.completed(value));
        pt("response data here ${value.data?.code}");
        AppPopUp.showToast(message: "OTP resent successfully : ${value.data?.code}",duration: Duration(seconds: 10));
        startResendCountdown();
      } else {
        AppPopUp.showToast(message: value.message ?? "OTP resend failed");
      }
    } catch (e, s) {
      pt("Error in resend OTP: $e\n$s");
      AppPopUp.showToast(message: "Something went wrong while resending OTP.");
    } finally {
      setLoading(false);
    }
  }

//--------------------------set password
  ApiResponse<SetPasswordModel>? _setPasswordApiData = ApiResponse.completed(null);
  ApiResponse<SetPasswordModel>? get setPasswordApiData => _setPasswordApiData;
  void setPasswordRequestApiData(ApiResponse<SetPasswordModel> response) {
    _setPasswordApiData = response;
    notifyListeners();
  }

  Future<void> setPassword({required String password})async{
    setPasswordRequestApiData(ApiResponse.loading());
    notifyListeners();

    Map<String, String> data = {
      "token": otpApiData?.data?.token ?? "",
      "password": password.trim(),
    };

    pt("dataaaa >>> $data");

    try{
      await repository.setPassword(data).then((value) async{
        if(value.success == true){
          setPasswordRequestApiData(ApiResponse.completed(value));
          pt(name: "response","${value.message}");
          pt(name: "authToken _setPasswordApiData","${_setPasswordApiData?.data?.data?.authToken}");
          AppPopUp.showToast(message: value.message ?? "");
          await SecureStorage.saveToken(_setPasswordApiData?.data?.data?.authToken ?? "").then((value) {
            if(setPasswordApiData?.data?.data?.authToken?.isNotEmpty ?? false){
              Navigator.pushNamedAndRemoveUntil(navigatorKey.currentContext!,AppRoutes.signInView,(route) => false);
            }
          },);

          final newRefreshToken = _setPasswordApiData?.data?.data?.refreshToken ?? '';
          if (newRefreshToken.isNotEmpty) {
            await SecureStorage.saveRefreshToken(newRefreshToken);
            await sl.authService.saveRefreshToken(newRefreshToken);
          }
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


  // Start or reset resend OTP countdown timer
  void startResendCountdown() {
    _resendSeconds = 59;
    _isResendAvailable = false;
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        _resendSeconds--;
      } else {
        _isResendAvailable = true;
        _resendTimer?.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  bool validateEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

}