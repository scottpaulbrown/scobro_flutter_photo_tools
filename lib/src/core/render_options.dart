import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'image_format.dart';

/// The file format the renderer writes.
@immutable
sealed class OutputFormat {
  const OutputFormat();

  /// A JPEG at [quality] (1–100). JPEG has no transparency, so transparent
  /// pixels are flattened onto [background], an ARGB colour value such as
  /// `0xFFFFFFFF` (white).
  const factory OutputFormat.jpeg({int quality, int background}) = JpegOutput;

  /// A PNG, which keeps transparency.
  const factory OutputFormat.png() = PngOutput;

  /// The [ImageFormat] this writes.
  ImageFormat get imageFormat;
}

/// A JPEG output; see [OutputFormat.jpeg].
final class JpegOutput extends OutputFormat {
  /// Creates a [JpegOutput].
  const JpegOutput({this.quality = 88, this.background = 0xFFFFFFFF})
      : assert(quality >= 1 && quality <= 100, 'quality must be 1–100');

  /// The JPEG quality, 1–100.
  final int quality;

  /// The ARGB colour that transparent pixels are flattened onto.
  final int background;

  @override
  ImageFormat get imageFormat => ImageFormat.jpeg;

  @override
  bool operator ==(Object other) =>
      other is JpegOutput &&
      other.quality == quality &&
      other.background == background;

  @override
  int get hashCode => Object.hash(JpegOutput, quality, background);

  @override
  String toString() =>
      'OutputFormat.jpeg(quality: $quality, background: 0x${background.toRadixString(16)})';
}

/// A PNG output; see [OutputFormat.png].
final class PngOutput extends OutputFormat {
  /// Creates a [PngOutput].
  const PngOutput();

  @override
  ImageFormat get imageFormat => ImageFormat.png;

  @override
  bool operator ==(Object other) => other is PngOutput;

  @override
  int get hashCode => (PngOutput).hashCode;

  @override
  String toString() => 'OutputFormat.png()';
}

/// How a framed picture is cropped and written.
@immutable
class RenderOptions {
  /// Creates [RenderOptions].
  const RenderOptions({
    this.aspectRatio = 1,
    this.outputLongEdge = 1024,
    this.format = const OutputFormat.jpeg(),
    this.maxZoom = 4,
  })  : assert(aspectRatio > 0, 'aspectRatio must be positive'),
        assert(outputLongEdge > 0, 'outputLongEdge must be positive'),
        assert(maxZoom >= 1, 'maxZoom must be at least 1');

  /// The crop's width divided by its height: 1 for a square, 16 / 9 for a
  /// wide banner, 3 / 4 for a portrait card.
  final double aspectRatio;

  /// The length in pixels of the output's longer edge. The shorter edge
  /// follows from [aspectRatio].
  final int outputLongEdge;

  /// The file format written.
  final OutputFormat format;

  /// How far the user may zoom in; 4 keeps a quarter of the width.
  final double maxZoom;

  /// The output picture's size in pixels.
  Size get outputSize {
    if (aspectRatio >= 1) {
      final short = (outputLongEdge / aspectRatio).round();
      return Size(
          outputLongEdge.toDouble(), (short < 1 ? 1 : short).toDouble());
    }
    final short = (outputLongEdge * aspectRatio).round();
    return Size((short < 1 ? 1 : short).toDouble(), outputLongEdge.toDouble());
  }

  /// A copy with the given fields replaced.
  RenderOptions copyWith({
    double? aspectRatio,
    int? outputLongEdge,
    OutputFormat? format,
    double? maxZoom,
  }) =>
      RenderOptions(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        outputLongEdge: outputLongEdge ?? this.outputLongEdge,
        format: format ?? this.format,
        maxZoom: maxZoom ?? this.maxZoom,
      );

  @override
  bool operator ==(Object other) =>
      other is RenderOptions &&
      other.aspectRatio == aspectRatio &&
      other.outputLongEdge == outputLongEdge &&
      other.format == format &&
      other.maxZoom == maxZoom;

  @override
  int get hashCode => Object.hash(aspectRatio, outputLongEdge, format, maxZoom);

  @override
  String toString() => 'RenderOptions(aspectRatio: $aspectRatio, '
      'outputLongEdge: $outputLongEdge, format: $format, maxZoom: $maxZoom)';
}
