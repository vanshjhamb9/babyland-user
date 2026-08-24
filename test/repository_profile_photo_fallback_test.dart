import 'dart:io';

import 'package:babyland/app/data/network/network_api_services.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/core/environment/app_environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies multipart HTTP 500 triggers baby-photo fallback instead of throwing.
void main() {
  setUpAll(() async {
    await AppEnvironment.init();
  });

  group('Repository profile photo fallback', () {
    test('multipart DioException triggers baby POST + JSON PUT fallback', () async {
      final fake = _ProfilePhotoFakeApi();
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Test User', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isTrue);
      expect(fake.multipartAttempts, 1);
      expect(fake.babyPhotoAttempts, 1);
      expect(fake.jsonPutAttempts, 1);
      expect(fake.lastJsonPayload?['photo'], 'https://cdn.example.com/photo.jpg');
      expect(fake.lastJsonPayload?['name'], 'Test User');
      expect(fake.lastJsonPayload?['phone'], '+918769626027');
      expect(fake.lastJsonPayload?.containsKey('conditions'), isFalse);
    });

    test('direct multipart success skips fallback', () async {
      final fake = _ProfilePhotoFakeApi(multipartSucceeds: true);
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Direct', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isTrue);
      expect(fake.multipartAttempts, 1);
      expect(fake.babyPhotoAttempts, 0);
      expect(fake.jsonPutAttempts, 0);
    });

    test('baby POST DioException returns error without crashing', () async {
      final fake = _ProfilePhotoFakeApi(
        babyPostThrows: true,
        photosListUrl: '',
      );
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Test User', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isFalse);
      expect(fake.babyPhotoAttempts, 1);
      expect(result.message, contains('Photo upload failed'));
    });

    test('baby POST DioException recovers URL from GET photos', () async {
      final fake = _ProfilePhotoFakeApi(
        babyPostThrows: true,
        photosListUrl: 'https://cdn.example.com/recovered.jpg',
      );
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Test User', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isTrue);
      expect(fake.getPhotosAttempts, greaterThan(0));
      expect(fake.lastJsonPayload?['photo'], 'https://cdn.example.com/recovered.jpg');
    });

    test('empty upload URL falls back to GET photos', () async {
      final fake = _ProfilePhotoFakeApi(
        babyPostEmptyUrl: true,
        photosListUrl: 'https://cdn.example.com/from-list.jpg',
      );
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Test User', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isTrue);
      expect(fake.getPhotosAttempts, greaterThan(0));
      expect(fake.lastJsonPayload?['photo'], 'https://cdn.example.com/from-list.jpg');
    });

    test('prepregnancy multipart 500 skips baby POST with server-unavailable message', () async {
      final fake = _ProfilePhotoFakeApi(stage: 'prepregnancy');
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final result = await repo.updateUserProfile(
        {'name': 'Test User', 'phone': '+918769626027'},
        profileImage: image,
      );

      expect(result.success, isFalse);
      expect(fake.multipartAttempts, 1);
      expect(fake.babyPhotoAttempts, 0);
      expect(fake.jsonPutAttempts, 0);
      expect(
        result.message,
        contains('temporarily unavailable'),
      );
    });

    test('concurrent photo uploads coalesce into one request', () async {
      final fake = _ProfilePhotoFakeApi();
      final repo = Repository(apiService: fake);
      final image = await _tempJpeg();

      final results = await Future.wait([
        repo.updateUserProfile(
          {'name': 'Test User', 'phone': '+918769626027'},
          profileImage: image,
        ),
        repo.updateUserProfile(
          {'name': 'Test User', 'phone': '+918769626027'},
          profileImage: image,
        ),
      ]);

      expect(results.every((r) => r.success == true), isTrue);
      expect(fake.multipartAttempts, 1);
      expect(fake.babyPhotoAttempts, 1);
    });
  });
}

class _ProfilePhotoFakeApi implements NetworkApiServices {
  _ProfilePhotoFakeApi({
    this.multipartSucceeds = false,
    this.babyPostThrows = false,
    this.babyPostEmptyUrl = false,
    this.photosListUrl = 'https://cdn.example.com/from-get.jpg',
    this.stage = 'postpregnancy',
  });

  final bool multipartSucceeds;
  final bool babyPostThrows;
  final bool babyPostEmptyUrl;
  final String photosListUrl;
  final String stage;

  int multipartAttempts = 0;
  int babyPhotoAttempts = 0;
  int jsonPutAttempts = 0;
  int getPhotosAttempts = 0;
  Map<String, dynamic>? lastJsonPayload;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<dynamic> get(String url, {Map<String, dynamic>? params}) async {
    if (url.contains('get/photos')) {
      getPhotosAttempts++;
      if (photosListUrl.isEmpty) {
        return {'success': true, 'photos': []};
      }
      return {
        'success': true,
        'photos': [
          {
            'photoUrl': photosListUrl,
            'createdAt': '2026-08-23T12:00:00.000Z',
          },
        ],
      };
    }
    if (url.contains('babygrowths/get')) {
      return {
        'success': true,
        'tracker': {'_id': 'tracker123'},
      };
    }
    if (url.contains('users/getUser')) {
      return {
        'success': true,
        'message': 'ok',
        'user': {
          'success': true,
          'user': {
            'name': 'Test User',
            'phone': '+918769626027',
            'stage': stage,
          },
        },
      };
    }
    return {'success': true};
  }

  @override
  Future<dynamic> putApiMultiPart(
    String url,
    Map<String, dynamic> fields,
    Map<String, File> files,
  ) async {
    multipartAttempts++;
    if (multipartSucceeds) {
      return {'success': true, 'message': 'ok'};
    }
    throw DioException(
      requestOptions: RequestOptions(path: url),
      response: Response(
        requestOptions: RequestOptions(path: url),
        statusCode: 500,
        data: {'success': false, 'message': 'Internal server error'},
      ),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  Future<dynamic> postApiMultiPart(
    String url,
    Map<String, dynamic> fields,
    Map<String, File> files,
  ) async {
    babyPhotoAttempts++;
    if (babyPostThrows) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        response: Response(
          requestOptions: RequestOptions(path: url),
          statusCode: 500,
          data: {'success': false, 'message': 'Internal server error'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    if (babyPostEmptyUrl) {
      return {'success': true, 'message': 'uploaded', 'data': {}};
    }
    return {
      'success': true,
      'message': 'uploaded',
      'data': {'photoUrl': 'https://cdn.example.com/photo.jpg'},
    };
  }

  @override
  Future<dynamic> put(String url, {dynamic data, Map<String, dynamic>? headers}) async {
    jsonPutAttempts++;
    lastJsonPayload = Map<String, dynamic>.from(data as Map);
    return {'success': true, 'message': 'profile updated'};
  }
}

Future<File> _tempJpeg() async {
  final file = File('${Directory.systemTemp.path}/repo_profile_test.jpg');
  await file.writeAsBytes([
    0xFF, 0xD8, 0xFF, 0xD9,
  ]);
  return file;
}
