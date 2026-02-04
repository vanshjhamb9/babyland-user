import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/sign_in/model/login_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';

class SignInController extends ChangeNotifier{

  final formKey = GlobalKey<FormState>();
  var passwordController  = TextEditingController();
  var emailController  = TextEditingController();

  bool _isChecked = true;
  bool get isChecked => _isChecked;
  setIsChecked(bool value){
    pt(value.toString());
    _isChecked = value;
    notifyListeners();
  }

  bool _isShowPass = true;
  bool get isShowPass => _isShowPass;

  setIsShowPass(bool value){
    _isShowPass = value;
    notifyListeners();
  }


//--------------------------set password
  ApiResponse<LoginModel>? _loginApiData = ApiResponse.completed(null);
  ApiResponse<LoginModel>? get loginApiData => _loginApiData;

  void setLoginApiData(ApiResponse<LoginModel> response) {
    _loginApiData = response;
    notifyListeners();
  }

  Future<void> login() async {
    setLoginApiData(ApiResponse.loading());

    final data = {
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final value = await repository.login(data);

      if (value.success == true) {
        // ✅ Save API response
        setLoginApiData(ApiResponse.completed(value));

        pt(name: "response", "${value.message}");
        pt(name: "authToken", "${value.authToken}");

        // ✅ Show success message
        AppPopUp.showToast(message: value.message ?? "Login successful");

        // ✅ Save token securely
        await SecureStorage.saveToken(value.authToken ?? "");
        await SecureStorage.saveUserId(value.user?.id ?? "");

        // ✅ Navigate safely after storage
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            AppRoutes.stagesView,
                (route) => false,
            arguments: {"fromLoginScreen": true},
          );
        }

      } else {
        // ❌ API returned failure
        setLoginApiData(ApiResponse.error(value.message ?? "Login failed"));
        AppPopUp.showToast(message: value.message ?? "Login failed");
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setLoginApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }
  }



  final List<String> icons = [
    // ImageConstants.facebook,
    ImageConstants.google,
    ImageConstants.apple,
    // ImageConstants.whatsApp,
  ];


}