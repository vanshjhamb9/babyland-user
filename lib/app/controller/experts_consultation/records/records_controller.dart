// import 'dart:io';
//
// import 'package:babyland/app/widgets/print.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
//
// class RecordsProvider extends ChangeNotifier{
//
//
//   final ImagePicker imagePicker = ImagePicker();
//   String _pickedPhoto = "";
//   String get pickedPhoto => _pickedPhoto;
//
//   void setPickedImage(String path){
//     _pickedPhoto = path;
//     notifyListeners();
//   }
//
//   void clearPickedImage(){
//     _pickedPhoto = "";
//     notifyListeners();
//   }
//
//   pickImage({required ImageSource imageSource})async{
//     final XFile? image = await imagePicker.pickImage(source: imageSource);
//
//     if(image != null){
//       File pickedImage = File(image.path);
//       setPickedImage(pickedImage.path);
//       pt("pickedPhoto $_pickedPhoto");
//     }
//   }
//
//
//   //upload from google drive
//
//   Future<void> pickFromGoogleDrive() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         allowMultiple: false,
//         type: FileType.custom,
//         allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
//         withData: true,
//       );
//
//       if (result != null) {
//         final filePath = result.files.first.path;
//         final fileName = result.files.first.name;
//
//         if (filePath != null) {
//           pt("Picked image path: $filePath");
//           setPickedImage(filePath);
//         } else {
//           pt("Picked image is in cloud and has no local path. File name: $fileName");
//         }
//       } else {
//         pt("No image selected");
//       }
//     } catch (e) {
//       pt("Error picking image: $e");
//     }
//   }
//
//
//
// }

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:babyland/app/widgets/print.dart';

import '../../../../main.dart';
import '../../../data/response/api_response.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_popup.dart';
import '../model/ConsultationDataModel.dart';

class RecordsProvider extends ChangeNotifier {
  final ImagePicker imagePicker = ImagePicker();

  // Sab files (image, pdf, doc, etc.)
  final List<PlatformFile> _files = [];
  List<PlatformFile> get files => List.unmodifiable(_files);

  void addFile(PlatformFile file) {
    _files.add(file);
    notifyListeners();
  }

  void addFiles(List<PlatformFile> files) {
    _files.addAll(files);
    notifyListeners();
  }

  void removeFileAt(int index) {
    _files.removeAt(index);
    notifyListeners();
  }

  void clearFiles() {
    _files.clear();
    notifyListeners();
  }

  // Gallery / Camera se image
  Future<void> pickImage({required ImageSource imageSource}) async {
    final XFile? image = await imagePicker.pickImage(source: imageSource);

    if (image != null) {
      final file = PlatformFile(
        name: image.name,
        path: image.path,
        size: await File(image.path).length(),
        bytes: null,
      );
      addFile(file);
      pt("picked image ${image.path}");
    } else {
      pt("No image selected");
    }
  }

  // Google Drive / File picker (image, pdf, doc sab allow karna ho to)
  Future<void> pickFromGoogleDrive() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'pdf',
          'doc',
          'docx'
        ],
        withData: true,
      );

      if (result != null) {
        addFiles(result.files);
        pt("Picked ${result.files.length} files");
      } else {
        pt("No file selected");
      }
    } catch (e) {
      pt("Error picking file: $e");
    }
  }



  ApiResponse<ConsultationDataModel>? _consultationApiData = ApiResponse.completed(null);
  ApiResponse<ConsultationDataModel>? get ConsultationApiData => _consultationApiData;

  void setConsultationApiData(ApiResponse<ConsultationDataModel> response) {
    _consultationApiData = response;
    notifyListeners();
  }

  Map<String, File> get filesAsMap {
    final Map<String, File> filesMap = {};
    for (int i = 0; i < _files.length; i++) {
      final file = _files[i];
      if (file.path != null) {
        filesMap["files[$i]"] = File(file.path!);  // Backend array format
      }
    }
    return filesMap;
  }

  String? doctorId;

  void setDoctorId(String? id) {
    doctorId = id;
    notifyListeners();
  }

  Future<void> consultationApi() async {
    pt("this is doctor id $doctorId");
    // Files check
    if (_files.isEmpty) {
      AppPopUp.showToast(message: "Please upload at least one file");
      return;
    }

    setConsultationApiData(ApiResponse.loading());

    final data = {
      "id": doctorId.toString(),  // ya patientId/consultationId whatever hai
    };

    try {
      final value =  await repository.consultationRepo(
        data,
        filesAsMap,
      );

      if ((value).success == true) {
        setConsultationApiData(ApiResponse.completed(value));
        pt("Upload success");

        // Success navigation
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamed(
            navigatorKey.currentContext!,
            AppRoutes.reportView,
          );
        }
        clearFiles();  // Files clear after success
      } else {
        setConsultationApiData(ApiResponse.error("Upload failed"));
      }
    } catch (e, s) {
      pt("Consultation API error: $e\n$s");
      setConsultationApiData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Upload failed. Please try again.");
    }
  }
}
