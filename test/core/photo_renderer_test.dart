import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

bool _isRed(img.Pixel p) => p.r > 150 && p.b < 120;
bool _isBlue(img.Pixel p) => p.b > 150 && p.r < 120;

void main() {
  const renderer = PhotoRenderer();
  // 80 x 40, with a 10 px red block at the top-left.
  final source = TestImages.asymmetricPng();
  const square512 = RenderOptions(outputLongEdge: 512);

  Future<img.Image> render(
    PhotoFraming framing, [
    RenderOptions options = square512,
  ]) async {
    final edited = await renderer.render(source, framing, options);
    return img.decodeImage(edited.bytes)!;
  }

  test('sizeOf reads the picture size', () async {
    // ignore: prefer_const_constructors
    expect(await PhotoRenderer().sizeOf(source), const Size(80, 40));
    expect(await renderer.sizeOf(source), const Size(80, 40));
  });

  test('an unreadable picture throws a FormatException', () async {
    await expectLater(
      renderer.sizeOf(TestImages.brokenJpeg()),
      throwsFormatException,
    );
    await expectLater(
      renderer.render(TestImages.brokenJpeg(), const PhotoFraming()),
      throwsFormatException,
    );
  });

  group('output size per aspect ratio', () {
    for (final (ratio, size) in [
      (1.0, const Size(512, 512)),
      (4 / 3, const Size(512, 384)),
      (16 / 9, const Size(512, 288)),
      (9 / 16, const Size(288, 512)),
    ]) {
      test('$ratio gives ${size.width.round()}x${size.height.round()}',
          () async {
        final options = RenderOptions(aspectRatio: ratio, outputLongEdge: 512);
        final edited =
            await renderer.render(source, const PhotoFraming(), options);
        expect(edited.width, size.width);
        expect(edited.height, size.height);
        final decoded = img.decodeJpg(edited.bytes)!;
        expect(decoded.width, size.width);
        expect(decoded.height, size.height);
        expect(edited.format, ImageFormat.jpeg);
        expect(detectImageFormat(edited.bytes), ImageFormat.jpeg);
      });
    }
  });

  test('the default options give a 1024 square', () async {
    final edited = await renderer.render(source, const PhotoFraming());
    expect(edited.width, 1024);
    expect(edited.height, 1024);
    expect(edited.framing, const PhotoFraming());
  });

  test('zoom keeps a smaller area', () async {
    // Zoom 1 at the left edge keeps x 0..40, so the 10 px block fills a
    // quarter of the side; zoom 2 at the top-left keeps 20 px, so half.
    final wide = await render(const PhotoFraming(offsetX: -1));
    final tight =
        await render(const PhotoFraming(zoom: 2, offsetX: -1, offsetY: -1));
    expect(_isRed(wide.getPixel(10, 10)), isTrue);
    expect(_isRed(tight.getPixel(200, 200)), isTrue);
    expect(_isRed(wide.getPixel(200, 200)), isFalse);
  });

  test('each quarter turn moves the marker corner', () async {
    Future<List<bool>> corners(int turns) async {
      // Offsets chosen so the crop always contains the marker corner.
      final framing = PhotoFraming(
        quarterTurns: turns,
        offsetX: turns == 0 || turns == 3 ? -1 : (turns == 2 ? 1 : 0),
        offsetY: turns == 1 || turns == 2 ? -1 : (turns == 3 ? 1 : 0),
      );
      final out = await render(framing);
      return [
        _isRed(out.getPixel(8, 8)),
        _isRed(out.getPixel(503, 8)),
        _isRed(out.getPixel(8, 503)),
        _isRed(out.getPixel(503, 503)),
      ];
    }

    // The marker's corner after each clockwise turn: TL, TR, BR, BL.
    expect(await corners(0), [true, false, false, false]);
    expect(await corners(1), [false, true, false, false]);
    expect(await corners(2), [false, false, false, true]);
    expect(await corners(3), [false, false, true, false]);
  });

  test('zoom, rotation and offset together match the geometry', () async {
    const framing = PhotoFraming(quarterTurns: 1, zoom: 2, offsetY: -1);
    final rect = FramingGeometry.cropRect(
      const Size(80, 40),
      framing,
      aspectRatio: 1,
    );
    // The turned picture is 40 x 80; the kept square is 20 wide, at the top.
    expect(rect, const Rect.fromLTWH(10, 0, 20, 20));
    final out = await render(framing);
    // The red block turns to x 30..40, y 0..10, outside x 10..30: blue.
    expect(_isBlue(out.getPixel(256, 256)), isTrue);
    expect(_isBlue(out.getPixel(500, 10)), isTrue);
  });

  test('a 16:9 crop of a turned picture keeps the right band', () async {
    const options = RenderOptions(aspectRatio: 16 / 9, outputLongEdge: 320);
    // Turned once: 40 x 80 with the red block top-right; a band at the top.
    final edited = await renderer.render(
      source,
      const PhotoFraming(quarterTurns: 1, offsetY: -1),
      options,
    );
    final out = img.decodeJpg(edited.bytes)!;
    expect(out.width, 320);
    expect(out.height, 180);
    expect(_isRed(out.getPixel(310, 10)), isTrue);
    expect(_isRed(out.getPixel(10, 10)), isFalse);
  });

  test('JPEG flattens transparency onto the background', () async {
    const options = RenderOptions(
      outputLongEdge: 16,
      format: OutputFormat.jpeg(background: 0xFF00FF00),
    );
    final edited = await renderer.render(
      TestImages.transparentPng(),
      const PhotoFraming(),
      options,
    );
    final p = img.decodeJpg(edited.bytes)!.getPixel(8, 8);
    expect(p.g, greaterThan(200));
    expect(p.r, lessThan(60));
    expect(p.b, lessThan(60));
  });

  test('the default JPEG background is white', () async {
    final edited = await renderer.render(
      TestImages.transparentPng(),
      const PhotoFraming(),
      const RenderOptions(outputLongEdge: 16),
    );
    final p = img.decodeJpg(edited.bytes)!.getPixel(8, 8);
    expect(p.r, greaterThan(240));
    expect(p.g, greaterThan(240));
    expect(p.b, greaterThan(240));
  });

  test('PNG keeps transparency', () async {
    const options =
        RenderOptions(outputLongEdge: 16, format: OutputFormat.png());
    final edited = await renderer.render(
      TestImages.transparentPng(),
      const PhotoFraming(),
      options,
    );
    expect(edited.format, ImageFormat.png);
    expect(edited.mimeType, 'image/png');
    final out = img.decodePng(edited.bytes)!;
    expect(out.hasAlpha, isTrue);
    expect(out.getPixel(8, 8).a, 0);
  });

  test('a palette PNG renders', () async {
    final paletted = img.Image(
      width: 20,
      height: 10,
      numChannels: 3,
      withPalette: true,
    );
    paletted.palette!.setRgb(0, 255, 0, 0);
    final edited = await renderer.render(
      Uint8List.fromList(img.encodePng(paletted)),
      const PhotoFraming(),
      const RenderOptions(outputLongEdge: 8, format: OutputFormat.png()),
    );
    final out = img.decodePng(edited.bytes)!;
    expect(out.width, 8);
    expect(_isRed(out.getPixel(4, 4)), isTrue);
  });

  test('upscales a small source to the output size', () async {
    final edited = await renderer.render(
      TestImages.plainJpeg(width: 4, height: 4),
      const PhotoFraming(),
      const RenderOptions(outputLongEdge: 64),
    );
    expect(img.decodeJpg(edited.bytes)!.width, 64);
  });

  group('EXIF orientation 6 fixture', () {
    final fixture =
        File('test/fixtures/exif_orientation_6.jpg').readAsBytesSync();

    test('sizeOf reports the upright size', () async {
      // Stored 80 x 40; orientation 6 shows it turned clockwise: 40 x 80.
      expect(await renderer.sizeOf(fixture), const Size(40, 80));
    });

    test('renders upright: the marker sits top-right', () async {
      final edited = await renderer.render(
        fixture,
        const PhotoFraming(offsetY: -1),
        const RenderOptions(outputLongEdge: 80),
      );
      final out = img.decodeJpg(edited.bytes)!;
      expect(_isRed(out.getPixel(75, 5)), isTrue);
      expect(_isRed(out.getPixel(5, 5)), isFalse);
    });

    test('bakeOrientation gives an upright PNG', () async {
      final baked = await renderer.bakeOrientation(fixture);
      expect(detectImageFormat(baked), ImageFormat.png);
      final out = img.decodePng(baked)!;
      expect(out.width, 40);
      expect(out.height, 80);
      expect(_isRed(out.getPixel(35, 5)), isTrue);
    });

    test('the output carries no EXIF', () async {
      final edited = await renderer.render(fixture, const PhotoFraming());
      expect(String.fromCharCodes(edited.bytes).contains('Exif'), isFalse);
    });
  });
}
