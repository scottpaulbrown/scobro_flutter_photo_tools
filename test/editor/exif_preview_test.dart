import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

// Answers the plan's open question: does the preview (Flutter's codec) agree
// with the renderer (package:image + EXIF) on an orientation-6 JPEG?
void main() {
  final fixture =
      File('test/fixtures/exif_orientation_6.jpg').readAsBytesSync();

  bool isRed(int r, int g, int b) => r > 150 && b < 120;

  Future<List<bool>> previewCorners(PhotoEditorController c) async {
    const box = Rect.fromLTWH(0, 0, 40, 80);
    final recorder = ui.PictureRecorder();
    paintFramedImage(
      Canvas(recorder),
      c.image!,
      c.framing,
      box,
      aspectRatio: c.options.aspectRatio,
    );
    final image = await recorder.endRecording().toImage(40, 80);
    final data = (await image.toByteData())!;
    image.dispose();
    bool at(int x, int y) {
      final i = (y * 40 + x) * 4;
      return isRed(
          data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
    }

    return [at(3, 3), at(36, 3), at(3, 76), at(36, 76)];
  }

  List<bool> renderedCorners(Uint8List bytes) {
    final out = img.decodeJpg(bytes)!;
    bool at(int x, int y) {
      final p = out.getPixel(x, y);
      return isRed(p.r.toInt(), p.g.toInt(), p.b.toInt());
    }

    return [at(3, 3), at(36, 3), at(3, 76), at(36, 76)];
  }

  test('the preview is upright and matches the rendered output', () async {
    // A 40 x 80 crop of the upright 40 x 80 picture: the whole of it.
    final c = PhotoEditorController(
      options: const RenderOptions(aspectRatio: 0.5, outputLongEdge: 80),
    );
    addTearDown(c.dispose);
    await c.load(fixture);

    expect(c.imageSize, const Size(40, 80));
    final preview = await previewCorners(c);
    final rendered = renderedCorners((await c.render())!.bytes);
    // The marker turns from the stored top-left to the upright top-right.
    expect(rendered, [false, true, false, false]);
    expect(preview, rendered);
  });

  test("Flutter's codec applies EXIF orientation on this platform", () async {
    // Records the answer to the open question. If a platform's codec ignores
    // EXIF, the controller falls back to upright pixels (tested separately).
    final codec = await ui.instantiateImageCodec(fixture);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);
    expect([frame.image.width, frame.image.height], [40, 80]);
  });
}
