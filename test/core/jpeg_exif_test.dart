import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/src/core/jpeg_exif.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  group('jpegOrientation', () {
    for (var o = 1; o <= 8; o++) {
      test('reads orientation $o', () {
        expect(jpegOrientation(TestImages.exifJpeg(orientation: o)), o);
      });
    }

    test('is 1 without EXIF, or for anything that is not a JPEG', () {
      expect(jpegOrientation(TestImages.plainJpeg()), 1);
      expect(jpegOrientation(TestImages.asymmetricPng()), 1);
      expect(jpegOrientation(TestImages.brokenJpeg()), 1);
      expect(jpegOrientation(Uint8List(0)), 1);
    });

    test('reads the fixture from a real camera layout', () {
      final fixture =
          File('test/fixtures/exif_orientation_6.jpg').readAsBytesSync();
      expect(jpegOrientation(fixture), 6);
    });
  });

  group('withoutJpegExif', () {
    test('removes the EXIF block and keeps the picture', () {
      final source = TestImages.exifJpeg(orientation: 6);
      final stripped = withoutJpegExif(source);
      expect(stripped.length, lessThan(source.length));
      expect(img.decodeJpgExif(stripped)?.imageIfd.hasOrientation ?? false,
          isFalse);
      expect(String.fromCharCodes(stripped).contains('Exif'), isFalse);
      // Same stored pixels: 80 x 40, red block top-left.
      final decoded = img.decodeJpg(stripped)!;
      expect(decoded.width, 80);
      expect(decoded.height, 40);
      expect(decoded.getPixel(3, 3).r, greaterThan(150));
    });

    test('works on the camera fixture', () {
      final fixture =
          File('test/fixtures/exif_orientation_6.jpg').readAsBytesSync();
      final stripped = withoutJpegExif(fixture);
      expect(jpegOrientation(stripped), 1);
      expect(img.decodeJpg(stripped), isNotNull);
    });

    test('returns the same bytes when there is nothing to remove', () {
      for (final bytes in [
        TestImages.plainJpeg(),
        TestImages.asymmetricPng(),
        TestImages.brokenJpeg(),
        Uint8List(0),
      ]) {
        expect(identical(withoutJpegExif(bytes), bytes), isTrue);
      }
    });

    test('keeps fill bytes and stops at a damaged segment', () {
      // SOI, a fill byte, an EXIF APP1, then a segment whose length runs
      // past the end.
      final bytes = Uint8List.fromList([
        0xFF, 0xD8, //
        0xFF, //
        0xFF, 0xE1, 0x00, 0x08, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00, //
        0xFF, 0xD0, //
        0xFF, 0xE0, 0x00, 0x40, 0x01, //
      ]);
      expect(withoutJpegExif(bytes), [
        0xFF, 0xD8, 0xFF, 0xFF, 0xD0, 0xFF, 0xE0, 0x00, 0x40, 0x01, //
      ]);
    });
  });
}
