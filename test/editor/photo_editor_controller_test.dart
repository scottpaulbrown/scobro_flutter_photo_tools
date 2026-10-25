import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  late PhotoEditorController controller;

  Future<PhotoEditorController> loaded({
    int w = 80,
    int h = 40,
    RenderOptions options = const RenderOptions(outputLongEdge: 256),
    PhotoRenderer? renderer,
  }) async {
    controller = PhotoEditorController(options: options, renderer: renderer);
    addTearDown(controller.dispose);
    await controller.load(TestImages.asymmetricPng(width: w, height: h));
    return controller;
  }

  test('starts idle, then loads the picture with the default framing',
      () async {
    final c = PhotoEditorController();
    addTearDown(c.dispose);
    expect(c.status, PhotoEditorStatus.idle);
    expect(c.isReady, isFalse);
    expect(c.image, isNull);
    expect(c.imageSize, isNull);
    expect(c.renderer, isA<PhotoRenderer>());
    expect(c.options, const RenderOptions());

    final statuses = <PhotoEditorStatus>[];
    c.addListener(() => statuses.add(c.status));
    final source = TestImages.asymmetricPng();
    await c.load(source);

    expect(statuses.first, PhotoEditorStatus.loading);
    expect(c.status, PhotoEditorStatus.ready);
    expect(c.isReady, isTrue);
    expect(c.source, source);
    expect(c.imageSize, const Size(80, 40));
    expect(c.framing, const PhotoFraming());
    expect(c.isEdited, isFalse);
    expect(c.error, isNull);
  });

  test('four turns return to the start', () async {
    final c = await loaded();
    for (var i = 0; i < 4; i++) {
      c.rotateClockwise();
      expect(c.framing.quarterTurns, (i + 1) % 4);
    }
    expect(c.framing, const PhotoFraming());
    expect(c.isEdited, isFalse);
  });

  test('zoom is clamped to 1…maxZoom', () async {
    final c = await loaded(
      options: const RenderOptions(maxZoom: 3, outputLongEdge: 64),
    );
    c.setZoom(9);
    expect(c.framing.zoom, 3);
    c.setZoom(0.2);
    expect(c.framing.zoom, 1);
    c.setZoom(2);
    expect(c.isEdited, isTrue);
  });

  test('panning moves the crop and stays inside the picture', () async {
    final c = await loaded();
    c.panBy(const Offset(-0.2, 0));
    expect(c.framing.offsetX, greaterThan(0));
    c.panBy(const Offset(-50, 0));
    expect(c.framing.offsetX, 1);
    c.panBy(const Offset(0, 0.5));
    // A landscape picture at zoom 1 has no vertical travel.
    expect(c.framing.offsetY, 0);
    expect(c.isEdited, isTrue);
    c.reset();
    expect(c.framing, const PhotoFraming());
  });

  test('editing does nothing before the picture is ready', () {
    final c = PhotoEditorController();
    addTearDown(c.dispose);
    var notified = 0;
    c
      ..addListener(() => notified++)
      ..rotateClockwise()
      ..setZoom(2)
      ..panBy(const Offset(1, 1))
      ..reset();
    expect(notified, 0);
    expect(c.framing, const PhotoFraming());
  });

  test('render gives the framed picture at the options size', () async {
    final c = await loaded(
      options: const RenderOptions(aspectRatio: 16 / 9, outputLongEdge: 320),
    );
    c
      ..setZoom(2)
      ..rotateClockwise();
    final statuses = <PhotoEditorStatus>[];
    c.addListener(() => statuses.add(c.status));
    final edited = await c.render();

    expect(statuses, [PhotoEditorStatus.rendering, PhotoEditorStatus.ready]);
    expect(edited, isNotNull);
    expect(edited!.width, 320);
    expect(edited.height, 180);
    expect(edited.framing, c.framing);
    final decoded = img.decodeJpg(edited.bytes)!;
    expect(decoded.width, 320);
    expect(c.status, PhotoEditorStatus.ready);
  });

  test('a failed render returns null and keeps the picture', () async {
    final renderer = FakeRenderer(renderError: StateError('disk full'));
    final c = await loaded(renderer: renderer);
    expect(await c.render(), isNull);
    expect(c.status, PhotoEditorStatus.ready);
    expect(c.error, isA<StateError>());
    expect(c.isReady, isTrue);

    renderer.renderError = null;
    expect(await c.render(), isNotNull);
    expect(c.error, isNull);
  });

  test('render before loading returns null', () async {
    final c = PhotoEditorController();
    addTearDown(c.dispose);
    expect(await c.render(), isNull);
  });

  test('an unreadable picture fails to load', () async {
    final c = PhotoEditorController();
    addTearDown(c.dispose);
    await c.load(TestImages.brokenJpeg());
    expect(c.status, PhotoEditorStatus.failed);
    expect(c.error, isNotNull);
    expect(c.image, isNull);
    expect(c.isReady, isFalse);
  });

  test('a picture the renderer cannot read fails, even if Flutter can',
      () async {
    final c = PhotoEditorController(
      renderer: FakeRenderer(sizeError: const FormatException('nope')),
    );
    addTearDown(c.dispose);
    await c.load(TestImages.asymmetricPng());
    expect(c.status, PhotoEditorStatus.failed);
    expect(c.error, isFormatException);
  });

  test('a codec that ignores EXIF falls back to upright pixels', () async {
    // The renderer says the picture is 40 x 80 upright, but the codec gives
    // the stored 80 x 40, as a codec ignoring EXIF would.
    final renderer = FakeRenderer(size: const Size(40, 80));
    final c = PhotoEditorController(renderer: renderer);
    addTearDown(c.dispose);
    await c.load(TestImages.asymmetricPng());
    expect(renderer.bakeCalls, 1);
    expect(c.status, PhotoEditorStatus.ready);
  });

  test('a newer load wins over an older one', () async {
    final c = PhotoEditorController();
    addTearDown(c.dispose);
    final first = c.load(TestImages.asymmetricPng(width: 30, height: 10));
    final second = c.load(TestImages.asymmetricPng(width: 12, height: 50));
    await Future.wait([first, second]);
    expect(c.imageSize, const Size(12, 50));

    final failing = c.load(TestImages.brokenJpeg());
    final good = c.load(TestImages.asymmetricPng());
    await Future.wait([failing, good]);
    expect(c.status, PhotoEditorStatus.ready);
    expect(c.imageSize, const Size(80, 40));
  });

  test('disposing during a load or render is safe', () async {
    final c = PhotoEditorController();
    final load = c.load(TestImages.asymmetricPng());
    c.dispose();
    await load;

    final failing = PhotoEditorController();
    final failedLoad = failing.load(TestImages.brokenJpeg());
    failing.dispose();
    await failedLoad;

    final rendering = PhotoEditorController(
      options: const RenderOptions(outputLongEdge: 16),
    );
    await rendering.load(TestImages.asymmetricPng());
    final render = rendering.render();
    rendering.dispose();
    expect(await render, isNotNull);

    final renderer = FakeRenderer(renderError: StateError('x'));
    final failingRender = PhotoEditorController(renderer: renderer);
    await failingRender.load(TestImages.asymmetricPng());
    final failed = failingRender.render();
    failingRender.dispose();
    expect(await failed, isNull);
  });
}
