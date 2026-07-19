import 'package:babyland/app/common_model/common_model.dart';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';

class BasicProfileProvider extends ChangeNotifier {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  ApiResponse<CommonResponseModel>? _updateProfileData = ApiResponse.completed(null);
  ApiResponse<CommonResponseModel>? get updateProfileData => _updateProfileData;

  void setUpdateProfileData(ApiResponse<CommonResponseModel> response) {
    _updateProfileData = response;
    notifyListeners();
  }

  Future<void> submitProfile(BuildContext context) async {
    final name = nameController.text.trim();
    final age = ageController.text.trim();
    final height = heightController.text.trim();
    final weight = weightController.text.trim();

    if (name.isEmpty || age.isEmpty || height.isEmpty || weight.isEmpty) {
      AppPopUp.showToast(message: "All fields marked with * are mandatory");
      return;
    }

    setUpdateProfileData(ApiResponse.loading());
    notifyListeners();

    try {
      final userProvider = context.read<GetUserProvider>();
      
      // Using existing updateUserProfile from GetUserProvider or direct repository call
      // Based on profile_update_screen.dart, it uses provider.updateUserProfile
      await userProvider.updateUserProfile(
        name: name,
        age: age,
        height: height,
        weight: weight,
      );

      setUpdateProfileData(ApiResponse.completed(CommonResponseModel(success: true, message: "Profile updated")));
      
      Navigator.pushReplacementNamed(context, AppRoutes.basicInfoView);
    } catch (e, s) {
      pt("Error in submitProfile: $e\n$s");
      setUpdateProfileData(ApiResponse.error(e.toString()));
      AppPopUp.showToast(message: "Failed to update profile. Please try again.");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }
}
