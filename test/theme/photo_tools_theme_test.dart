import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

void main() {
  Future<PhotoToolsTheme> resolve(WidgetTester tester, ThemeData theme) async {
    late PhotoToolsTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            resolved = PhotoToolsTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return resolved;
  }

  testWidgets('without an extension every value comes from the scheme',
      (tester) async {
    final theme = ThemeData(colorSchemeSeed: Colors.teal);
    final t = await resolve(tester, theme);
    expect(t, PhotoToolsTheme.fallback(theme.colorScheme));
    expect(t.badgeBackground, theme.colorScheme.primary);
    expect(t.badgeForeground, theme.colorScheme.onPrimary);
    expect(t.guideColor, Colors.white);
    expect(t.stageRadius, 20);
    expect(t.guideWidth, 2);
    expect(t.stageBackground, isNotNull);
    expect(t.stageScrim, isNotNull);
    expect(t.previewBackground, theme.colorScheme.surfaceContainerLow);
  });

  testWidgets('an extension overrides only what it sets', (tester) async {
    final theme = ThemeData(
      extensions: const [
        PhotoToolsTheme(guideColor: Colors.amber, stageRadius: 4),
      ],
    );
    final t = await resolve(tester, theme);
    expect(t.guideColor, Colors.amber);
    expect(t.stageRadius, 4);
    expect(t.badgeBackground, theme.colorScheme.primary);
  });

  test('copyWith, lerp and equality', () {
    const a = PhotoToolsTheme(
      stageBackground: Colors.black,
      stageScrim: Colors.black,
      guideColor: Colors.white,
      guideWidth: 2,
      stageRadius: 0,
      badgeBackground: Colors.black,
      badgeForeground: Colors.white,
      previewBackground: Colors.black,
    );
    const b = PhotoToolsTheme(
      stageBackground: Colors.white,
      stageScrim: Colors.white,
      guideColor: Colors.black,
      guideWidth: 4,
      stageRadius: 10,
      badgeBackground: Colors.white,
      badgeForeground: Colors.black,
      previewBackground: Colors.white,
    );
    expect(a.copyWith(), a);
    expect(a.hashCode, a.copyWith().hashCode);
    expect(a.copyWith(stageRadius: 3).stageRadius, 3);
    expect(a, isNot(b));
    expect(a.lerp(null, 0.5), a);
    final mid = a.lerp(b, 0.5);
    expect(mid.guideWidth, 3);
    expect(mid.stageRadius, 5);
    expect(a.lerp(b, 1), b);
  });
}
