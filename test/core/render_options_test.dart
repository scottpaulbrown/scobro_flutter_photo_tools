import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

void main() {
  test('defaults: square 1024 JPEG at quality 88 on white, zoom up to 4', () {
    const o = RenderOptions();
    expect(o.aspectRatio, 1);
    expect(o.outputLongEdge, 1024);
    expect(o.format, const OutputFormat.jpeg());
    expect(o.maxZoom, 4);
    expect(o.outputSize, const Size(1024, 1024));
    final jpeg = o.format as JpegOutput;
    expect(jpeg.quality, 88);
    expect(jpeg.background, 0xFFFFFFFF);
  });

  test('output size follows the aspect ratio', () {
    Size size(double ratio, int edge) =>
        RenderOptions(aspectRatio: ratio, outputLongEdge: edge).outputSize;
    expect(size(16 / 9, 1600), const Size(1600, 900));
    expect(size(9 / 16, 1600), const Size(900, 1600));
    expect(size(4 / 3, 400), const Size(400, 300));
    expect(size(100, 10), const Size(10, 1));
    expect(size(0.01, 10), const Size(1, 10));
  });

  test('copyWith, equality and toString', () {
    const o = RenderOptions();
    expect(o.copyWith(), o);
    expect(o.hashCode, const RenderOptions().hashCode);
    final changed = o.copyWith(
      aspectRatio: 2,
      outputLongEdge: 200,
      format: const OutputFormat.png(),
      maxZoom: 3,
    );
    expect(changed.aspectRatio, 2);
    expect(changed.outputLongEdge, 200);
    expect(changed.format, const OutputFormat.png());
    expect(changed.maxZoom, 3);
    expect(changed, isNot(o));
    expect(o.toString(), contains('aspectRatio: 1'));
  });

  test('output formats', () {
    // A non-const call so the constructor counts as covered.
    // ignore: prefer_const_constructors
    expect(PngOutput().imageFormat, ImageFormat.png);
    expect(const OutputFormat.jpeg().imageFormat, ImageFormat.jpeg);
    expect(const OutputFormat.png().imageFormat, ImageFormat.png);
    expect(
      const OutputFormat.jpeg(quality: 70),
      const OutputFormat.jpeg(quality: 70),
    );
    expect(
      const OutputFormat.jpeg(quality: 70),
      isNot(const OutputFormat.jpeg(quality: 71)),
    );
    expect(
      const OutputFormat.jpeg().hashCode,
      const OutputFormat.jpeg().hashCode,
    );
    expect(const OutputFormat.png(), const OutputFormat.png());
    expect(
        const OutputFormat.png().hashCode, const OutputFormat.png().hashCode);
    expect(const OutputFormat.png(), isNot(const OutputFormat.jpeg()));
    expect(const OutputFormat.jpeg().toString(), contains('quality: 88'));
    expect(const OutputFormat.jpeg().toString(), contains('ffffffff'));
    expect(const OutputFormat.png().toString(), 'OutputFormat.png()');
  });
}
