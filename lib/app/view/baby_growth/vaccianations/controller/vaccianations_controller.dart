import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/view/baby_growth/vaccianations/model/vaccination_model.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';

class VaccianationController extends ChangeNotifier{

  int? selectedIndex;
  updateSelectedIndex(int index){
    selectedIndex = index;
    notifyListeners();
  }

  ApiResponse<VaccinationModel>? _vaccinationData = ApiResponse<VaccinationModel>.completed(null);
  ApiResponse<VaccinationModel>? get vaccinationData => _vaccinationData;

  void setVaccination(ApiResponse<VaccinationModel> response) {
    _vaccinationData = response;
    notifyListeners();
  }

  Future<void> getVaccinationApi() async {
    setVaccination(ApiResponse.loading());
    await repository.getAllVaccinations().then((value) {
      if (value.success == true) {
        setVaccination(ApiResponse.completed(value));
      } else {
        setVaccination(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
    }).onError((error, stackTrace) {
      setVaccination(ApiResponse.error(error.toString()));
    });
  }

  //update
  ApiResponse<CommonResponseModel>? _updateVaccinationData = ApiResponse<CommonResponseModel>.completed(null);
  ApiResponse<CommonResponseModel>? get updateVaccinationData => _updateVaccinationData;

  void setUpdateVaccination(ApiResponse<CommonResponseModel> response) {
    _updateVaccinationData = response;
    notifyListeners();
  }

  Future<void> updateVaccinationApi(String vacId) async {
    Map<String,dynamic> data = {
      "status": "completed"
    };
    setUpdateVaccination(ApiResponse.loading());
    await repository.updateVaccinations(data,vacId).then((value)async {
      if (value.success == true) {
        setUpdateVaccination(ApiResponse.completed(value));
        await getVaccinationApi();
      } else {
        setUpdateVaccination(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
    }).onError((error, stackTrace) {
      setUpdateVaccination(ApiResponse.error(error.toString()));
    });
  }
}