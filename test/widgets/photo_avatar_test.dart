import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

import '../helpers.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget avatar, {Widget? wrap}) =>
      tester.pumpWidget(app(Scaffold(body: Center(child: avatar))));

  test('initials', () {
    expect(PhotoAvatar.initialsFor('sam'), 'S');
    expect(PhotoAvatar.initialsFor('  Sam  Smith '), 'SS');
    expect(PhotoAvatar.initialsFor('Mary Jane Watson'), 'MW');
    expect(PhotoAvatar.initialsFor(''), '?');
    expect(PhotoAvatar.initialsFor('   '), '?');
    expect(PhotoAvatar.initialsFor('élodie'), 'É');
  });

  test('ring widths by size', () {
    expect(PhotoAvatar.defaultRingWidth(104), 3);
    expect(PhotoAvatar.defaultRingWidth(44), 2);
    expect(PhotoAvatar.defaultRingWidth(24), 1.5);
  });

  testWidgets('initials on the colour, in a contrasting text colour',
      (tester) async {
    await pump(
      tester,
      const PhotoAvatar(name: 'Sam Smith', size: 64, color: Color(0xFF1B3A6B)),
    );
    expect(find.text('SS'), findsOneWidget);
    final text = tester.widget<Text>(find.text('SS'));
    expect(text.style!.color, Colors.white);

    await pump(
      tester,
      const PhotoAvatar(name: 'Sam', size: 64, color: Color(0xFFFFE08A)),
    );
    expect(tester.widget<Text>(find.text('S')).style!.color, Colors.black87);
  });

  testWidgets('neutral without a colour', (tester) async {
    await pump(tester, const PhotoAvatar(name: 'Sam', size: 44));
    final context = tester.element(find.text('S'));
    expect(
      tester.widget<Text>(find.text('S')).style!.color,
      Theme.of(context).colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('a ring adds a border at the given size', (tester) async {
    await pump(
      tester,
      const PhotoAvatar(name: 'Sam', size: 64, ringColor: Colors.teal),
    );
    expect(tester.getSize(find.byType(PhotoAvatar)), const Size(64, 64));
    final ring =
        tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where(
              (d) => (d.decoration as BoxDecoration).border != null,
            );
    expect(ring, hasLength(1));

    await pump(
      tester,
      const PhotoAvatar(
        name: 'Sam',
        size: 64,
        ringColor: Colors.teal,
        ringWidth: 6,
      ),
    );
    final border = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => (d.decoration as BoxDecoration).border)
        .whereType<Border>()
        .single;
    expect(border.top.width, 6);
  });

  testWidgets('a photo child is clipped to a circle', (tester) async {
    await pump(
      tester,
      const PhotoAvatar(
        name: 'Sam',
        size: 44,
        photoChild: ColoredBox(key: ValueKey('photo'), color: Colors.pink),
      ),
    );
    expect(find.byKey(const ValueKey('photo')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('photo')),
        matching: find.byType(ClipOval),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an image fades in over the initials', (tester) async {
    final image = MemoryImage(TestImages.asymmetricPng(width: 4, height: 4));
    await pump(tester, PhotoAvatar(name: 'Sam', size: 44, image: image));
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(PhotoAvatar))),
    );
    await tester.pump();
    expect(find.text('S'), findsOneWidget); // Underneath, for the fade.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a loader-backed photo shows; null bytes keep the initials',
      (tester) async {
    final png = TestImages.asymmetricPng(width: 4, height: 4);
    final loader = VersionedImageLoader(
      fetch: (id, _) async => id == 'sam' ? png : null,
    );
    await tester.pumpWidget(
      PhotoToolsScope(
        loader: loader,
        child: app(
          const Scaffold(
            body: Column(
              children: [
                PhotoAvatar(
                  name: 'Sam',
                  size: 44,
                  photoId: 'sam',
                  photoVersion: '1',
                ),
                PhotoAvatar(
                  name: 'Kim',
                  size: 44,
                  photoId: 'kim',
                  photoVersion: '1',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 20),
          ));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(images.first.image, VersionedMemoryImage(loader, 'sam', '1'));
    expect(loader.peek('sam', '1'), png);
    expect(loader.contains('kim', '1'), isTrue);
    // Kim has no photo, so the error builder shows the initials again.
    expect(find.text('K'), findsNWidgets(2));
  });

  testWidgets('without a loader or version only the initials show',
      (tester) async {
    await pump(
      tester,
      const PhotoAvatar(
          name: 'Sam', size: 44, photoId: 'sam', photoVersion: '1'),
    );
    expect(find.byType(Image), findsNothing);
    await pump(
      tester,
      PhotoAvatar(
        name: 'Sam',
        size: 44,
        photoId: 'sam',
        loader: VersionedImageLoader(fetch: (_, __) async => null),
      ),
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('semantics: decorative by default, labelled on request',
      (tester) async {
    await pump(tester, const PhotoAvatar(name: 'Sam', size: 44));
    expect(find.bySemanticsLabel('S'), findsNothing);
    await pump(
      tester,
      const PhotoAvatar(name: 'Sam', size: 44, semanticLabel: 'Sam Smith'),
    );
    expect(find.bySemanticsLabel('Sam Smith'), findsOneWidget);
  });
}
