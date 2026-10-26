import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/framing_geometry.dart';
import '../core/photo_framing.dart';

/// Draws [image] on [canvas] so the area [framing] keeps fills [target].
///
/// [target] should have the same [aspectRatio] (width / height) as the crop.
/// Parts of the picture outside the crop are drawn too, beyond [target]'s
/// edges; clip the canvas first if you only want the crop. Uses the same
/// geometry as `PhotoRenderer`, so the result matches the saved picture.
void paintFramedImage(
  Canvas canvas,
  ui.Image image,
  PhotoFraming framing,
  Rect target, {
  required double aspectRatio,
  double maxZoom = 4,
}) {
  final w = image.width.toDouble();
  final h = image.height.toDouble();
  final crop = FramingGeometry.cropRect(
    Size(w, h),
    framing,
    aspectRatio: aspectRatio,
    maxZoom: maxZoom,
  );
  final scale = target.width / crop.width;
  canvas
    ..save()
    ..translate(target.left, target.top)
    ..scale(scale)
    ..translate(-crop.left, -crop.top);
  // Carry the picture into the turned space the crop is measured in.
  switch (framing.quarterTurns % 4) {
    case 1:
      canvas
        ..translate(h, 0)
        ..rotate(math.pi / 2);
    case 2:
      canvas
        ..translate(w, h)
        ..rotate(math.pi);
    case 3:
      canvas
        ..translate(0, w)
        ..rotate(-math.pi / 2);
  }
  canvas
    ..drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    )
    ..restore();
}

/// The picture as [framing] keeps it, painted to fill whatever box it is
/// given. Give it a box of the same [aspectRatio]; previews use it so they
/// match the saved result.
class FramedImage extends StatelessWidget {
  /// Creates a [FramedImage].
  const FramedImage({
    super.key,
    required this.image,
    required this.framing,
    required this.aspectRatio,
    this.maxZoom = 4,
  });

  /// The decoded picture, upright.
  final ui.Image image;

  /// How it is framed.
  final PhotoFraming framing;

  /// The crop's width divided by its height.
  final double aspectRatio;

  /// The largest zoom the framing may use.
  final double maxZoom;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: CustomPaint(
          painter: _FramedImagePainter(image, framing, aspectRatio, maxZoom),
        ),
      );
}

class _FramedImagePainter extends CustomPainter {
  _FramedImagePainter(this.image, this.framing, this.aspectRatio, this.maxZoom);

  final ui.Image image;
  final PhotoFraming framing;
  final double aspectRatio;
  final double maxZoom;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(box);
    paintFramedImage(
      canvas,
      image,
      framing,
      box,
      aspectRatio: aspectRatio,
      maxZoom: maxZoom,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FramedImagePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.framing != framing ||
      oldDelegate.aspectRatio != aspectRatio ||
      oldDelegate.maxZoom != maxZoom;
}
