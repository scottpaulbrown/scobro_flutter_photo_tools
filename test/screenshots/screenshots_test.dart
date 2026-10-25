// Writes the pub.dev screenshots in doc/screenshots. Skipped by default:
//   flutter test --tags screenshot --run-skipped --update-goldens
@Tags(['screenshot'])
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

final _light = ThemeData(colorSchemeSeed: const Color(0xFFB4532A));
final _dark = ThemeData(
  colorSchemeSeed: const Color(0xFFB4532A),
  brightness: Brightness.dark,
);

Future<Uint8List> _landscape() async {
  const w = 900.0;
  const h = 600.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, h),
          [const Color(0xFFF4A261), const Color(0xFFE76F51)],
        ),
    )
    ..drawCircle(
      const Offset(560, 210),
      90,
      Paint()..color = const Color(0xFFFFF3B0),
    );
  for (var i = 0; i < 3; i++) {
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 30) {
      path.lineTo(x, 380 + i * 70 + math.sin(x / 110 + i * 1.7) * 40);
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF264653).withValues(alpha: 0.4 + i * 0.3),
    );
  }
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late Uint8List picture;

  setUpAll(() async => picture = await _landscape());

  void surface(WidgetTester tester, Size logical) {
    tester.view.physicalSize = logical * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  Future<void> editor(
    WidgetTester tester,
    ThemeData theme,
    Size size, {
    RenderOptions options = const RenderOptions(),
    CropGuideShape guide = CropGuideShape.circle,
    String? title,
    bool avatarPreviews = true,
  }) async {
    surface(tester, size);
    await tester.pumpWidget(
      app(
        PhotoEditorPage(
          source: picture,
          options: options,
          guideShape: guide,
          title: title,
          previews: [
            for (final (s, caption) in [
              (84.0, 'Profile'),
              (44.0, 'Lists'),
              (24.0, 'Chips'),
            ])
              PhotoPreviewSpec(
                size: s,
                caption: caption,
                builder: !avatarPreviews
                    ? null
                    : (context, framed) => PhotoAvatar(
                          name: 'Sam',
                          size: s,
                          ringColor: Theme.of(context).colorScheme.primary,
                          photoChild: framed,
                        ),
              ),
          ],
        ),
        theme: theme,
      ),
    );
    await waitFor(tester, () => stagePainter(tester) != null);
    await tester.pumpAndSettle();
  }

  testWidgets('editor on a phone', (tester) async {
    await editor(tester, _light, const Size(400, 860),
        title: "Frame Sam's photo");
    await tester.tap(find.byKey(PhotoToolsKeys.zoomIn));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PhotoEditorPage),
      matchesGoldenFile('../../doc/screenshots/editor_phone.png'),
    );
  });

  testWidgets('editor on a desktop, dark, 16:9', (tester) async {
    await editor(
      tester,
      _dark,
      const Size(1280, 760),
      options: const RenderOptions(aspectRatio: 16 / 9),
      guide: CropGuideShape.roundedRect,
      title: 'Frame the banner',
      avatarPreviews: false,
    );
    await expectLater(
      find.byType(PhotoEditorPage),
      matchesGoldenFile('../../doc/screenshots/editor_desktop_dark.png'),
    );
  });

  testWidgets('source sheet', (tester) async {
    surface(tester, const Size(400, 860));
    await tester.pumpWidget(
      PhotoToolsScope(
        picker: FakePhotoSourcePicker(),
        child: app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showPhotoSourceSheet(
                    context,
                    title: 'Photo for Sam',
                    showRemove: true,
                    customSources: [
                      CustomPhotoSource(
                        id: 'google',
                        icon: Icons.account_circle_outlined,
                        label: 'Use Google picture',
                        load: () async => null,
                      ),
                    ],
                  ),
                  child: const Text('Change photo'),
                ),
              ),
            ),
          ),
          theme: _light,
        ),
      ),
    );
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../doc/screenshots/source_sheet.png'),
    );
  });

  for (final (name, theme) in [('light', _light), ('dark', _dark)]) {
    testWidgets('avatars, $name', (tester) async {
      surface(tester, const Size(560, 300));
      final photo = MemoryImage(picture);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 28,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  ChangePhotoBadge(
                    size: 104,
                    onTap: () {},
                    child: PhotoAvatar(name: 'Sam', size: 104, image: photo),
                  ),
                  ChangePhotoBadge(
                    size: 104,
                    busy: true,
                    onTap: () {},
                    child: const PhotoAvatar(
                      name: 'Lee Chen',
                      size: 104,
                      color: Color(0xFF2A9D8F),
                    ),
                  ),
                  for (final (i, n) in ['Ana Ruiz', 'Ben', 'Cleo Park'].indexed)
                    PhotoAvatar(
                      name: n,
                      size: 64,
                      color: [
                        const Color(0xFFE9C46A),
                        const Color(0xFF6D597A),
                        const Color(0xFF457B9D),
                      ][i],
                      ringColor: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
          theme: theme,
        ),
      );
      await tester.runAsync(
        () => precacheImage(photo, tester.element(find.byType(Scaffold))),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../../doc/screenshots/avatars_$name.png'),
      );
    });
  }
}
