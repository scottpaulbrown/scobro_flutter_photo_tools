import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';
import 'package:scobro_flutter_photo_tools_example/src/fake_photo_server.dart';
import 'package:scobro_flutter_photo_tools_example/src/gallery_app.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GalleryApp(
        server: FakePhotoServer(latency: Duration.zero),
        picker: FakePhotoSourcePicker(),
        seedLoaderDemo: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone: bottom navigation', (tester) async {
    await pumpAt(tester, const Size(400, 860));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablet: a labelled rail', (tester) async {
    await pumpAt(tester, const Size(800, 1000));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets('desktop: an extended rail, and every demo opens',
      (tester) async {
    await pumpAt(tester, const Size(1400, 900));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Change a profile photo'), findsOneWidget);
    await tester.tap(find.text('Banner'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a 16:9 banner'), findsOneWidget);
    await tester.tap(find.text('Loader'));
    await tester.pumpAndSettle();
    expect(find.text('Photos behind your own auth'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });
}
