import 'package:flutter/foundation.dart';

/// How a picture is framed inside the crop box: turned, zoomed and moved.
///
/// A framing is independent of the picture's size and of the crop's aspect
/// ratio; [FramingGeometry.cropRect] turns it into pixels. The default
/// framing keeps the largest centred area of the picture, unrotated.
@immutable
class PhotoFraming {
  /// Creates a [PhotoFraming].
  const PhotoFraming({
    this.quarterTurns = 0,
    this.zoom = 1,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  /// Clockwise quarter turns, 0–3.
  final int quarterTurns;

  /// 1 keeps the largest area of the picture at the crop's aspect ratio;
  /// 2 keeps half of that width and height, and so on up to the renderer's
  /// `maxZoom`.
  final double zoom;

  /// Where the crop sits along the free horizontal travel: −1 is the left
  /// edge, 0 the centre and 1 the right edge.
  final double offsetX;

  /// Where the crop sits along the free vertical travel: −1 is the top edge,
  /// 0 the centre and 1 the bottom edge.
  final double offsetY;

  /// Whether this is the default framing (nothing turned, zoomed or moved).
  bool get isDefault => this == const PhotoFraming();

  /// A copy with the given fields replaced.
  PhotoFraming copyWith({
    int? quarterTurns,
    double? zoom,
    double? offsetX,
    double? offsetY,
  }) =>
      PhotoFraming(
        quarterTurns: quarterTurns ?? this.quarterTurns,
        zoom: zoom ?? this.zoom,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
      );

  /// The picture turned a further quarter clockwise.
  ///
  /// The picture's axes swap, so zoom and offsets go back to the centre.
  PhotoFraming rotatedClockwise() =>
      PhotoFraming(quarterTurns: (quarterTurns + 1) % 4);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoFraming &&
          quarterTurns == other.quarterTurns &&
          zoom == other.zoom &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY;

  @override
  int get hashCode => Object.hash(quarterTurns, zoom, offsetX, offsetY);

  @override
  String toString() => 'PhotoFraming(quarterTurns: $quarterTurns, '
      'zoom: $zoom, offsetX: $offsetX, offsetY: $offsetY)';
}
