import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';

void main() {
  test('defaults are unturned, unzoomed and centred', () {
    const f = PhotoFraming();
    expect(f.quarterTurns, 0);
    expect(f.zoom, 1);
    expect(f.offsetX, 0);
    expect(f.offsetY, 0);
    expect(f.isDefault, isTrue);
  });

  test('copyWith replaces only the given fields', () {
    const f =
        PhotoFraming(quarterTurns: 1, zoom: 2, offsetX: 0.5, offsetY: -0.5);
    expect(f.copyWith(), f);
    expect(f.copyWith(quarterTurns: 3).quarterTurns, 3);
    expect(f.copyWith(zoom: 3).zoom, 3);
    expect(f.copyWith(offsetX: 1).offsetX, 1);
    expect(f.copyWith(offsetY: 1).offsetY, 1);
    expect(f.copyWith(offsetY: 1).zoom, 2);
    expect(f.isDefault, isFalse);
  });

  test('rotatedClockwise turns and recentres; four turns restore', () {
    var f = const PhotoFraming(zoom: 2, offsetX: 1);
    f = f.rotatedClockwise();
    expect(f, const PhotoFraming(quarterTurns: 1));
    f = f.rotatedClockwise().rotatedClockwise().rotatedClockwise();
    expect(f, const PhotoFraming());
  });

  test('equality, hashCode and toString', () {
    const a = PhotoFraming(quarterTurns: 1, zoom: 1.5);
    const b = PhotoFraming(quarterTurns: 1, zoom: 1.5);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const PhotoFraming(quarterTurns: 2, zoom: 1.5)));
    expect(a.toString(), contains('quarterTurns: 1'));
    expect(a.toString(), contains('zoom: 1.5'));
  });
}
