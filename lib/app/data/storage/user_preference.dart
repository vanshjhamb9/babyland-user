import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/print.dart';

class UserPreference {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';
  static const _roleKey = 'role';
  static const _stepKey = 'step';
  static const _doctorKey = 'doctor';

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
  }
}
