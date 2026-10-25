import 'dart:ui';

import 'photo_framing.dart';

/// Pure geometry shared by the on-screen editor, the previews and the
/// renderer, so what the user sees is what gets saved.
///
/// All rectangles are in the pixels of the picture *after* it is turned by the
/// framing's quarter turns.
abstract final class FramingGeometry {
  /// The size of a [source] picture once turned by [quarterTurns].
  static Size rotatedSize(Size source, int quarterTurns) =>
      quarterTurns.isOdd ? source.flipped : source;

  /// The largest rectangle of [aspectRatio] (width / height) that fits in
  /// [size].
  static Size largestFit(Size size, double aspectRatio) {
    assert(aspectRatio > 0, 'aspectRatio must be positive');
    if (size.width / size.height > aspectRatio) {
      return Size(size.height * aspectRatio, size.height);
    }
    return Size(size.width, size.width / aspectRatio);
  }

  /// The area of the turned [source] picture that [framing] keeps, at
  /// [aspectRatio] (width / height).
  ///
  /// Zoom is clamped to 1…[maxZoom] and offsets to −1…1, so the rectangle
  /// always lies inside the picture.
  static Rect cropRect(
    Size source,
    PhotoFraming framing, {
    required double aspectRatio,
    double maxZoom = 4,
  }) {
    final size = rotatedSize(source, framing.quarterTurns);
    final crop = _cropSize(size, framing, aspectRatio, maxZoom);
    final freeX = size.width - crop.width;
    final freeY = size.height - crop.height;
    final ox = framing.offsetX.clamp(-1.0, 1.0);
    final oy = framing.offsetY.clamp(-1.0, 1.0);
    return Rect.fromLTWH(
      freeX / 2 * (1 + ox),
      freeY / 2 * (1 + oy),
      crop.width,
      crop.height,
    );
  }

  /// [framing] after the picture is dragged by [stageFraction], in fractions
  /// of the crop box (1.0 is the crop's full width or height).
  ///
  /// Dragging the picture right moves the kept area left. The result is
  /// clamped so the kept area stays inside the picture; an axis with no free
  /// travel stays centred.
  static PhotoFraming pan(
    Size source,
    PhotoFraming framing,
    Offset stageFraction, {
    required double aspectRatio,
    double maxZoom = 4,
  }) {
    if (source.isEmpty) return framing;
    final size = rotatedSize(source, framing.quarterTurns);
    final crop = _cropSize(size, framing, aspectRatio, maxZoom);
    double next(double current, double delta, double side, double free) {
      if (free <= 0) return 0;
      return (current - delta * side / (free / 2)).clamp(-1.0, 1.0);
    }

    return framing.copyWith(
      offsetX: next(
        framing.offsetX,
        stageFraction.dx,
        crop.width,
        size.width - crop.width,
      ),
      offsetY: next(
        framing.offsetY,
        stageFraction.dy,
        crop.height,
        size.height - crop.height,
      ),
    );
  }

  static Size _cropSize(
    Size rotated,
    PhotoFraming framing,
    double aspectRatio,
    double maxZoom,
  ) {
    final zoom = framing.zoom.clamp(1.0, maxZoom);
    return largestFit(rotated, aspectRatio) / zoom;
  }
}
