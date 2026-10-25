@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

final _themes = {
  'light': ThemeData(colorSchemeSeed: const Color(0xFF2F6B5E)),
  'dark': ThemeData(
    colorSchemeSeed: const Color(0xFF2F6B5E),
    brightness: Brightness.dark,
  ),
  'custom': ThemeData(
    colorSchemeSeed: const Color(0xFF2F6B5E),
    extensions: const [
      PhotoToolsTheme(
        badgeBackground: Color(0xFFFFC857),
        badgeForeground: Color(0xFF1B1B1F),
      ),
    ],
  ),
};

void main() {
  for (final MapEntry(key: name, value: theme) in _themes.entries) {
    testWidgets('avatars and badges, $name', (tester) async {
      useSurface(tester, const Size(520, 260));
      final photo = MemoryImage(
        TestImages.asymmetricPng(width: 60, height: 60, mark: 30),
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final size in [104.0, 84.0, 64.0, 44.0, 32.0, 24.0])
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: PhotoAvatar(
                            name: 'Sam Smith',
                            size: size,
                            color: const Color(0xFF3D5A80),
                            ringColor: const Color(0xFF98C1D9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ChangePhotoBadge(
                        size: 84,
                        onTap: () {},
                        child: PhotoAvatar(name: 'Kim', size: 84, image: photo),
                      ),
                      const SizedBox(width: 32),
                      ChangePhotoBadge(
                        size: 84,
                        busy: true,
                        onTap: () {},
                        child: const PhotoAvatar(name: 'Lee', size: 84),
                      ),
                      const SizedBox(width: 32),
                      ChangePhotoBadge(
                        size: 44,
                        onTap: () {},
                        child: const PhotoAvatar(name: 'Ana Ruiz', size: 44),
                      ),
                    ],
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/avatars_$name.png'),
      );
    });

    testWidgets('source sheet, $name', (tester) async {
      useSurface(tester, Surfaces.phone);
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
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
            theme: theme,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/source_sheet_$name.png'),
      );
    });
  }
}
