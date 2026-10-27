import 'dart:typed_data';
import 'dart:ui' as ui;

import '../editor/framed_image.dart';
import 'image_format.dart';
import 'jpeg_encoder.dart';
import 'jpeg_exif.dart';
import 'photo_framing.dart';
import 'render_options.dart';

/// The renderer's work done with Flutter's image codec and canvas instead of
/// the `image` package.
///
/// On the web, Flutter hands decoding to the browser and drawing to the GPU,
/// so a 12-megapixel photo takes a fraction of a second here, where decoding
/// it in Dart takes many seconds and freezes the page (the web has no
/// isolates). The results match the isolate pipeline: the same EXIF
/// orientation rules, the same crop geometry and the same output sizes.
abstract final class CodecPipeline {
  /// The picture's size once its EXIF orientation is applied.
  static Future<ui.Size> sizeOf(Uint8List source) async {
    final (bytes, orientation) = _stored(source);
    final image = await _decode(bytes);
    final size = orientation >= 5
        ? ui.Size(image.height.toDouble(), image.width.toDouble())
        : ui.Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  /// [source] with its EXIF orientation applied, encoded as a PNG.
  static Future<Uint8List> bakeOrientation(Uint8List source) async {
    // Always drawn through the canvas: in Chrome, the first PNG export of an
    // image straight from the codec comes back as raw pixels instead.
    final image = await decodeUpright(source, redraw: true);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      return png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  /// Renders [source] as [framing] keeps it, with [options].
  static Future<Uint8List> render(
    Uint8List source,
    PhotoFraming framing,
    RenderOptions options,
  ) async {
    final image = await decodeUpright(source);
    final ui.Image rendered;
    try {
      final out = options.outputSize;
      final width = out.width.round();
      final height = out.height.round();
      final target =
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, target)..clipRect(target);
      if (options.format case JpegOutput(:final background)) {
        // JPEG has no alpha: flatten onto the (opaque) background colour.
        canvas.drawRect(
          target,
          ui.Paint()..color = ui.Color(0xFF000000 | (background & 0xFFFFFF)),
        );
      }
      paintFramedImage(
        canvas,
        image,
        framing,
        target,
        aspectRatio: options.aspectRatio,
        maxZoom: options.maxZoom,
      );
      final picture = recorder.endRecording();
      try {
        rendered = await picture.toImage(width, height);
      } finally {
        picture.dispose();
      }
    } finally {
      image.dispose();
    }
    try {
      switch (options.format) {
        case JpegOutput(:final quality):
          final rgba = await rendered.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          return await encodeJpegRgba(
            rgba!.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
            rendered.width,
            rendered.height,
            quality,
          );
        case PngOutput():
          final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
          return png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      }
    } finally {
      rendered.dispose();
    }
  }

  /// [source] decoded and turned upright by its EXIF orientation. With
  /// [redraw], an upright picture is still drawn onto a fresh canvas image
  /// rather than returned straight from the codec.
  ///
  /// Throws a [FormatException] when [source] can't be decoded.
  static Future<ui.Image> decodeUpright(
    Uint8List source, {
    bool redraw = false,
  }) async {
    final (bytes, orientation) = _stored(source);
    final stored = await _decode(bytes);
    if (orientation == 1 && !redraw) return stored;
    try {
      return await _orient(stored, orientation);
    } finally {
      stored.dispose();
    }
  }

  /// The bytes to decode and the orientation to apply to them. For a JPEG
  /// the EXIF block is removed, so the codec returns the stored pixels on
  /// every browser and the orientation is applied here, once.
  static (Uint8List, int) _stored(Uint8List source) {
    if (detectImageFormat(source) != ImageFormat.jpeg) return (source, 1);
    return (withoutJpegExif(source), jpegOrientation(source));
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
    } catch (_) {
      throw const FormatException('The picture could not be read.');
    }
    try {
      return (await codec.getNextFrame()).image;
    } catch (_) {
      throw const FormatException('The picture could not be read.');
    } finally {
      codec.dispose();
    }
  }

  /// Draws [stored] the way EXIF [orientation] (2 to 8) says to show it,
  /// using the same rules as `bakeOrientation` in the `image` package.
  static Future<ui.Image> _orient(ui.Image stored, int orientation) async {
    final w = stored.width.toDouble();
    final h = stored.height.toDouble();
    // Where a stored pixel (x, y) lands: x' = a·x + c·y + e, y' = b·x + d·y + f.
    final (a, b, c, d, e, f) = switch (orientation) {
      2 => (-1.0, 0.0, 0.0, 1.0, w, 0.0), // mirrored
      3 => (-1.0, 0.0, 0.0, -1.0, w, h), // turned 180°
      4 => (1.0, 0.0, 0.0, -1.0, 0.0, h), // flipped
      5 => (0.0, 1.0, 1.0, 0.0, 0.0, 0.0), // transposed
      6 => (0.0, 1.0, -1.0, 0.0, h, 0.0), // turned 90° clockwise
      7 => (0.0, -1.0, -1.0, 0.0, h, w), // transversed
      8 => (0.0, -1.0, 1.0, 0.0, 0.0, w), // turned 90° anticlockwise
      _ => (1.0, 0.0, 0.0, 1.0, 0.0, 0.0),
    };
    final turned = orientation >= 5;
    final width = turned ? stored.height : stored.width;
    final height = turned ? stored.width : stored.height;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..transform(
        Float64List.fromList([
          a, b, 0, 0, //
          c, d, 0, 0, //
          0, 0, 1, 0, //
          e, f, 0, 1, //
        ]),
      )
      ..drawImage(stored, ui.Offset.zero, ui.Paint());
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }
}
