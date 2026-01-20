import 'dart:io';

import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/view/baby_growth/photo/photo_model/get_baby_photos_model.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class PhotoProvider extends ChangeNotifier{


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
      Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.addNewPhotoView);
      pt("pickedPhoto $_pickedPhoto");
    }

  }


//---------------------------------------------------add photos

  ApiResponse<CommonResponseModel>? _addBabyPhotos = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get addBabyPhotos => _addBabyPhotos;

  void setBabyPhotos(ApiResponse<CommonResponseModel> response) {
    _addBabyPhotos = response;
    notifyListeners();
  }

  Future<void> addBabyPhotosApi({
    required Map<String, dynamic> fields,
    required Map<String, File> files,
  }) async {
    setBabyPhotos(ApiResponse.loading());
    notifyListeners();
    // 🔎 PRINT FIELDS
    pt("===== Sending Fields =====");
    fields.forEach((key, value) {
      pt("$key : $value");
    });

    // 🔎 PRINT FILES
    pt("===== Sending Files =====");
    files.forEach((key, file) {
      pt("$key : ${file.path}");
    });
    await repository.addBabyGrowthPhotos(fields, files).then((value)async {
      if (value.success == true) {
        setBabyPhotos(ApiResponse.completed(value));
        await getBabyPhotosApis();
        Navigator.pop(navigatorKey.currentContext!);
        pt(name: "MildStone Response", "${value.message}");
        AppPopUp.showToast(message: value.message ?? "Photo added successfully...");

      } else {
        setBabyPhotos(ApiResponse.error(value.message ?? "Something went wrong!"));
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      pt("Error in addMildStoneDetails: $error\n$stackTrace");
      setBabyPhotos(ApiResponse.error(error.toString()));
      notifyListeners();
    });
  }

//--------------------------------get baby photo
  ApiResponse<GetBabyPhotosModel>? _babyPhotoDataGet = ApiResponse<GetBabyPhotosModel>.completed(null);
  ApiResponse<GetBabyPhotosModel>? get babyPhotoDataGet => _babyPhotoDataGet;

  void setMildStoneApi(ApiResponse<GetBabyPhotosModel> response) {
    _babyPhotoDataGet = response;
    notifyListeners();
  }

  Future<void> getBabyPhotosApis() async {
    setMildStoneApi(ApiResponse.loading());

    await repository.getBabyGrowthPhotos().then((value) {
      if (value.success == true) {
        setMildStoneApi(ApiResponse.completed(value));
      } else {
        setMildStoneApi(ApiResponse.error("Something went wrong!"));
      }
    }).onError((error, stackTrace) {
      setMildStoneApi(ApiResponse.error(error.toString()));
    });
  }

}