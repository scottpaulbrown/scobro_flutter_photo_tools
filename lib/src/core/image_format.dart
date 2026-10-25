import 'dart:typed_data';

/// The picture formats the package reads and writes.
///
/// The format is sniffed from the file's first bytes by [detectImageFormat],
/// never from its name or extension.
enum ImageFormat {
  /// JPEG (`image/jpeg`).
  jpeg('image/jpeg', 'jpg'),

  /// PNG (`image/png`).
  png('image/png', 'png'),

  /// WebP (`image/webp`). Accepted as input; never produced as output.
  webp('image/webp', 'webp');

  const ImageFormat(this.mimeType, this.fileExtension);

  /// The MIME type, for example `image/jpeg`.
  final String mimeType;

  /// The usual file extension without the dot, for example `jpg`.
  final String fileExtension;
}

/// The format of [bytes], read from their magic bytes, or null when they are
/// not a JPEG, PNG or WebP picture (HEIC, PDF, an empty list, ...).
ImageFormat? detectImageFormat(Uint8List bytes) {
  final b = bytes;
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return ImageFormat.jpeg;
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 && // P
      b[2] == 0x4E && // N
      b[3] == 0x47 && // G
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return ImageFormat.png;
  }
  if (b.length >= 12 &&
      b[0] == 0x52 && // R
      b[1] == 0x49 && // I
      b[2] == 0x46 && // F
      b[3] == 0x46 && // F
      b[8] == 0x57 && // W
      b[9] == 0x45 && // E
      b[10] == 0x42 && // B
      b[11] == 0x50) {
    // P
    return ImageFormat.webp;
  }
  return null;
}
