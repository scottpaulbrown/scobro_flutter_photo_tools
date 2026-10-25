import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

Uint8List _bytes(List<int> b) => Uint8List.fromList(b);

void main() {
  group('detectImageFormat', () {
    test('JPEG', () {
      expect(detectImageFormat(TestImages.plainJpeg()), ImageFormat.jpeg);
    });

    test('PNG', () {
      expect(detectImageFormat(TestImages.asymmetricPng()), ImageFormat.png);
    });

    test('WebP', () {
      final webp = _bytes([
        ...'RIFF'.codeUnits,
        0x24,
        0,
        0,
        0,
        ...'WEBPVP8 '.codeUnits,
        0,
        0,
      ]);
      expect(detectImageFormat(webp), ImageFormat.webp);
    });

    test('HEIC is not supported', () {
      final heic = _bytes([0, 0, 0, 0x18, ...'ftypheic'.codeUnits, 0, 0, 0, 0]);
      expect(detectImageFormat(heic), isNull);
    });

    test('PDF is not supported', () {
      expect(detectImageFormat(_bytes('%PDF-1.7\n'.codeUnits)), isNull);
    });

    test('empty and truncated input', () {
      expect(detectImageFormat(Uint8List(0)), isNull);
      expect(detectImageFormat(_bytes([0xFF, 0xD8])), isNull);
      expect(detectImageFormat(_bytes([0x89, 0x50, 0x4E, 0x47])), isNull);
      expect(detectImageFormat(_bytes('RIFF'.codeUnits)), isNull);
    });

    test('RIFF that is not WebP', () {
      final wav =
          _bytes([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WAVE'.codeUnits]);
      expect(detectImageFormat(wav), isNull);
    });
  });

  test('formats carry their MIME type and extension', () {
    expect(ImageFormat.jpeg.mimeType, 'image/jpeg');
    expect(ImageFormat.jpeg.fileExtension, 'jpg');
    expect(ImageFormat.png.mimeType, 'image/png');
    expect(ImageFormat.png.fileExtension, 'png');
    expect(ImageFormat.webp.mimeType, 'image/webp');
    expect(ImageFormat.webp.fileExtension, 'webp');
  });
}
