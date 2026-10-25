import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Small generated pictures for tests, so tests don't need asset files.
abstract final class TestImages {
  /// A [width] x [height] PNG, blue everywhere except a red [mark] x [mark]
  /// block in its top-left corner, so turns and crops can be told apart.
  static Uint8List asymmetricPng({
    int width = 80,
    int height = 40,
    int mark = 10,
  }) =>
      Uint8List.fromList(img.encodePng(_asymmetric(width, height, mark)));

  /// The same picture as [asymmetricPng], as a JPEG.
  static Uint8List asymmetricJpeg({
    int width = 80,
    int height = 40,
    int mark = 10,
  }) =>
      Uint8List.fromList(
        img.encodeJpg(_asymmetric(width, height, mark), quality: 95),
      );

  /// A plain green JPEG, [width] x [height].
  static Uint8List plainJpeg({int width = 20, int height = 20}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(10, 200, 60));
    return Uint8List.fromList(img.encodeJpg(image));
  }

  /// A fully transparent PNG, [width] x [height].
  static Uint8List transparentPng({int width = 20, int height = 20}) {
    final image = img.Image(width: width, height: height, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
    return Uint8List.fromList(img.encodePng(image));
  }

  /// A JPEG whose pixels are stored as [asymmetricJpeg] ([width] x [height],
  /// red block top-left) with EXIF [orientation] set, so viewers that honour
  /// EXIF show it turned. Orientation 6 means "turn 90° clockwise to view".
  static Uint8List exifJpeg({
    int width = 80,
    int height = 40,
    int mark = 10,
    int orientation = 6,
  }) {
    final image = _asymmetric(width, height, mark);
    image.exif.imageIfd.orientation = orientation;
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  /// Bytes that start like a JPEG but can't be decoded.
  static Uint8List brokenJpeg() =>
      Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);

  static img.Image _asymmetric(int width, int height, int mark) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(0, 0, 255));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: mark - 1,
      y2: mark - 1,
      color: img.ColorRgb8(255, 0, 0),
    );
    return image;
  }
}
