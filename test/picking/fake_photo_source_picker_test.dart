import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:scobro_flutter_photo_tools/scobro_flutter_photo_tools.dart';
import 'package:scobro_flutter_photo_tools/testing.dart';

void main() {
  test('answers with its canned picks and counts calls', () async {
    final image = PickedImage(
      name: 'a.jpg',
      bytes: TestImages.plainJpeg(),
      format: ImageFormat.jpeg,
    );
    final picker = FakePhotoSourcePicker(devicePick: Picked(image));

    expect(await picker.pickFromDevice(), isA<Picked>());
    expect(await picker.takePhoto(), const PickCancelled());
    expect(picker.deviceCalls, 1);
    expect(picker.cameraCalls, 1);
    expect(picker.canTakePhoto, isTrue);
  });

  test('refused and denied picks carry their reason', () async {
    final picker = FakePhotoSourcePicker(
      devicePick: const PickRefused(ImageValidationError.empty()),
      cameraPick: const CameraDenied(),
      canTakePhoto: false,
    );
    expect(
      await picker.pickFromDevice(const PickerOptions(maxDimension: 10)),
      const PickRefused(EmptyImageError()),
    );
    expect(picker.lastOptions?.maxDimension, 10);
    expect(await picker.takePhoto(), const CameraDenied());
    expect(picker.canTakePhoto, isFalse);
  });

  test('withImage picks a test JPEG from both sources', () async {
    final picker = FakePhotoSourcePicker.withImage(width: 30, height: 20);
    final device = await picker.pickFromDevice() as Picked;
    final camera = await picker.takePhoto() as Picked;
    expect(device.image.format, ImageFormat.jpeg);
    expect(camera.image.name, 'test.jpg');
    expect(
      await const PhotoRenderer().sizeOf(device.image.bytes),
      const Size(30, 20),
    );
  });
}
