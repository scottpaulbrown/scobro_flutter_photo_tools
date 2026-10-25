import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  Future<PhotoEditorController> pump(
    WidgetTester tester, {
    Size size = Surfaces.phone,
    double? height,
    VoidCallback? onChooseAnother,
    VoidCallback? onRetry,
    PhotoRenderer? renderer,
    bool load = true,
  }) async {
    useSurface(tester, size);
    final controller = PhotoEditorController(
      options: const RenderOptions(outputLongEdge: 32),
      renderer: renderer,
    );
    addTearDown(controller.dispose);
    final editor = PhotoEditor(
      controller: controller,
      onChooseAnother: onChooseAnother,
      onRetry: onRetry,
    );
    await tester.pumpWidget(
      app(
        Scaffold(
          body: height == null
              ? SingleChildScrollView(child: editor)
              : SizedBox(height: height, child: editor),
        ),
      ),
    );
    return controller;
  }

  testWidgets('shows a labelled spinner while loading', (tester) async {
    final controller = await pump(tester);
    controller.load(TestImages.asymmetricPng()).ignore();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Loading photo')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(PhotoToolsKeys.rotate))
          .onPressed,
      isNull,
    );
    await waitFor(tester, () => controller.isReady);
    expect(stagePainter(tester), isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an unreadable picture without onChooseAnother has no action',
      (tester) async {
    final controller = await pump(tester);
    await tester.runAsync(() => controller.load(TestImages.brokenJpeg()));
    await tester.pump();
    expect(find.text('That picture could not be read.'), findsOneWidget);
    expect(find.text('Choose another'), findsNothing);
  });

  testWidgets('onChooseAnother is called from the unreadable card',
      (tester) async {
    var chose = 0;
    final controller = await pump(tester, onChooseAnother: () => chose++);
    await tester.runAsync(() => controller.load(TestImages.brokenJpeg()));
    await tester.pump();
    await tester.tap(find.text('Choose another'));
    expect(chose, 1);
  });

  testWidgets('a render failure shows a card; onRetry is optional',
      (tester) async {
    final controller = await pump(
      tester,
      renderer: FakeRenderer(renderError: StateError('x')),
    );
    await tester.runAsync(() => controller.load(TestImages.asymmetricPng()));
    await tester.runAsync(controller.render);
    await tester.pump();
    expect(find.text('That photo could not be saved.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('in a bounded height the stage fits it', (tester) async {
    final controller = await pump(tester, size: Surfaces.desktop, height: 500);
    await tester.runAsync(() => controller.load(TestImages.asymmetricPng()));
    await tester.pump();
    final stage = tester.getRect(find.byKey(PhotoToolsKeys.stage));
    expect(stage.height, lessThanOrEqualTo(500));
    final box = stagePainter(tester)!.cropBox;
    expect(box.width, box.height);
  });

  testWidgets('the rule-of-thirds grid shows only while dragging',
      (tester) async {
    final controller = await pump(tester);
    await tester.runAsync(() => controller.load(TestImages.asymmetricPng()));
    await tester.pump();
    expect(stagePainter(tester)!.gridOpacity, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(PhotoToolsKeys.stage)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(stagePainter(tester)!.gridOpacity, 1);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(stagePainter(tester)!.gridOpacity, 0);
  });

  test('every guide shape outlines the box', () {
    const box = Rect.fromLTWH(0, 0, 100, 50);
    for (final shape in CropGuideShape.values) {
      final bounds = shape.pathFor(box).getBounds();
      expect(bounds, box);
    }
    // A circle guide at 2:1 is an oval: its left edge middle is inside, its
    // corner is not.
    final oval = CropGuideShape.circle.pathFor(box);
    expect(oval.contains(const Offset(1, 25)), isTrue);
    expect(oval.contains(const Offset(2, 2)), isFalse);
    expect(
      CropGuideShape.roundedRect.pathFor(box).contains(const Offset(1, 1)),
      isFalse,
    );
    expect(
        CropGuideShape.rect.pathFor(box).contains(const Offset(1, 1)), isTrue);
  });
}
