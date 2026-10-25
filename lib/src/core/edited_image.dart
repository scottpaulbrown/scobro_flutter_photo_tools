import 'package:flutter/foundation.dart';

import 'image_format.dart';
import 'photo_framing.dart';

/// A finished picture: the bytes to upload or store, with what you need to
/// send them.
///
/// Every API in the package that produces a picture hands back one of these.
@immutable
class EditedImage {
  /// Creates an [EditedImage].
  const EditedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    this.framing = const PhotoFraming(),
  });

  /// The encoded picture.
  final Uint8List bytes;

  /// The width in pixels.
  final int width;

  /// The height in pixels.
  final int height;

  /// The encoding of [bytes].
  final ImageFormat format;

  /// The framing the picture was rendered with.
  final PhotoFraming framing;

  /// The MIME type, for an upload's `Content-Type`, for example `image/jpeg`.
  String get mimeType => format.mimeType;

  /// The file extension without the dot, for example `jpg`.
  String get fileExtension => format.fileExtension;

  /// A file name for an upload: [stem] plus the extension, for example
  /// `photo.jpg`.
  String suggestedFileName([String stem = 'photo']) => '$stem.$fileExtension';

  @override
  String toString() => 'EditedImage(${width}x$height, ${format.name}, '
      '${bytes.length} bytes, $framing)';
}
