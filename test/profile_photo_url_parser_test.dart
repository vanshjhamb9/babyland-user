import 'package:babyland/app/data/repository/profile_photo_url_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractUploadedPhotoUrl extended keys', () {
    test('extracts secure_url from Cloudinary-style payload', () {
      expect(
        extractUploadedPhotoUrl({
          'secure_url': 'https://res.cloudinary.com/demo/photo.jpg',
        }),
        'https://res.cloudinary.com/demo/photo.jpg',
      );
    });

    test('extracts nested imageUrl', () {
      expect(
        extractUploadedPhotoUrl({
          'data': {'imageUrl': 'https://cdn.example.com/nested.jpg'},
        }),
        'https://cdn.example.com/nested.jpg',
      );
    });
  });
}
