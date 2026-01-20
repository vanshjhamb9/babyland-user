import 'package:babyland/app/data/response/api_response.dart';
import 'package:flutter/cupertino.dart';

import '../../../main.dart';
import '../../widgets/print.dart';
import 'model/policy_model.dart';

class PoliciesProvider extends ChangeNotifier{
  ApiResponse<PolicyModel>? _policyData = ApiResponse.completed(null);
  ApiResponse<PolicyModel>? get policyData => _policyData;

  void setUserData(ApiResponse<PolicyModel> response) {
    _policyData = response;
    notifyListeners();
  }

  Future<void> privacyPolicyApi(String policy) async {
    setUserData(ApiResponse.loading());
    notifyListeners();


    await repository.privacyPolicy(policy).then((value) {
      if (value.success == true) {
        setUserData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
        // AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        // Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
      }
      if(value.success == false) {
        setUserData(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in privacy: $error\n$stackTrace");
      setUserData(ApiResponse.error(error.toString()));
      notifyListeners();
      // AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }

}