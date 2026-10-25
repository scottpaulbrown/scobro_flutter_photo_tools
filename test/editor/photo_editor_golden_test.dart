@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

final _light = ThemeData(colorSchemeSeed: const Color(0xFF2F6B5E));
final _dark = ThemeData(
  colorSchemeSeed: const Color(0xFF2F6B5E),
  brightness: Brightness.dark,
);
final _custom = _light.copyWith(
  extensions: const [
    PhotoToolsTheme(
      guideColor: Color(0xFFFFC857),
      guideWidth: 3,
      stageRadius: 4,
      stageBackground: Color(0xFF1B1B1F),
    ),
  ],
);

void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size size,
    required ThemeData theme,
    RenderOptions options = const RenderOptions(),
    CropGuideShape guideShape = CropGuideShape.circle,
  }) async {
    useSurface(tester, size);
    await tester.pumpWidget(
      app(
        PhotoEditorPage(
          source: TestImages.asymmetricJpeg(width: 320, height: 200, mark: 60),
          options: options,
          guideShape: guideShape,
          previews: const [
            PhotoPreviewSpec(size: 84, caption: 'Profile'),
            PhotoPreviewSpec(size: 44, caption: 'Lists'),
            PhotoPreviewSpec(size: 24, caption: 'Schedule'),
          ],
        ),
        theme: theme,
      ),
    );
    await waitFor(tester, () => stagePainter(tester) != null);
    await tester.pumpAndSettle();
  }

  for (final (name, theme) in [
    ('light', _light),
    ('dark', _dark),
    ('custom', _custom),
  ]) {
    testWidgets('editor, phone, $name', (tester) async {
      await pumpEditor(tester, size: Surfaces.phone, theme: theme);
      await expectLater(
        find.byType(PhotoEditorPage),
        matchesGoldenFile('../goldens/editor_phone_$name.png'),
      );
    });

    testWidgets('editor, desktop, $name', (tester) async {
      await pumpEditor(tester, size: Surfaces.desktop, theme: theme);
      await expectLater(
        find.byType(PhotoEditorPage),
        matchesGoldenFile('../goldens/editor_desktop_$name.png'),
      );
    });
  }

  testWidgets('editor, tablet, 16:9 banner', (tester) async {
    await pumpEditor(
      tester,
      size: Surfaces.tablet,
      theme: _light,
      options: const RenderOptions(aspectRatio: 16 / 9),
      guideShape: CropGuideShape.roundedRect,
    );
    await expectLater(
      find.byType(PhotoEditorPage),
      matchesGoldenFile('../goldens/editor_tablet_banner.png'),
    );
  });
}
