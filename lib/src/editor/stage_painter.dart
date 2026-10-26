import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/photo_framing.dart';
import 'crop_guide_shape.dart';
import 'framed_image.dart';

/// Paints the editor's framing area: the whole picture, dimmed outside the
/// guide, with the guide's outline, a dashed outline of the saved rectangle
/// (when the guide isn't a plain rectangle) and a rule-of-thirds grid that
/// fades in while the picture is being moved.
class StagePainter extends CustomPainter {
  /// Creates a [StagePainter].
  StagePainter({
    required this.image,
    required this.framing,
    required this.cropBox,
    required this.aspectRatio,
    required this.maxZoom,
    required this.guideShape,
    required this.scrim,
    required this.guideColor,
    required this.guideWidth,
    required this.gridOpacity,
  });

  /// The upright picture.
  final ui.Image image;

  /// How it is framed.
  final PhotoFraming framing;

  /// Where the crop sits on the stage.
  final Rect cropBox;

  /// The crop's width divided by its height.
  final double aspectRatio;

  /// The largest zoom.
  final double maxZoom;

  /// The guide drawn over the crop box.
  final CropGuideShape guideShape;

  /// The colour laid over the picture outside the guide.
  final Color scrim;

  /// The guide's outline colour.
  final Color guideColor;

  /// The guide's outline width.
  final double guideWidth;

  /// 0–1: how visible the rule-of-thirds grid is.
  final double gridOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final stage = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(stage);
    paintFramedImage(
      canvas,
      image,
      framing,
      cropBox,
      aspectRatio: aspectRatio,
      maxZoom: maxZoom,
    );
    canvas.restore();

    final guide = guideShape.pathFor(cropBox);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(stage)
      ..addPath(guide, Offset.zero);
    canvas.drawPath(outside, Paint()..color = scrim);

    if (gridOpacity > 0) {
      final grid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = guideColor.withValues(alpha: 0.45 * gridOpacity);
      canvas
        ..save()
        ..clipPath(guide);
      for (var i = 1; i < 3; i++) {
        final x = cropBox.left + cropBox.width * i / 3;
        final y = cropBox.top + cropBox.height * i / 3;
        canvas
          ..drawLine(Offset(x, cropBox.top), Offset(x, cropBox.bottom), grid)
          ..drawLine(Offset(cropBox.left, y), Offset(cropBox.right, y), grid);
      }
      canvas.restore();
    }

    canvas.drawPath(
      guide,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = guideWidth
        ..color = guideColor,
    );

    if (guideShape != CropGuideShape.rect) {
      // The saved rectangle, dashed, so it's clear the corners are kept.
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = guideColor.withValues(alpha: 0.6);
      for (final metric in (Path()..addRect(cropBox)).computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          canvas.drawPath(metric.extractPath(distance, distance + 5), dash);
          distance += 9;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant StagePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.framing != framing ||
      oldDelegate.cropBox != cropBox ||
      oldDelegate.aspectRatio != aspectRatio ||
      oldDelegate.maxZoom != maxZoom ||
      oldDelegate.guideShape != guideShape ||
      oldDelegate.scrim != scrim ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.guideWidth != guideWidth ||
      oldDelegate.gridOpacity != gridOpacity;
}
