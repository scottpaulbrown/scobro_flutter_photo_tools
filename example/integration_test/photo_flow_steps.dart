import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';
import 'package:scobro_flutter_photo_tools_example/src/fake_photo_server.dart';
import 'package:scobro_flutter_photo_tools_example/src/gallery_app.dart';

/// The example's end-to-end photo flows. Run on a device by
/// `photo_flow_test.dart` (integration_test) and on the VM by
/// `test/photo_flow_widget_test.dart`.
void definePhotoFlowTests() {
  late FakePhotoServer server;

  Future<void> startApp(WidgetTester tester) async {
    server = FakePhotoServer(latency: Duration.zero);
    await tester.pumpWidget(
      GalleryApp(
        server: server,
        picker: FakePhotoSourcePicker.withImage(width: 600, height: 400),
        seedLoaderDemo: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets real async work (isolates, image decoding) run until [done].
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(done(), isTrue, reason: 'Timed out waiting');
  }

  bool editorReady(WidgetTester tester) {
    final save = find.byKey(PhotoToolsKeys.save);
    return save.evaluate().isNotEmpty &&
        tester.widget<FilledButton>(save).onPressed != null;
  }

  Future<void> openEditorFromDevice(WidgetTester tester) async {
    await tester.tap(find.byKey(PhotoToolsKeys.sourceDevice));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await waitFor(tester, () => editorReady(tester));
  }

  testWidgets('avatar: pick, rotate, zoom, save uploads a 512 px JPEG',
      (tester) async {
    await startApp(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
    await tester.pumpAndSettle();
    expect(find.text('Photo for Sam'), findsOneWidget);

    await openEditorFromDevice(tester);
    expect(find.text("Frame Sam's photo"), findsOneWidget);
    await tester.tap(find.byKey(PhotoToolsKeys.rotate));
    await tester.pump();
    await tester.ensureVisible(find.byKey(PhotoToolsKeys.zoomIn));
    await tester.tap(find.byKey(PhotoToolsKeys.zoomIn));
    await tester.pump();
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await tester.pump();
    await waitFor(tester, () => server.lastUpload != null);
    await tester.pump(const Duration(milliseconds: 600));

    final upload = server.lastUpload!;
    expect(upload.width, 512);
    expect(upload.height, 512);
    expect(upload.format, ImageFormat.jpeg);
    expect(detectImageFormat(upload.bytes), ImageFormat.jpeg);
    expect(upload.framing.quarterTurns, 1);
    expect(upload.framing.zoom, greaterThan(1));
    expect(server.versionOf('sam'), '1');
    expect(find.textContaining('512 × 512 JPEG'), findsWidgets);
  });

  testWidgets('avatar: a failing upload shows the server message',
      (tester) async {
    await startApp(tester);
    await tester.tap(find.byKey(const ValueKey('fail-uploads')));
    await tester.pump();
    await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
    await tester.pumpAndSettle();
    await openEditorFromDevice(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await tester.pump();
    await waitFor(
      tester,
      () => find.textContaining('bad day').evaluate().isNotEmpty,
    );
    expect(server.versionOf('sam'), isNull);
  });

  testWidgets('banner: staged mode returns a 1600 x 900 picture',
      (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Banner'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose banner'));
    await tester.tap(find.text('Choose banner'));
    await tester.pumpAndSettle();
    expect(find.byKey(PhotoToolsKeys.sourceCamera), findsNothing);

    await openEditorFromDevice(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.save));
    await tester.pump();
    await waitFor(
      tester,
      () => find.textContaining('1600 × 900').evaluate().isNotEmpty,
    );
    expect(find.byKey(const ValueKey('banner-result')), findsOneWidget);
    expect(server.lastUpload, isNull);
  });

  testWidgets('cancel: leaving the editor changes nothing', (tester) async {
    await startApp(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
    await tester.pumpAndSettle();
    await openEditorFromDevice(tester);
    await tester.tap(find.byKey(PhotoToolsKeys.cancel));
    await tester.pumpAndSettle();
    expect(find.byKey(PhotoToolsKeys.save), findsNothing);
    expect(server.lastUpload, isNull);
    expect(find.text('Nothing yet'), findsOneWidget);
  });
}
