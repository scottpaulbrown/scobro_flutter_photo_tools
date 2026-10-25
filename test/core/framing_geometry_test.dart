import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

const _landscape = Size(400, 200);
const _portrait = Size(200, 400);

Rect _crop(Size source, PhotoFraming f, double ratio, {double maxZoom = 4}) =>
    FramingGeometry.cropRect(source, f, aspectRatio: ratio, maxZoom: maxZoom);

void main() {
  test('rotatedSize swaps the axes on odd turns only', () {
    expect(FramingGeometry.rotatedSize(_landscape, 0), _landscape);
    expect(FramingGeometry.rotatedSize(_landscape, 1), _portrait);
    expect(FramingGeometry.rotatedSize(_landscape, 2), _landscape);
    expect(FramingGeometry.rotatedSize(_landscape, 3), _portrait);
  });

  group('largestFit', () {
    test('wide box, square ratio: limited by height', () {
      expect(FramingGeometry.largestFit(_landscape, 1), const Size(200, 200));
    });
    test('tall box, square ratio: limited by width', () {
      expect(FramingGeometry.largestFit(_portrait, 1), const Size(200, 200));
    });
    test('16:9 in a 4:3 box: limited by width', () {
      expect(
        FramingGeometry.largestFit(const Size(400, 300), 16 / 9),
        const Size(400, 225),
      );
    });
  });

  group('cropRect at zoom 1, centred', () {
    test('1:1 on landscape keeps the centred square', () {
      expect(
        _crop(_landscape, const PhotoFraming(), 1),
        const Rect.fromLTWH(100, 0, 200, 200),
      );
    });

    test('1:1 on portrait keeps the centred square', () {
      expect(
        _crop(_portrait, const PhotoFraming(), 1),
        const Rect.fromLTWH(0, 100, 200, 200),
      );
    });

    test('4:3 on landscape', () {
      final r = _crop(_landscape, const PhotoFraming(), 4 / 3);
      expect(r.height, 200);
      expect(r.width, closeTo(266.67, 0.01));
      expect(r.center, const Offset(200, 100));
    });

    test('16:9 on landscape is limited by width', () {
      final r = _crop(_landscape, const PhotoFraming(), 16 / 9);
      expect(r.height, closeTo(200, 0.01));
      expect(r.width, closeTo(355.56, 0.01));
      expect(r.center.dx, closeTo(200, 0.01));
    });

    test('16:9 on portrait keeps the full width', () {
      final r = _crop(_portrait, const PhotoFraming(), 16 / 9);
      expect(r.width, 200);
      expect(r.height, closeTo(112.5, 0.01));
      expect(r.center, const Offset(100, 200));
    });

    test('9:16 on portrait keeps the full height', () {
      final r = _crop(_portrait, const PhotoFraming(), 9 / 16);
      expect(r.height, closeTo(355.56, 0.01));
      expect(r.width, closeTo(200, 0.01));
    });
  });

  group('zoom', () {
    test('zoom 2 halves both sides around the centre', () {
      expect(
        _crop(_landscape, const PhotoFraming(zoom: 2), 1),
        const Rect.fromLTWH(150, 50, 100, 100),
      );
    });

    test('zoom is clamped to maxZoom and to 1', () {
      expect(_crop(_landscape, const PhotoFraming(zoom: 10), 1).width, 50);
      expect(
        _crop(_landscape, const PhotoFraming(zoom: 10), 1, maxZoom: 2).width,
        100,
      );
      expect(_crop(_landscape, const PhotoFraming(zoom: 0.1), 1).width, 200);
    });
  });

  group('offsets', () {
    test('−1 and 1 reach the edges', () {
      expect(_crop(_landscape, const PhotoFraming(offsetX: -1), 1).left, 0);
      expect(_crop(_landscape, const PhotoFraming(offsetX: 1), 1).right, 400);
      expect(
        _crop(_landscape, const PhotoFraming(zoom: 2, offsetY: 1), 1).bottom,
        200,
      );
    });

    test('offsets beyond −1…1 are clamped inside the picture', () {
      final r =
          _crop(_landscape, const PhotoFraming(offsetX: 5, offsetY: -5), 1);
      expect(r.right, 400);
      expect(r.top, 0);
    });
  });

  group('rotation', () {
    test('an odd turn measures in the swapped picture', () {
      expect(
        _crop(_landscape, const PhotoFraming(quarterTurns: 1), 1),
        const Rect.fromLTWH(0, 100, 200, 200),
      );
    });

    test('16:9 after a quarter turn of a landscape picture', () {
      final r = _crop(_landscape, const PhotoFraming(quarterTurns: 1), 16 / 9);
      expect(r.width, 200);
      expect(r.height, closeTo(112.5, 0.01));
    });

    test('four turns restore the original crop', () {
      var f = const PhotoFraming();
      for (var i = 0; i < 4; i++) {
        f = f.rotatedClockwise();
      }
      expect(
        _crop(_landscape, f, 4 / 3),
        _crop(_landscape, const PhotoFraming(), 4 / 3),
      );
    });
  });

  group('pan', () {
    PhotoFraming pan(
      PhotoFraming f,
      Offset d, {
      double ratio = 1,
      Size s = _landscape,
    }) =>
        FramingGeometry.pan(s, f, d, aspectRatio: ratio);

    test('dragging the picture left moves the kept area right', () {
      // The crop is 200 wide and the free travel 200, so the offset spans 100.
      expect(
        pan(const PhotoFraming(), const Offset(-0.2, 0)).offsetX,
        closeTo(0.4, 1e-9),
      );
    });

    test('pans are clamped to the edges', () {
      expect(pan(const PhotoFraming(), const Offset(-50, 0)).offsetX, 1);
      expect(pan(const PhotoFraming(), const Offset(50, 0)).offsetX, -1);
    });

    test('an axis with no travel stays centred', () {
      expect(pan(const PhotoFraming(), const Offset(0, 0.5)).offsetY, 0);
    });

    test('a zoomed picture travels on both axes', () {
      final f = pan(const PhotoFraming(zoom: 2), const Offset(0.1, 0.1));
      expect(f.offsetX, lessThan(0));
      expect(f.offsetY, lessThan(0));
      expect(f.zoom, 2);
    });

    test('an empty picture leaves the framing alone', () {
      const f = PhotoFraming(offsetX: 0.3);
      expect(pan(f, const Offset(1, 1), s: Size.zero), f);
    });
  });
}
