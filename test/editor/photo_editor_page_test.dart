import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  EditedImage? popped;
  bool returned = false;

  Future<void> open(
    WidgetTester tester, {
    Size size = Surfaces.phone,
    Uint8List? source,
    RenderOptions options = const RenderOptions(outputLongEdge: 256),
    List<PhotoPreviewSpec> previews = const [],
    PhotoRenderer? renderer,
    String? title,
    CropGuideShape guideShape = CropGuideShape.circle,
  }) async {
    popped = null;
    returned = false;
    useSurface(tester, size);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  popped = await showPhotoEditor(
                    context,
                    source: source ?? TestImages.asymmetricPng(),
                    options: options,
                    previews: previews,
                    renderer: renderer,
                    title: title,
                    guideShape: guideShape,
                  );
                  returned = true;
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, () => stagePainter(tester) != null);
  }

  PhotoFraming framing(WidgetTester tester) => stagePainter(tester)!.framing;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await tester.pump();
    await waitFor(tester, () => returned);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title, the picture and the actions', (tester) async {
    await open(tester);

    expect(find.text('Frame photo'), findsOneWidget);
    expect(find.byKey(PhotoToolsKeys.stage), findsOneWidget);
    expect(find.text('Save photo'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Rotate'), findsOneWidget);
    expect(stagePainter(tester)!.guideShape, CropGuideShape.circle);
    expect(find.byKey(PhotoToolsKeys.previews), findsNothing);
  });

  testWidgets('a custom title and guide shape', (tester) async {
    await open(tester, title: 'Banner', guideShape: CropGuideShape.rect);
    expect(find.text('Banner'), findsOneWidget);
    expect(stagePainter(tester)!.guideShape, CropGuideShape.rect);
  });

  testWidgets('dragging the stage pans the crop', (tester) async {
    await open(tester);
    await tester.drag(find.byKey(PhotoToolsKeys.stage), const Offset(-60, 0));
    await tester.pump();
    expect(framing(tester).offsetX, greaterThan(0));
  });

  testWidgets('the slider and zoom buttons zoom', (tester) async {
    await open(tester);
    await tester.drag(
      find.byKey(PhotoToolsKeys.zoomSlider),
      const Offset(30, 0),
    );
    await tester.pump();
    final dragged = framing(tester).zoom;
    expect(dragged, greaterThan(1));

    await tester.tap(find.byKey(PhotoToolsKeys.zoomIn));
    await tester.pump();
    expect(framing(tester).zoom, greaterThan(dragged));
    await tester.tap(find.byKey(PhotoToolsKeys.zoomOut));
    await tester.pump();
    await tester.tap(find.byKey(PhotoToolsKeys.zoomOut));
    await tester.pump();
    expect(framing(tester).zoom, lessThan(dragged));
  });

  testWidgets('the mouse wheel zooms', (tester) async {
    await open(tester);
    final center = tester.getCenter(find.byKey(PhotoToolsKeys.stage));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -200)));
    await tester.pump();
    expect(framing(tester).zoom, closeTo(1.5, 1e-9));
  });

  testWidgets('a pinch zooms', (tester) async {
    await open(tester);
    final center = tester.getCenter(find.byKey(PhotoToolsKeys.stage));
    final a = await tester.startGesture(center - const Offset(20, 0));
    final b = await tester.startGesture(center + const Offset(20, 0));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await a.moveBy(const Offset(-10, 0));
      await b.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pump();
    expect(framing(tester).zoom, greaterThan(1.3));
  });

  testWidgets('the keyboard pans and zooms the focused stage', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.stage));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(framing(tester).zoom, greaterThan(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(framing(tester).zoom, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(framing(tester).offsetX, lessThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(framing(tester).offsetX, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(framing(tester).offsetY, lessThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(framing(tester).offsetY, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
  });

  testWidgets('Rotate turns a quarter each tap and four restore',
      (tester) async {
    await open(tester);
    for (final turns in [1, 2, 3, 0]) {
      await tester.tap(find.byKey(PhotoToolsKeys.rotate));
      await tester.pump();
      expect(framing(tester).quarterTurns, turns);
    }
    expect(framing(tester), const PhotoFraming());
  });

  testWidgets('zoom, rotate and drag, then Save returns the framed picture',
      (tester) async {
    await open(tester);
    await tester.drag(
      find.byKey(PhotoToolsKeys.zoomSlider),
      const Offset(80, 0),
    );
    await tester.tap(find.byKey(PhotoToolsKeys.rotate));
    await tester.pump();
    await tester.drag(find.byKey(PhotoToolsKeys.stage), const Offset(0, 30));
    await tester.pump();
    final expected = framing(tester);

    await save(tester);

    expect(returned, isTrue);
    expect(popped!.framing, expected);
    final out = img.decodeJpg(popped!.bytes)!;
    expect(out.width, 256);
    expect(out.height, 256);
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('a 16:9 banner saves at 16:9', (tester) async {
    await open(
      tester,
      options: const RenderOptions(aspectRatio: 16 / 9, outputLongEdge: 320),
      guideShape: CropGuideShape.roundedRect,
    );
    final box = stagePainter(tester)!.cropBox;
    expect(box.width / box.height, closeTo(16 / 9, 0.01));
    await save(tester);
    expect(popped!.width, 320);
    expect(popped!.height, 180);
  });

  testWidgets('Cancel pops null', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.cancel));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(popped, isNull);
  });

  testWidgets('the close button pops null', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.close));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(popped, isNull);
  });

  testWidgets('system back pops null', (tester) async {
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(popped, isNull);
  });

  testWidgets('leaving after edits asks before discarding', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.rotate));
    await tester.pump();

    await tester.tap(find.byKey(PhotoToolsKeys.cancel));
    await tester.pumpAndSettle();
    expect(find.text('Discard this photo?'), findsOneWidget);
    expect(find.text('The framing you set will be lost.'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Frame photo'), findsOneWidget);
    expect(returned, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard this photo?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(popped, isNull);
  });

  testWidgets('an unreadable picture offers Choose another, which pops null',
      (tester) async {
    await open(tester, source: TestImages.brokenJpeg());
    await waitFor(tester, () => find.text('Choose another').hasFound);
    expect(find.text('That picture could not be read.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(PhotoToolsKeys.save)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Choose another'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(popped, isNull);
  });

  testWidgets('a failed render offers Try again', (tester) async {
    final renderer = FakeRenderer(renderError: StateError('boom'));
    await open(tester, renderer: renderer);
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await waitFor(tester, () => find.text('Try again').hasFound);
    expect(find.text('That photo could not be saved.'), findsOneWidget);
    expect(returned, isFalse);

    renderer.renderError = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await waitFor(tester, () => returned);
    await tester.pumpAndSettle();
    expect(popped, isNotNull);
    expect(renderer.renderCalls, 2);
  });

  testWidgets('previews follow the framing', (tester) async {
    await open(
      tester,
      previews: [
        const PhotoPreviewSpec(size: 84, caption: 'Profile'),
        PhotoPreviewSpec(
          size: 44,
          caption: 'Lists',
          builder: (context, framed) => DecoratedBox(
            key: const ValueKey('custom-preview'),
            decoration: const BoxDecoration(color: Colors.pink),
            child: framed,
          ),
        ),
      ],
    );
    expect(find.text('How it will look'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-preview')), findsOneWidget);

    await tester.tap(find.byKey(PhotoToolsKeys.rotate));
    await tester.pump();
    final previews =
        tester.widgetList<FramedImage>(find.byType(FramedImage)).toList();
    expect(previews, hasLength(2));
    for (final p in previews) {
      expect(p.framing, framing(tester));
      expect(p.framing.quarterTurns, 1);
    }
  });

  group('layout', () {
    testWidgets('phone: the stage spans the width', (tester) async {
      await open(tester);
      final stage = tester.getRect(find.byKey(PhotoToolsKeys.stage));
      expect(stage.width, 400 - 2 * 16);
      final bar = tester.getRect(find.byKey(PhotoToolsKeys.rotate));
      expect(bar.top, greaterThan(stage.bottom));
    });

    testWidgets('tablet: a centred 560 column', (tester) async {
      await open(tester, size: Surfaces.tablet);
      final stage = tester.getRect(find.byKey(PhotoToolsKeys.stage));
      expect(stage.width, 560);
      expect(stage.center.dx, closeTo(400, 0.5));
    });

    testWidgets('desktop: controls to the right of the stage', (tester) async {
      await open(tester, size: Surfaces.desktop);
      final stage = tester.getRect(find.byKey(PhotoToolsKeys.stage));
      final rotate = tester.getRect(find.byKey(PhotoToolsKeys.rotate));
      expect(rotate.left, greaterThan(stage.right));
      expect(rotate.top, lessThan(stage.bottom));
    });
  });

  testWidgets('a PhotoToolsScope supplies strings and renderer',
      (tester) async {
    final renderer = FakeRenderer();
    useSurface(tester, Surfaces.phone);
    await tester.pumpWidget(
      PhotoToolsScope(
        strings: const PhotoToolsStrings(editorTitle: 'Cadrer', save: 'OK'),
        renderer: renderer,
        child: app(
          PhotoEditorPage(
            source: TestImages.asymmetricPng(),
            options: const RenderOptions(outputLongEdge: 32),
          ),
        ),
      ),
    );
    await waitFor(tester, () => stagePainter(tester) != null);
    expect(find.text('Cadrer'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await waitFor(tester, () => renderer.renderCalls > 0);
    expect(renderer.renderCalls, 1);
  });
}
