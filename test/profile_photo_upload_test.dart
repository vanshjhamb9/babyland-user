import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/common_profile_header/get_user_model.dart';
import 'package:babyland/app/data/response/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

GetUserProvider _providerWithUser({
  String? name,
  String? phone,
  String? email,
  String? stage,
}) {
  final provider = GetUserProvider();
  provider.setUserData(
    ApiResponse.completed(
      GetUserModel(
        success: true,
        user: User(
          user: Users(
            name: name,
            phone: phone,
            email: email,
            stage: stage,
            cycleType: 'regular',
            conditions: Conditions(
              pCOS: false,
              pMS: false,
              endometriosis: false,
              thyroidIssues: false,
              diabetes: true,
              hypertension: false,
            ),
          ),
        ),
      ),
    ),
  );
  return provider;
}

void main() {
  group('buildProfilePhotoMultipartPayload', () {
    test('includes name and phone from cached user', () {
      final provider = _providerWithUser(
        name: 'Vansh',
        phone: '+918769626027',
      );

      final payload = provider.buildProfilePhotoMultipartPayload();

      expect(payload['name'], 'Vansh');
      expect(payload['phone'], '+918769626027');
      expect(payload.containsKey('stage'), isFalse);
      expect(payload.containsKey('conditions'), isFalse);
    });

    test('defaults name to User when missing', () {
      final provider = _providerWithUser(phone: '+918769626027');

      final payload = provider.buildProfilePhotoMultipartPayload();

      expect(payload['name'], 'User');
      expect(payload['phone'], '+918769626027');
    });

    test('respects nameOverride', () {
      final provider = _providerWithUser(
        name: 'Cached Name',
        phone: '+918769626027',
      );

      final payload =
          provider.buildProfilePhotoMultipartPayload(nameOverride: 'Override');

      expect(payload['name'], 'Override');
    });

    test('omits phone when not cached', () {
      final provider = _providerWithUser(name: 'Vansh');

      final payload = provider.buildProfilePhotoMultipartPayload();

      expect(payload['name'], 'Vansh');
      expect(payload.containsKey('phone'), isFalse);
    });
  });

  group('buildProfileUpdatePayload', () {
    test('includes full profile fields for JSON updates', () {
      final provider = _providerWithUser(
        name: 'Vansh',
        phone: '+918769626027',
        email: 'test@example.com',
        stage: 'postpregnancy',
      );

      final payload = provider.buildProfileUpdatePayload();

      expect(payload['name'], 'Vansh');
      expect(payload['phone'], '+918769626027');
      expect(payload['email'], 'test@example.com');
      expect(payload['stage'], 'postpregnancy');
      expect(payload['cycleType'], 'regular');
      expect(payload['conditions'], isA<Map>());
    });
  });

  group('buildJsonProfilePayload', () {
    test('maps Thyroid Issues UI key to ThyroidIssues API key', () {
      final provider = _providerWithUser(name: 'Vansh', phone: '+918769626027');

      final payload = provider.buildJsonProfilePayload(
        name: 'Vansh',
        conditions: {
          'PCOS': false,
          'PMS': true,
          'Endometriosis': false,
          'Thyroid Issues': true,
          'Diabetes': false,
          'Hypertension': false,
        },
      );

      final conditions = payload['conditions'] as Map;
      expect(conditions['ThyroidIssues'], isTrue);
      expect(conditions.containsKey('Thyroid Issues'), isFalse);
    });
  });

  group('needsAdditionalJsonUpdateAfterPhoto', () {
    test('returns false when only name is present (photo-only upload)', () {
      expect(
        GetUserProvider.needsAdditionalJsonUpdateAfterPhoto(
          jsonPayload: {'name': 'Vansh'},
        ),
        isFalse,
      );
    });

    test('returns true when email or conditions are provided', () {
      expect(
        GetUserProvider.needsAdditionalJsonUpdateAfterPhoto(
          jsonPayload: {'name': 'Vansh', 'phone': '+918769626027'},
          email: 'test@example.com',
        ),
        isTrue,
      );
      expect(
        GetUserProvider.needsAdditionalJsonUpdateAfterPhoto(
          jsonPayload: {'name': 'Vansh'},
          conditions: {'PMS': true},
        ),
        isTrue,
      );
    });
  });

  group('minimal vs full payload separation', () {
    test('photo multipart payload excludes conditions and weight', () {
      final provider = _providerWithUser(
        name: 'Vansh',
        phone: '+918769626027',
        email: 'test@example.com',
      );

      final photoPayload = provider.buildProfilePhotoMultipartPayload();
      final jsonPayload = provider.buildJsonProfilePayload(
        name: 'Vansh',
        email: 'test@example.com',
        weight: '65',
        conditions: {'PMS': true},
      );

      expect(photoPayload.keys, containsAll(['name', 'phone']));
      expect(photoPayload.containsKey('conditions'), isFalse);
      expect(photoPayload.containsKey('weight'), isFalse);
      expect(photoPayload.containsKey('email'), isFalse);

      expect(jsonPayload.containsKey('conditions'), isTrue);
      expect(jsonPayload['weight'], '65');
      expect(jsonPayload['email'], 'test@example.com');
    });
  });
}
