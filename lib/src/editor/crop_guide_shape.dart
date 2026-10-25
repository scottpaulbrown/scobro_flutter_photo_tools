import 'dart:ui';

/// The outline drawn over the crop box in the editor and used to clip the
/// previews. The saved picture is always the full rectangle; the guide only
/// shows how the app will display it.
enum CropGuideShape {
  /// An ellipse inscribed in the crop box: a circle at aspect ratio 1, an
  /// oval at any other ratio. Use it for round avatars.
  circle,

  /// A rectangle with rounded corners (12% of the shorter side).
  roundedRect,

  /// A plain rectangle.
  rect;

  /// The guide's outline inside [box].
  Path pathFor(Rect box) => switch (this) {
        CropGuideShape.circle => Path()..addOval(box),
        CropGuideShape.roundedRect => Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              box,
              Radius.circular(box.shortestSide * 0.12),
            ),
          ),
        CropGuideShape.rect => Path()..addRect(box),
      };
}
