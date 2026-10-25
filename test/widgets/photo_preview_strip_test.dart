import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

import '../helpers.dart';

void main() {
  test('spec sizes follow the aspect ratio by the long edge', () {
    const spec = PhotoPreviewSpec(size: 80);
    expect(spec.sizeFor(1), const Size(80, 80));
    expect(spec.sizeFor(2), const Size(80, 40));
    expect(spec.sizeFor(0.5), const Size(40, 80));
  });

  testWidgets('lays out each preview at its size, with captions and a title',
      (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PhotoPreviewStrip(
            title: 'How it will look',
            aspectRatio: 2,
            specs: const [
              PhotoPreviewSpec(size: 80, caption: 'Banner'),
              PhotoPreviewSpec(size: 40),
            ],
            builder: (context, spec) => ColoredBox(
              key: ValueKey(spec.size),
              color: Colors.teal,
            ),
          ),
        ),
      ),
    );
    expect(find.text('How it will look'), findsOneWidget);
    expect(find.text('Banner'), findsOneWidget);
    expect(
        tester.getSize(find.byKey(const ValueKey(80.0))), const Size(80, 40));
    expect(
        tester.getSize(find.byKey(const ValueKey(40.0))), const Size(40, 20));
  });

  testWidgets('no title when none is given', (tester) async {
    await tester.pumpWidget(
      app(
        PhotoPreviewStrip(
          specs: const [PhotoPreviewSpec(size: 40)],
          builder: (_, __) => const SizedBox(),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
