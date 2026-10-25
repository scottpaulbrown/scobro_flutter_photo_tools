import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import '../helpers.dart';

void main() {
  late int taps;

  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool busy = false,
    String? semanticLabel,
  }) async {
    taps = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Center(
            child: ChangePhotoBadge(
              size: 64,
              enabled: enabled,
              busy: busy,
              semanticLabel: semanticLabel,
              onTap: () => taps++,
              child: const PhotoAvatar(name: 'Sam', size: 64),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a labelled button with a camera badge', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    expect(find.bySemanticsLabel('Change photo'), findsOneWidget);
    expect(find.byTooltip('Change photo'), findsOneWidget);
    await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
    expect(taps, 1);
  });

  testWidgets('a custom label', (tester) async {
    await pump(tester, semanticLabel: 'Change your photo');
    expect(find.bySemanticsLabel('Change your photo'), findsOneWidget);
  });

  testWidgets('busy shows a ring and ignores taps', (tester) async {
    await pump(tester, busy: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(PhotoToolsKeys.changePhoto));
    expect(taps, 0);
  });

  testWidgets('disabled is just the avatar', (tester) async {
    await pump(tester, enabled: false);
    expect(find.byIcon(Icons.photo_camera), findsNothing);
    expect(find.byKey(PhotoToolsKeys.changePhoto), findsNothing);
    expect(find.bySemanticsLabel('Change photo'), findsNothing);
  });

  testWidgets('badge colours come from PhotoToolsTheme', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ChangePhotoBadge(
            size: 64,
            onTap: () {},
            child: const SizedBox(),
          ),
        ),
        theme: ThemeData(
          extensions: const [
            PhotoToolsTheme(
              badgeBackground: Colors.orange,
              badgeForeground: Colors.black,
            ),
          ],
        ),
      ),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.photo_camera)).color,
      Colors.black,
    );
  });
}
