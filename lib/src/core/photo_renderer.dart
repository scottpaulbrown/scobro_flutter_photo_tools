import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'edited_image.dart';
import 'framing_geometry.dart';
import 'photo_framing.dart';
import 'render_options.dart';

/// Turns a picked picture and its framing into the final file: applies the
/// EXIF orientation, rotates, crops, resizes and encodes.
///
/// The work runs through [compute], so on Android, iOS and desktop it happens
/// on a background isolate and never janks the UI. Web has no isolates, so a
/// large picture may stall a frame or two there; pick with a sensible
/// `PickerOptions.maxDimension` to keep it small.
class PhotoRenderer {
  /// Creates a [PhotoRenderer].
  const PhotoRenderer();

  /// The picture's size in pixels once its EXIF orientation is applied.
  ///
  /// Throws a [FormatException] when [source] can't be decoded.
  Future<Size> sizeOf(Uint8List source) async {
    final result = await compute(_sizeOf, source);
    return Size(result[0].toDouble(), result[1].toDouble());
  }

  /// [source] with its EXIF orientation applied, encoded as a PNG.
  ///
  /// The editor uses this to draw the picture upright on platforms whose
  /// image codec ignores EXIF orientation. Throws a [FormatException] when
  /// [source] can't be decoded.
  Future<Uint8List> bakeOrientation(Uint8List source) =>
      compute(_bakeOrientation, source);

  /// Renders [source] as [framing] keeps it, with [options].
  ///
  /// Throws a [FormatException] when [source] can't be decoded.
  Future<EditedImage> render(
    Uint8List source,
    PhotoFraming framing, [
    RenderOptions options = const RenderOptions(),
  ]) async {
    final bytes = await compute(_render, _RenderJob(source, framing, options));
    final size = options.outputSize;
    return EditedImage(
      bytes: bytes,
      width: size.width.round(),
      height: size.height.round(),
      format: options.format.imageFormat,
      framing: framing,
    );
  }
}

class _RenderJob {
  const _RenderJob(this.source, this.framing, this.options);
  final Uint8List source;
  final PhotoFraming framing;
  final RenderOptions options;
}

img.Image _decode(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) {
    throw const FormatException('The picture could not be read.');
  }
  final upright = img.bakeOrientation(decoded);
  // Expand indexed colour so every later step works on plain pixels.
  return upright.hasPalette
      ? upright.convert(numChannels: upright.numChannels)
      : upright;
}

List<int> _sizeOf(Uint8List source) {
  final image = _decode(source);
  return [image.width, image.height];
}

Uint8List _bakeOrientation(Uint8List source) {
  final image = _decode(source)..exif = img.ExifData();
  return img.encodePng(image);
}

Uint8List _render(_RenderJob job) {
  var image = _decode(job.source);
  final options = job.options;
  final turns = job.framing.quarterTurns % 4;
  // The geometry measures from the upright (unturned) size plus the turns.
  final upright = Size(image.width.toDouble(), image.height.toDouble());
  if (turns != 0) {
    image = img.copyRotate(image, angle: turns * 90);
  }
  final rect = FramingGeometry.cropRect(
    upright,
    job.framing,
    aspectRatio: options.aspectRatio,
    maxZoom: options.maxZoom,
  );
  final w = rect.width.round().clamp(1, image.width);
  final h = rect.height.round().clamp(1, image.height);
  final x = rect.left.round().clamp(0, image.width - w);
  final y = rect.top.round().clamp(0, image.height - h);
  final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

  final out = options.outputSize;
  final outW = out.width.round();
  final outH = out.height.round();
  final resized = img.copyResize(
    cropped,
    width: outW,
    height: outH,
    interpolation: cropped.width > outW
        ? img.Interpolation.average
        : img.Interpolation.linear,
  )..exif = img.ExifData(); // Never pass on location or camera details.

  switch (options.format) {
    case JpegOutput(:final quality, :final background):
      // JPEG has no alpha: flatten onto the background colour.
      final flat = img.Image(width: outW, height: outH, numChannels: 3);
      img.fill(
        flat,
        color: img.ColorRgb8(
          (background >> 16) & 0xFF,
          (background >> 8) & 0xFF,
          background & 0xFF,
        ),
      );
      img.compositeImage(flat, resized);
      return Uint8List.fromList(img.encodeJpg(flat, quality: quality));
    case PngOutput():
      return Uint8List.fromList(img.encodePng(resized));
  }
}
