import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/controller/sign_in/model/login_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/data/storage/user_local_data.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/runtime/app_state_reconciliation_coordinator.dart';
import 'package:babyland/core/error/error_handler.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

class SignInController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  var passwordController = TextEditingController();
  var emailController = TextEditingController();

  bool _isChecked = true;
  bool get isChecked => _isChecked;
  setIsChecked(bool value) {
    pt(value.toString());
    _isChecked = value;
    notifyListeners();
  }

  bool _isShowPass = true;
  bool get isShowPass => _isShowPass;

  setIsShowPass(bool value) {
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

        // ✅ Save token securely (both legacy and new architecture)
        final token = value.authToken ?? "";
        final refreshToken = value.refreshToken ?? "";
        if (kDebugMode) {
          debugPrint('User logged in');
        }

        // ✅ Show success message
        AppPopUp.showToast(message: value.message ?? "Login successful");
        final userId = value.user?.id ?? "";

        // Save to legacy SecureStorage (for backward compatibility)
        await SecureStorage.saveToken(token);
        if (refreshToken.isNotEmpty) {
          await SecureStorage.saveRefreshToken(refreshToken);
        }
        await SecureStorage.saveUserId(userId);

        // Save to new AuthService (for new architecture)
        await sl.authService.saveToken(token);
        if (refreshToken.isNotEmpty) {
          await sl.authService.saveRefreshToken(refreshToken);
        }
        await sl.authService.saveUserId(userId);
        await UserLocalData.setNeedsPhoneProfile(true);

        final loginCtx = navigatorKey.currentContext;
        if (loginCtx != null && loginCtx.mounted) {
          unawaited(
            Provider.of<AppStateReconciliationCoordinator>(
              loginCtx,
              listen: false,
            ).reconcile(ReconcileTrigger.login),
          );
        }

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
      String message = "Something went wrong. Please try again.";

      if (e is DioException) {
        final appException = ErrorHandler.handle(e);
        message = appException.message;

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message =
              'Login timed out. Check your network connection and backend server, then try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          message =
              'Unable to reach the login server. Ensure your device is on the same Wi-Fi network as the backend.';
        }

        if (kDebugMode) {
          debugPrint("LOGIN ERROR TYPE: ${e.type}");
          debugPrint("LOGIN ERROR STATUS: ${e.response?.statusCode}");
          debugPrint("LOGIN ERROR BODY: ${e.response?.data}");
          debugPrint("LOGIN ERROR URI: ${e.requestOptions.uri}");
        }
      }

      AppPopUp.showToast(message: message);
    }
  }

  final List<String> icons = [
    // ImageConstants.facebook,
    ImageConstants.google,
    ImageConstants.apple,
    // ImageConstants.whatsApp,
  ];
}
