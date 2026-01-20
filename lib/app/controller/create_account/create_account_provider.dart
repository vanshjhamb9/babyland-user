import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/controller/create_account/model/request_verification_model.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/network/network_api_services.dart';
import '../../data/response/api_response.dart';
import 'model/set_password_model.dart';

class CreateAccountProvider extends ChangeNotifier {

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
     await repository.otpVerification(data).then((value) {
       if(value.success == true){
         _otpApiData = ApiResponse.completed(value);
         pt(name: "response","${value.message}");
         AppPopUp.showToast(message: value.message ?? "");
         SecureStorage.saveToken(value.token ?? "");
         pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
       }else{
         _otpApiData = ApiResponse.error(value.message);
         pt(name: "response error","${value.message}");
         AppPopUp.showToast(message: value.message ?? "");
       }
       notifyListeners();

     },);
   }catch(e,s){
     pt("Error request varification $e $s ");
     _otpApiData = ApiResponse.error(e.toString());
     notifyListeners();

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
}
