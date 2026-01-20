import 'dart:io';
import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/app/view/baby_growth/model/baby_growth_add_data_model.dart';
import 'package:babyland/app/view/baby_growth/model/baby_growth_details_model.dart';
import 'package:babyland/app/view/baby_growth/model/get_mildstone_model.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_routes.dart';
import '../../view/baby_growth/milestones/add_mild_stones.dart';
import 'model/add_baby_growth_data_model.dart';

class BabyGrowthProvider extends ChangeNotifier{

  final dateController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final cmController = TextEditingController();
  final formKey = GlobalKey<FormState>();


  ApiResponse<BabyGrowthAddData>? _addBabyGrowthData = ApiResponse.completed(null);
  ApiResponse<BabyGrowthAddData>? get addBabyGrowthData => _addBabyGrowthData;

  void setBabyGrowthData(ApiResponse<BabyGrowthAddData> response) {
    _addBabyGrowthData = response;
    notifyListeners();
  }

  Future<void> addBabyDataInitial() async {
    setBabyGrowthData(ApiResponse.loading());
    notifyListeners();
    Map<String, dynamic> data = {
      "babyName": "string",
      "dob": "2025-11-14"
    };

    await repository.babygrowthsAdd(data).then((value) {
      if (value.success == true) {
        setBabyGrowthData(ApiResponse.completed(value));
        pt(name: "response", "${value.message}");
        SecureStorage.saveTrackerId(value.tracker?.sId.toString() ?? "");
        // AppPopUp.showToast(message: value.message ?? "Something went wrong!");
        // Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.postPregnancyNavbarView);
      }
      if(value.success == false) {
        setBabyGrowthData(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setBabyGrowthData(ApiResponse.error(error.toString()));
      notifyListeners();
      // AppPopUp.showToast(message: "Something went wrong. Please try again.");
      notifyListeners();
    },);
  }
  // //--
  ApiResponse<CommonResponseModel>? _addBabyGrowthDataForPage = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addBabyGrowthDataForPage => _addBabyGrowthDataForPage;

  // void setBabyGrowthDataPage(ApiResponse<CommonResponseModel> response) {
  //   _addBabyGrowthDataForPage = response;
  //   notifyListeners();
  // }
  //
  // Future<void> babygrowthsAddPage({required String dob}) async {
  //   setBabyGrowthDataPage(ApiResponse.loading());
  //   notifyListeners();
  //   Map<String, dynamic> params ={
  //     "babyName": "abc",
  //     "dob": formatDateForApi(dob),
  //   };
  //   await repository.babygrowthsAddPage(params).then((value) {
  //     if (value.success == true) {
  //       setBabyGrowthDataPage(ApiResponse.completed(value));
  //       pt(name: "response", "${value.message}");
  //       Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.babyGrowthSummaryView);
  //     }
  //     if(value.success == false) {
  //       Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.babyGrowthSummaryView);
  //       setBabyGrowthDataPage(ApiResponse.error(value.message ?? "Something went wrong!"));
  //
  //     }
  //     notifyListeners();
  //   },).onError((error, stackTrace) {
  //     pt("Error in pregnancyInfo: $error\n$stackTrace");
  //     Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.babyGrowthSummaryView);
  //
  //     setBabyGrowthDataPage(ApiResponse.error(error.toString()));
  //     notifyListeners();
  //     // AppPopUp.showToast(message: "Something went wrong. Please try again.");
  //   },);
  // }

 // //--
  ApiResponse<BabyGrowthApiData>? _babyGrowthApiData = ApiResponse.completed(null);
  ApiResponse<BabyGrowthApiData>? get babyGrowthApiData => _babyGrowthApiData;

  void setBabyGrowthApiData(ApiResponse<BabyGrowthApiData> response) {
    _babyGrowthApiData = response;
    notifyListeners();
  }

  Future<void> babyGrowthsDetails() async {
    setBabyGrowthApiData(ApiResponse.loading());
    notifyListeners();
    await repository.babygrowthsDetails().then((value) {
      if (value.success == true) {
        setBabyGrowthApiData(ApiResponse.completed(value));
        pt(name: "response", "${value.success}");
      }
      if(value.success == false) {
        // setBabyGrowthApiData(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    },).onError((error, stackTrace) {
      pt("Error in pregnancyInfo: $error\n$stackTrace");
      setBabyGrowthApiData(ApiResponse.error(error.toString()));
      notifyListeners();
      // AppPopUp.showToast(message: "Something went wrong. Please try again.");
    },);
  }



  ApiResponse<CommonResponseModel>? _addMildStoneApi = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addMildStoneApi => _addMildStoneApi;

  void setAddMildStoneApi(ApiResponse<CommonResponseModel> response) {
    _addMildStoneApi = response;
    notifyListeners();
  }

  Future<void> addMildStoneDetails({
    required Map<String, dynamic> fields,
    required Map<String, File> files,
  }) async {
    setAddMildStoneApi(ApiResponse.loading());
    notifyListeners();

    await repository.addMildStone(fields, files).then((value) async {
      if (value.success == true) {
        setAddMildStoneApi(ApiResponse.completed(value));
        pt(name: "MildStone Response", "${value.message}");
        AppPopUp.showToast(message: value.message ?? "Milestone added successfully..");
        await geMildStoneDetails();

        if (navigatorKey.currentContext != null) {
          Navigator.pop(navigatorKey.currentContext!,true);
        }
      } else {
        setAddMildStoneApi(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in addMildStoneDetails: $error\n$stackTrace");
      setAddMildStoneApi(ApiResponse.error(error.toString()));
      notifyListeners();
    });
  }



  ApiResponse<MilestonesModel>? _milestonesData = ApiResponse<MilestonesModel>.completed(null);
  ApiResponse<MilestonesModel>? get milestonesData => _milestonesData;

  void setMildStoneApi(ApiResponse<MilestonesModel> response) {
    _milestonesData = response;
    notifyListeners();
  }

  Future<void> geMildStoneDetails() async {
    setMildStoneApi(ApiResponse<MilestonesModel>.loading());

    await repository.getMildStone().then((value) {
      if (value.success == true) {
        setMildStoneApi(ApiResponse<MilestonesModel>.completed(value));
      } else {
        setMildStoneApi(ApiResponse<MilestonesModel>.error(value.message ?? "Something went wrong!"));
      }
    }).onError((error, stackTrace) {
      setMildStoneApi(ApiResponse<MilestonesModel>.error(error.toString()));
    });
  }



  final ImagePicker imagePicker = ImagePicker();
  String _pickedPhoto = "";
  String get pickedPhoto => _pickedPhoto;

  void setPickedImage(String path){
    _pickedPhoto = path;
    notifyListeners();
  }

  void clearPickedImage(){
    _pickedPhoto = "";
    notifyListeners();
  }

  pickImage({required ImageSource imageSource})async{
  final XFile? image = await imagePicker.pickImage(source: imageSource);

    if(image != null){
      File pickedImage = File(image.path);
      setPickedImage(pickedImage.path);
      pt("pickedPhoto $_pickedPhoto");
    }

  }


  /// baby growth add api ///

  ApiResponse<Add_Baby_Growth_Data_Model>? _addNewBabyGrowthData = ApiResponse.completed(null);
  ApiResponse<Add_Baby_Growth_Data_Model>? get addNewBabyGrowthData => _addNewBabyGrowthData;

  void setNewBabyGrowthData(ApiResponse<Add_Baby_Growth_Data_Model> response) {
    _addNewBabyGrowthData = response;
    notifyListeners();
  }

  Future<void> addBabyGrowthApi() async {
    setNewBabyGrowthData(ApiResponse.loading());
    notifyListeners();
    Map<String, dynamic> params ={
      "date": formatDateForApi(dateController.text.toString()),
      "height": heightController.text.toString(),
      "weight": weightController.text.toString(),
      "headCircumference": cmController.text.toString()

    };
    pt("this is baby growth params $params");
    await repository.addBabyGrowthRepo(params).then((value) {
      if (value.success == true) {
        setNewBabyGrowthData(ApiResponse.completed(value));
        pt(name: "response", "${value.baby}");
        Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.babyGrowthSummaryView);
        dateController.clear();
        heightController.clear();
        weightController.clear();
        cmController.clear();
      }else{
        AppPopUp.showToast(message: value.baby?.message ??  "Please try again.");
      }
      notifyListeners();
    }
    ,).onError((error, stackTrace) {
      pt("Error in baby growth here : $error\n$stackTrace");
      // Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.babyGrowthSummaryView);

      setNewBabyGrowthData(ApiResponse.error(error.toString()));
      notifyListeners();
      AppPopUp.showToast(message:  "Something went wrong. Please try again.");
    },);
  }



}