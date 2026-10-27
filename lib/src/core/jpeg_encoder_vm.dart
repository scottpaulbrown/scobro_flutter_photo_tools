import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Encodes straight (not premultiplied) RGBA pixels as a JPEG.
///
/// Off the web this uses the `image` package. The pixels are expected to be
/// opaque: JPEG has no alpha, and the renderer flattens first.
Future<Uint8List> encodeJpegRgba(
  Uint8List rgba,
  int width,
  int height,
  int quality,
) async {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    bytesOffset: rgba.offsetInBytes,
    numChannels: 4,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}
