import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  PhotoSourceChoice? result;
  bool closed = false;

  Future<void> open(
    WidgetTester tester, {
    Size size = Surfaces.phone,
    bool allowCamera = true,
    bool canTakePhoto = true,
    List<CustomPhotoSource> customSources = const [],
    bool showRemove = false,
    String? removeConfirmName,
    String? title,
  }) async {
    result = null;
    closed = false;
    useSurface(tester, size);
    await tester.pumpWidget(
      PhotoToolsScope(
        picker: FakePhotoSourcePicker(canTakePhoto: canTakePhoto),
        child: app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showPhotoSourceSheet(
                      context,
                      title: title,
                      allowCamera: allowCamera,
                      customSources: customSources,
                      showRemove: showRemove,
                      removeConfirmName: removeConfirmName,
                    );
                    closed = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('by default: device and camera only', (tester) async {
    await open(tester);
    expect(find.text('Choose a photo'), findsOneWidget);
    expect(find.byKey(PhotoToolsKeys.sourceDevice), findsOneWidget);
    expect(find.byKey(PhotoToolsKeys.sourceCamera), findsOneWidget);
    expect(find.byKey(PhotoToolsKeys.sourceRemove), findsNothing);
  });

  testWidgets('a custom title', (tester) async {
    await open(tester, title: 'Photo for Sam');
    expect(find.text('Photo for Sam'), findsOneWidget);
  });

  testWidgets('no camera row when not allowed or not available',
      (tester) async {
    await open(tester, allowCamera: false);
    expect(find.byKey(PhotoToolsKeys.sourceCamera), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await open(tester, canTakePhoto: false);
    expect(find.byKey(PhotoToolsKeys.sourceCamera), findsNothing);
  });

  testWidgets('custom sources get a row each', (tester) async {
    final google = CustomPhotoSource(
      id: 'google',
      icon: Icons.account_circle_outlined,
      label: 'Use Google picture',
      load: () async => null,
    );
    await open(tester, customSources: [google]);
    expect(find.byKey(PhotoToolsKeys.sourceCustom('google')), findsOneWidget);
    await tester.tap(find.text('Use Google picture'));
    await tester.pumpAndSettle();
    expect((result! as CustomSourceChoice).source, same(google));
  });

  testWidgets('device and camera choices', (tester) async {
    await open(tester);
    await tester.tap(find.text('From this device'));
    await tester.pumpAndSettle();
    expect(result, isA<DeviceSourceChoice>());

    await open(tester);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(result, PhotoSourceChoice.camera);
  });

  testWidgets('Remove asks first, then removes', (tester) async {
    await open(tester, showRemove: true, removeConfirmName: 'Sam');
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.text("Remove Sam's photo?"), findsOneWidget);
    expect(find.text('The current photo will be removed.'), findsOneWidget);
    expect(closed, isFalse);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(result, PhotoSourceChoice.remove);
  });

  testWidgets('cancelling the Remove prompt keeps the sheet open',
      (tester) async {
    await open(tester, showRemove: true);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this photo?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('Choose a photo'), findsOneWidget);
  });

  testWidgets('dismissing resolves to null', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('a bottom sheet under 650, a 480 dialog above', (tester) async {
    await open(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await open(tester, size: Surfaces.tablet);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    final width = tester.getSize(find.byKey(PhotoToolsKeys.sourceDevice)).width;
    expect(width, lessThanOrEqualTo(480));
  });
}
