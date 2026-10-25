import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/src/editor/stage_painter.dart';

/// Screen sizes for the three layouts.
abstract final class Surfaces {
  static const phone = Size(400, 860);
  static const tablet = Size(800, 1000);
  static const desktop = Size(1400, 900);
}

/// Sets the test window to [size] (logical pixels) for the rest of the test.
void useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lets real async work (isolates, image codecs) run until [done] holds.
Future<void> waitFor(
  WidgetTester tester,
  bool Function() done, {
  int attempts = 60,
}) async {
  for (var i = 0; i < attempts && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
  }
  await tester.pump();
}

/// The stage painter currently on screen, if any.
StagePainter? stagePainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<StagePainter>()
    .firstOrNull;

/// A renderer whose behaviour tests control.
class FakeRenderer extends PhotoRenderer {
  FakeRenderer({
    this.size,
    this.renderError,
    this.sizeError,
    this.bakeCalls = 0,
  });

  /// What [sizeOf] reports; null uses the real renderer.
  Size? size;

  /// Thrown by [render] when set.
  Object? renderError;

  /// Thrown by [sizeOf] when set.
  Object? sizeError;

  /// How many times [bakeOrientation] ran.
  int bakeCalls;

  /// How many times [render] ran.
  int renderCalls = 0;

  @override
  Future<Size> sizeOf(Uint8List source) async {
    if (sizeError != null) throw sizeError!;
    return size ?? super.sizeOf(source);
  }

  @override
  Future<Uint8List> bakeOrientation(Uint8List source) {
    bakeCalls++;
    return super.bakeOrientation(source);
  }

  @override
  Future<EditedImage> render(
    Uint8List source,
    PhotoFraming framing, [
    RenderOptions options = const RenderOptions(),
  ]) async {
    renderCalls++;
    if (renderError != null) throw renderError!;
    return super.render(source, framing, options);
  }
}

/// A MaterialApp around [home] with an optional [theme].
Widget app(Widget home, {ThemeData? theme}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? ThemeData(colorSchemeSeed: const Color(0xFF2F6B5E)),
      home: home,
    );
