import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/main.dart';
import 'package:flutter/material.dart';

import '../../../widgets/app_popup.dart';
import '../../../widgets/print.dart';
import 'model/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier{

  SubscriptionProvider(){
    setSelectedPlanIndex(0);
  }

  int selectedPlanIndex = 0;
  String selectedPlanID = "";
  String _planName = "";
 String get planName=> _planName;
 setPLanName(String name){
   _planName = name;
   notifyListeners();
 }
 setSelectedPlanIndex(int index){
   selectedPlanIndex = index;
   notifyListeners();
 }
  ApiResponse<GetAllPlansModel>? _allSubscription = ApiResponse.completed(null);
  ApiResponse<GetAllPlansModel>? get allSubscription => _allSubscription;

  void setAllSubscription(ApiResponse<GetAllPlansModel> response) {
    _allSubscription = response;
    notifyListeners();
  }

  Future<void> getSubscriptionPlanApi() async {
    notifyListeners();
    setAllSubscription(ApiResponse.loading());
    notifyListeners();

    await repository.getSubscriptionPlan().then((value)async {
      if (value.success == true) {
        setAllSubscription(ApiResponse.completed(value));
      }
      if(value.success == false) {
        AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setAllSubscription(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }


  //add subscription
  ApiResponse<CommonResponseModel>? _addSubscription = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addSubscription => _addSubscription;

  void setAddSubscription(ApiResponse<CommonResponseModel> response) {
    _addSubscription = response;
    notifyListeners();
  }

  Future<void> addSubscriptionPlanApi({String? planId,String? paymentMethod}) async {
    notifyListeners();
    setAddSubscription(ApiResponse.loading());
    notifyListeners();
    Map<String,dynamic> data = {
      "planId": selectedPlanID != "" ? selectedPlanID  : (allSubscription?.data?.plans?.isNotEmpty ?? false) ? allSubscription?.data?.plans?.first.sId : selectedPlanID,
      "paymentMethod":paymentMethod ?? "COD"
    };

    await repository.addSubscriptionPlan(data).then((value)async {
      if (value.success == true) {
        setAddSubscription(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "");

      }
      if(value.success == false) {
        setAddSubscription(ApiResponse.completed(value));
        AppPopUp.showToast(message: value.message ?? "");
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setAddSubscription(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }

}