import 'package:flutter_test/flutter_test.dart';
import 'package:b_link/services/photo_service.dart';

void main() {
  test('storage path matches storage.rules', () {
    expect(PhotoService.pathFor('abc'), 'profile_photos/abc/photo.jpg');
  });

  test('content type follows the picked file (only types allowed by rules)', () {
    expect(PhotoService.contentTypeFor('IMG_1.JPG'), 'image/jpeg');
    expect(PhotoService.contentTypeFor('a.png'), 'image/png');
    expect(PhotoService.contentTypeFor('a.webp'), 'image/webp');
    expect(PhotoService.contentTypeFor('a.heic'), 'image/jpeg');
  });
}
