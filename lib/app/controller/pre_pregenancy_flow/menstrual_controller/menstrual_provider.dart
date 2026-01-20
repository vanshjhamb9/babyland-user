import 'package:babyland/app/controller/pre_pregenancy_flow/model/menstruals_cycle_model.dart';
import 'package:babyland/app/data/repository/menstrual_cycle_repository.dart';
import 'package:flutter/cupertino.dart';

import '../../../../main.dart';
import '../../../data/response/api_response.dart';
import '../../../widgets/app_popup.dart';
import '../../../widgets/print.dart';

class MenstrualProvider extends ChangeNotifier{
  final repository = MenstrualRepository(apiService: networkApi);

  ApiResponse<Menstruals_Cycle_model>? _menstrualApiData = ApiResponse.completed(null);
  ApiResponse<Menstruals_Cycle_model>? get menstrualApiData => _menstrualApiData;

  void setMenstrualApiData(ApiResponse<Menstruals_Cycle_model> response) {
    _menstrualApiData = response;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> menstrualCycleApi() async {
    setLoading(true);
    setMenstrualApiData(ApiResponse.loading());
    try {
      final value = await repository.getMenstrual();

      if (value.success == true) {

        setMenstrualApiData(ApiResponse.completed(value));
        pt("response data here ${value.data}");


      } else {
        setMenstrualApiData(ApiResponse.error(value.message ?? "otp failed"));
        AppPopUp.showToast(message: value.message.toString());
      }
    } catch (e, s) {
      pt("Error in login: $e\n$s");
      setMenstrualApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Something went wrong. Please try again.");
    }finally {
      setLoading(false);
    }
  }

}