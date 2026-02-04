import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/print.dart';

class UserLocalData {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';
  static const _roleKey = 'role';
  static const _stepKey = 'step';
  static const _doctorKey = 'doctor';

  static const _lastStageScreenShownKey = 'last_stage_screen_shown';

  // ---------------- ROLE ----------------
  static Future<void> saveRole(String role) async {
    if (role.isNotEmpty) {
      pt('Role saved securely: $role');
    }
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<void> clearRole() async {
    await _storage.delete(key: _roleKey);
  }

  // ---------------- STEP ----------------
  static Future<void> saveStep(String step) async {
    if (step.isNotEmpty) {
      pt('Step saved securely: $step');
    }
    await _storage.write(key: _stepKey, value: step);
  }

  static Future<String?> getStep() async {
    return await _storage.read(key: _stepKey);
  }

  static Future<void> clearStep() async {
    await _storage.delete(key: _stepKey);
  }

  static Future<void> saveDoctorId(String id) async {
      pt('Role saved securely: $id');
      await _storage.write(key: _doctorKey, value: id);
  }
  static Future<String?> getDoctorId() async {
    return await _storage.read(key: _doctorKey);
  }

  static Future<void> clearDoctorId() async {
    await _storage.delete(key: _doctorKey);
  }
  // ---------------- clear all data ----------------

  static Future<void> clearAllLocalData() async {
    await _storage.delete(key: _stepKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _doctorKey);
    await _storage.delete(key: _lastStageScreenShownKey); // Add this line
  }

  static Future<void> saveLastStageScreenShown() async {
    final currentDate = DateTime.now().toIso8601String();
    await _storage.write(key: _lastStageScreenShownKey, value: currentDate);
    pt('Last stage screen shown saved: $currentDate');
  }

  /// Check if 30 days have passed since last shown
  static Future<bool> shouldShowStageScreen() async {
    final lastShownDate = await _storage.read(key: _lastStageScreenShownKey);

    if (lastShownDate == null) {
      // Never shown before, should show
      return true;
    }

    final lastDate = DateTime.parse(lastShownDate);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(lastDate).inDays;

    pt('Days since last stage screen shown: $difference');

    // Show if 30 or more days have passed
    return difference >= 30;
  }

  /// Clear the last shown date (for testing or reset)
  static Future<void> clearLastStageScreenShown() async {
    await _storage.delete(key: _lastStageScreenShownKey);
  }

// Update your existing clearAllLocalData method to include the new key

  // ---------------- SETUP COMPLETE ----------------
  static const _postPregnancySetupCompleteKey = 'post_pregnancy_setup_complete';

  static Future<void> savePostPregnancySetupComplete() async {
    await _storage.write(key: _postPregnancySetupCompleteKey, value: 'true');
    pt('Post pregnancy setup complete saved');
  }

  static Future<bool> isPostPregnancySetupComplete() async {
    final value = await _storage.read(key: _postPregnancySetupCompleteKey);
    return value == 'true';
  }

  static Future<void> clearPostPregnancySetupComplete() async {
    await _storage.delete(key: _postPregnancySetupCompleteKey);
  }
}
