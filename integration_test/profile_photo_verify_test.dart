import 'dart:io';

import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/app/data/storage/secure_storage.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs on a physical device/emulator with an existing logged-in session.
///
/// Log in on device first, then run:
/// `flutter test integration_test/profile_photo_verify_test.dart -d DEVICE`
///
/// Or pass a token explicitly:
/// `flutter test integration_test/profile_photo_verify_test.dart -d DEVICE --dart-define=E2E_AUTH_TOKEN=your_jwt`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('Profile photo device verification (photo-only, JSON-only, split flow)',
      () async {
    await AppEnvironment.init();
    const envToken = String.fromEnvironment('E2E_AUTH_TOKEN');
    if (envToken.isNotEmpty) {
      await SecureStorage.saveToken(envToken);
    }

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      markTestSkipped(
        'No auth token — log in on device or pass --dart-define=E2E_AUTH_TOKEN',
      );
      return;
    }

    final repo = Repository(apiService: NetworkApiServices());
    final testImage = await _writeAssetToTempFile(
      'assets/images/IRA.jpeg',
      'profile_verify_test.jpg',
    );

    // 1. Photo-only upload (minimal payload)
    final userBefore = await repo.getUser();
    expect(userBefore.success, isTrue, reason: userBefore.message);

    final name = userBefore.user?.user?.name ?? 'User';
    final phone = userBefore.user?.user?.phone;
    expect(phone, isNotNull);
    expect(phone!.isNotEmpty, isTrue);

    final photoPayload = {'name': name, 'phone': phone};
    expect(photoPayload.containsKey('conditions'), isFalse);

    final photoResult = await repo.updateUserProfile(
      photoPayload,
      profileImage: testImage,
    );
    print(
      'photo-only upload: success=${photoResult.success} '
      'message=${photoResult.message}',
    );
    expect(photoResult.success, isTrue, reason: photoResult.message);

    final userAfterPhoto = await repo.getUser();
    final photoUrl = userAfterPhoto.user?.user?.profilePicture;
    print('photo after upload: $photoUrl');
    expect(photoUrl, isNotNull);
    expect(photoUrl!.trim().isNotEmpty, isTrue);

    // 2. JSON-only update (regression — no image)
    final jsonOnlyResult = await repo.updateUserProfile({
      'name': name,
      'phone': phone,
      'weight': userBefore.user?.user?.weight?.toString() ?? '60',
    });
    print(
      'JSON-only update: success=${jsonOnlyResult.success} '
      'message=${jsonOnlyResult.message}',
    );
    expect(jsonOnlyResult.success, isTrue, reason: jsonOnlyResult.message);

    // 3. Split flow — photo then conditions JSON (no duplicate photo upload)
    final splitPhotoResult = await repo.updateUserProfile(
      {'name': name, 'phone': phone},
      profileImage: testImage,
    );
    expect(splitPhotoResult.success, isTrue, reason: splitPhotoResult.message);

    final splitJsonResult = await repo.updateUserProfile({
      'name': name,
      'phone': phone,
      'conditions': {
        'PCOS': false,
        'PMS': true,
        'Endometriosis': false,
        'ThyroidIssues': false,
        'Diabetes': false,
        'Hypertension': true,
      },
    });
    print(
      'split flow JSON step: success=${splitJsonResult.success} '
      'message=${splitJsonResult.message}',
    );
    expect(splitJsonResult.success, isTrue, reason: splitJsonResult.message);

    final userFinal = await repo.getUser();
    expect(userFinal.user?.user?.conditions?.pMS, isTrue);
    expect(userFinal.user?.user?.profilePicture, isNotNull);
  });
}

Future<File> _writeAssetToTempFile(String assetPath, String fileName) async {
  final bytes = await rootBundle.load(assetPath);
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return file;
}
