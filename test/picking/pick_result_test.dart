import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  test('results compare by value and describe themselves', () {
    expect(const PickCancelled(), const PickCancelled());
    expect(const PickCancelled().hashCode, const PickCancelled().hashCode);
    expect(const PickCancelled().toString(), 'PickCancelled()');

    expect(const CameraDenied(), const CameraDenied());
    expect(const CameraDenied().hashCode, const CameraDenied().hashCode);
    expect(const CameraDenied().toString(), 'CameraDenied()');

    const refused = PickRefused(ImageValidationError.empty());
    expect(refused, const PickRefused(EmptyImageError()));
    expect(refused.hashCode, const PickRefused(EmptyImageError()).hashCode);
    expect(refused, isNot(const PickRefused(ImageTooLargeError(2, 1))));
    expect(refused.toString(), contains('empty'));

    final image = PickedImage(
      name: 'a.jpg',
      bytes: TestImages.plainJpeg(),
      format: ImageFormat.jpeg,
    );
    expect(image.toString(), contains('a.jpg'));
    expect(Picked(image).toString(), contains('a.jpg'));
    expect(Picked(image).image, same(image));
  });

  test('picker options', () {
    const o = PickerOptions();
    expect(o.maxDimension, 4096);
    expect(o.validation, const ValidationRules());
    expect(o, const PickerOptions());
    expect(o.hashCode, const PickerOptions().hashCode);
    expect(o, isNot(const PickerOptions(maxDimension: 10)));
  });
}
