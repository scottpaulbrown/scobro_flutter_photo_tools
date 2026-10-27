import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The EXIF orientation (1 to 8) stored in [jpeg], or 1 when there is none
/// or it can't be read.
///
/// Reads only the EXIF block, never the pixels, so it is cheap for any size
/// of picture. It uses the same parser the isolate renderer decodes with, so
/// both renderers agree on which pictures need turning.
int jpegOrientation(Uint8List jpeg) {
  try {
    final orientation = img.decodeJpgExif(jpeg)?.imageIfd.orientation;
    return orientation != null && orientation >= 1 && orientation <= 8
        ? orientation
        : 1;
  } catch (_) {
    return 1;
  }
}

/// [jpeg] without its EXIF (APP1 `Exif`) segments, or [jpeg] itself when it
/// has none or isn't a JPEG.
///
/// Browsers differ on whether they apply EXIF orientation when decoding.
/// Removing the block makes every browser hand back the stored, unturned
/// pixels, so the renderer can turn them itself, the same way everywhere.
Uint8List withoutJpegExif(Uint8List jpeg) {
  if (jpeg.length < 4 || jpeg[0] != 0xFF || jpeg[1] != 0xD8) return jpeg;
  final kept = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(jpeg, 0, 2));
  var removed = false;
  var i = 2;
  while (i + 4 <= jpeg.length && jpeg[i] == 0xFF) {
    final marker = jpeg[i + 1];
    // Start of scan or end of image: the rest is picture data.
    if (marker == 0xDA || marker == 0xD9) break;
    // Fill bytes and markers that have no length.
    if (marker == 0xFF ||
        marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      kept.add(Uint8List.sublistView(jpeg, i, i + (marker == 0xFF ? 1 : 2)));
      i += marker == 0xFF ? 1 : 2;
      continue;
    }
    final length = (jpeg[i + 2] << 8) | jpeg[i + 3];
    final end = i + 2 + length;
    if (length < 2 || end > jpeg.length) break;
    if (marker == 0xE1 && _isExifHeader(jpeg, i + 4, end)) {
      removed = true;
    } else {
      kept.add(Uint8List.sublistView(jpeg, i, end));
    }
    i = end;
  }
  if (!removed) return jpeg;
  kept.add(Uint8List.sublistView(jpeg, i));
  return kept.takeBytes();
}

const _exifHeader = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // "Exif\0\0"

bool _isExifHeader(Uint8List bytes, int start, int end) {
  if (end - start < _exifHeader.length) return false;
  for (var k = 0; k < _exifHeader.length; k++) {
    if (bytes[start + k] != _exifHeader[k]) return false;
  }
  return true;
}
